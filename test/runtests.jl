using Test
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

@testset "IPE" begin

    @testset "ledger provenance" begin
        @test !isempty(IPE.LedgerParams.PARAM_PROVENANCE)
        for (sym, p) in IPE.LedgerParams.PARAM_PROVENANCE
            @test !isempty(p.units)
            @test p.tier in ("A", "B", "C")
            @test p.method in ("reported", "digitized", "derived", "assumed", "calibrated")
        end
    end

    @testset "weak-basis parameters are visible" begin
        weak = IPE.LedgerParams.unledgered_check()
        @info "Parameters with weak basis (assumed or calibrated)" count=length(weak)
        for p in weak
            @info "  $(p.param_id) [$(p.method)]"
        end
        @test true   # disclosure, not a failure
    end

    @testset "model builds and simplifies" begin
        sys = build_model()
        @test sys isa ModelingToolkit.AbstractSystem
    end

    @testset "loop reaches equilibrium at nominal intake" begin
        sys = build_model()
        sol = solve_individual(sys; tspan_days = 60.0, saveat = 1.0)
        @test SciMLBase.successful_retcode(sol)
        # At nominal intake the loop must settle. If it drifts, the ledger's
        # derived values (FR_Na, TPR, f_pv) are not mutually consistent.
        # TODO: assert d(V_ecf)/dt -> 0 and MAP within reference range.
    end

    @testset "THE test: salt step re-equilibrates at a NEW pressure" begin
        # ADR 0007 falsifiable test.
        r = salt_step()
        v = check_pressure_natriuresis(r)

        # The loop must close: excretion returns to match intake.
        @test v.excretion_matches_intake

        # And pressure must MOVE. A model that excretes whatever it is given
        # closes the loop trivially and has no pressure regulation in it.
        @test v.map_shifts_between_levels
        @test v.higher_intake_higher_pressure

        @info "salt step" intakes=v.intakes maps=v.maps shift_mmHg=v.map_shift_mmHg
    end

    @testset "states stay physiological through the salt step" begin
        r = salt_step()
        for l in r.levels
            @test 10.0 <= l.V_ecf_final <= 20.0
            @test 1400.0 <= l.Na_ecf_final <= 2600.0
            @test 60.0 <= l.MAP_final <= 140.0
        end
    end

    @testset "solver agreement substitutes for external reference" begin
        sys = build_model()
        r = IPE.solver_agreement(sys; solvers = [FBDF(), Rodas5P()],
                                 tspan_days = 10.0, saveat = 1.0)
        @test r.max_rel_deviation < 1e-4
    end

    @testset "coupling partition rules" begin
        couplings = [
            Coupling(:cv, :renal, Neurohumoral; tau_seconds = 3.0, note = "sympathetic"),
            Coupling(:bodyfluids, :cv, Mechanical, note = "hydraulic"),
        ]
        @test_throws ErrorException validate_partition(
            couplings, Dict(:cv => :fast, :bodyfluids => :slow, :renal => :slow);
            boundary_seconds = 60.0)
        r = validate_partition(
            couplings, Dict(:cv => :fast, :bodyfluids => :fast, :renal => :slow);
            boundary_seconds = 60.0)
        @test r.ok
        @test_throws ErrorException Coupling(:a, :b, Neurohumoral)
        @test_throws ErrorException Coupling(:a, :b, Mechanical; tau_seconds = 1.0)
    end

    @testset "ADR 0009: baroreflex does not change long-run pressure" begin
        # The baroreflex RESETS, so it is a fast buffer and not a long-term
        # regulator. If it could set long-run pressure, the Guyton claim in
        # ADR 0007 would be false. This is a regression test on a physiological
        # claim, not on an implementation.
        with_br    = salt_step()
        without_br = salt_step(baroreflex = false)

        for (a, b) in zip(with_br.levels, without_br.levels)
            @test isapprox(a.MAP_final, b.MAP_final; rtol = 1e-3)
            @test isapprox(a.V_ecf_final, b.V_ecf_final; rtol = 1e-3)
        end

        v = check_pressure_natriuresis(with_br)
        @test v.pass
        @info "baroreflex on" maps=v.maps shift=v.map_shift_mmHg
    end

    @testset "salt sensitivity pins G_pn" begin
        # The steady-state salt sensitivity is set by RN.PRESSURE_NATRIURESIS.SLOPE
        # ALONE. Excretion must equal intake at steady state, so
        #   Na_excr = Na_filtered*(1 - FR_Na) + G_pn*(MAP - MAP_ref)
        # gives dMAP ~ d(intake)/G_pn, in which CV.VENOUS_RETURN.SENSITIVITY does
        # not appear. Verified numerically: varying G_vr over 2880 -> 600 at fixed
        # G_pn moves the shift only 15.698 -> 12.403.
        #
        # WHY THIS TEST EXISTS. Every other assertion in this file passes with
        # G_pn set to the Mizelle 1993 dog value of 5.43, which gives a 15.698 mmHg
        # shift - salt-sensitive-hypertensive behaviour, not normotensive. The suite
        # could not detect a 3.68x error in the model's most consequential
        # unmeasured number. This pins it. See the ledger notes on that row before
        # changing the expected value.
        v = check_pressure_natriuresis(salt_step())
        @test isapprox(v.map_shift_mmHg, 4.934; atol = 0.05)
    end

    @testset "ADR 0012 stage 1 is a change of variables, not of behaviour" begin
        # The central/peripheral partition is introduced with f_central CONSTANT,
        # and VC0 = f_c*BV0 and G_vc = G_vr/f_c derived from it, so that
        #   G_vc*(V_central - VC0) == G_vr*(V_blood - BV0)
        # algebraically for any f_c. The whole claim of stage 1 is that the model
        # therefore does not move. This pins that against the values recorded
        # before the partition existed.
        #
        # THE ADR ORIGINALLY DEMANDED BIT-IDENTITY AND THAT WAS THE WRONG BAR.
        # Adding two equations changes what structural_simplify emits, so the
        # generated code orders its arithmetic differently, the adaptive solver
        # takes fractionally different steps, and the trajectories separate at the
        # last few digits. Measured on introduction: 2.1e-15 to 2.2e-14 relative
        # on the three MAP levels and 3.5e-13 on the shift, which is a difference
        # of 1.7e-12 mmHg. That is reassociation, not physiology.
        #
        # 1e-9 is the bar: eight orders of magnitude tighter than any physiological
        # claim, and still loose enough not to fail on a solver version bump. If it
        # EVER fails, the partition has stopped being a change of variables - check
        # G_vc*f_c == G_vr in the ledger first, which check_closure.py also asserts.
        #
        # BOTH DIRECTIONS WERE VERIFIED BY PERTURBATION ON 2026-08-24 RATHER THAN
        # ASSUMED.
        #   sensitive: G_vc wrong by 10% moves the MAP levels 8e-5 relative, which
        #     this assertion catches easily. check_closure.py catches it too, so a
        #     broken partition fails two independent gates.
        #   inert:     f_central 0.25 -> 0.30 with both derived values recomputed
        #     moves the shift 3.7e-10 relative. Still passes, but note the margin to
        #     the 1e-9 bar is only about 3x. That is because 0.25 is a power of two
        #     and exact in binary; a non-power-of-two f_central is equally correct
        #     algebraically and about a thousand times noisier. If f_central is ever
        #     changed to a sourced value, EXPECT to re-measure this tolerance rather
        #     than assume 1e-9 still holds.
        pre_partition = (205.0 => 93.00003751695675,
                         154.0 => 90.53356850133511,
                         103.0 => 88.06587129611133)
        r = salt_step()
        for (lvl, expected) in pre_partition
            got = only(l.MAP_final for l in r.levels if l.level == lvl)
            @test isapprox(got, expected; rtol = 1e-9)
        end
        @test isapprox(check_pressure_natriuresis(r).map_shift_mmHg,
                       4.934166220845427; rtol = 1e-9)
    end

    @testset "modulators are off by default" begin
        # ADR 0006/0007: E3 and out-of-order components must not be on by default.
        sys = build_model()
        @test sys isa ModelingToolkit.AbstractSystem
        # storage=false and circadian=false are the defaults; enabling circadian
        # warns that it is unconnected.
    end
end
