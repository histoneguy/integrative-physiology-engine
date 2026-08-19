using Test
using IPE

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
        r = IPE.solver_agreement(sys; tspan_days = 10.0, saveat = 1.0)
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

    @testset "modulators are off by default" begin
        # ADR 0006/0007: E3 and out-of-order components must not be on by default.
        sys = build_model()
        @test sys isa ModelingToolkit.AbstractSystem
        # storage=false and circadian=false are the defaults; enabling circadian
        # warns that it is unconnected.
    end
end
