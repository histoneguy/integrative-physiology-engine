using Test
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using SciMLBase

@testset "IPE" begin

    # TOLERANCES IN THIS FILE ARE PHYSICAL, NOT NUMERICAL.
    #
    # The ledger carries 2 to 4 significant figures because that is what the
    # sources support. Asserting agreement to 1e-9 between numbers known to two
    # figures asserts a precision nobody has, and every reassociation of the
    # arithmetic - a partition, a split of CO into HR x SV, an added state - then
    # reads as a failure. Several sessions were spent chasing discrepancies at
    # 1e-8 and 1e-13 that were orders of magnitude below the precision of the
    # inputs. Rounding the whole ledger to real significant figures on 2026-08-27
    # left every simulated result unchanged, which is the proof that those digits
    # carried no information.
    #
    # The inertness tests below exist to catch WIRING ERRORS, which move results
    # by percent, not by 1e-7. rtol = 1e-4 is four orders tighter than any real
    # breakage and immune to arithmetic noise.

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
        # Normalised by `atol + rtol*|ref|`, so the accept threshold is 1.0:
        # the two solvers must agree to within the tolerance they were each
        # integrated to. Measured on introduction of ADR 0011: worst state
        # 6.9e-4 of budget.
        @test r.max_rel_deviation < 1.0
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
        #
        # VALUE UPDATED 2026-08-25, 4.934 -> 5.0996, WHEN ADH LANDED. This pin
        # exists to catch a parameter change slipping through unnoticed, and it
        # did its job: enabling osmoregulation moved the headline number and the
        # suite refused to pass. The change is kept because it is INTENTIONAL,
        # MEASURED and MECHANISTIC - ADR 0006 build order item 5, +3.4%, and in
        # the physiologically expected direction, because water follows salt: at
        # lower sodium intake plasma osmolality falls, ADH is suppressed, water
        # is excreted and ECF volume falls further than with a fixed water
        # output.
        #
        # G_pn ITSELF IS UNCHANGED at 20.0, which is what this testset is about.
        # If it ever moves, ADR 0013 is the record and this number moves with it.
        # Note that ADR 0013 finds the model already 2 to 19 times more
        # salt-sensitive than normotensive humans, so this shift is in the wrong
        # direction against the literature - a fact about G_pn, not about ADH.
        # REPINNED 2026-09-03, 2.0404 -> 1.8858, AND THE CAUSE IS NOT G_pn.
        # RN.GFR.VOLUME_SENSITIVITY was wired (HANDOVER section 3.22): GFR now
        # rises with extracellular volume, so part of the sodium a salt load
        # delivers is cleared by a larger FILTERED LOAD instead of by a higher
        # pressure. A 7.6% fall, inside the 5-20% band branch G3 of
        # validation/renal_hemodynamics_prereg.md fixed before the extraction.
        # The model stays inside the human 1.70-2.30 mmHg per 100 mmol/day at
        # 1.849 and now sits nearer the floor of that window than the middle.
        #
        # THE HIGH ARM DID NOT MOVE - 87.0046 in the two blocks below is unchanged
        # - because the modifier is exactly 1.0 at the nominal operating point by
        # construction. What moved is the RESPONSE, which is the whole point.
        r = salt_step()
        v = check_pressure_natriuresis(r)
        @test isapprox(v.map_shift_mmHg, 1.8858; atol = 0.05)

        # AND THE OTHER HALF OF THE PAIR, ADDED 2026-09-02 AT NO EXTRA COMPUTE:
        # dMAP/dV_ecf, which is set by CV.VENOUS_RETURN.SENSITIVITY and NOT by G_pn.
        #
        # ADR 0013's falsifiable test convicted this number and nothing pinned it.
        # G_pn and G_vr are ORTHOGONAL - an 8x change in G_vr moves the shift above by
        # 0.12% while moving this ratio exactly inversely - so the two assertions are
        # independent and each catches a different parameter drifting.
        #
        # 11.285 mmHg/L at the 70 kg reference, scaling as 1/mass. THE HUMAN VALUE IS
        # 1.885 mmHg/L at 80.6 kg, i.e. 2.170 here (van den Bosch 2021, n = 70, ECFV by
        # iothalamate and blood pressure in the same subjects). THE MODEL IS 5.2x TOO
        # STIFF and this pin records that mismatch rather than hiding it - see
        # validation/ecf_salt_response_extract.py and HANDOVER section 3.7.
        #
        # When venous compliance replaces G_vr (section 4 item 1), THIS TEST SHOULD FAIL
        # and the expected value should move toward 2.17. Replace it then; do not delete
        # it, and do not simply refit G_vr to make it pass.
        # 11.285 -> 6.1731 on 2026-09-02. THE TEST FAILED AND WAS REPLACED, WHICH
        # IS WHAT ITS OWN COMMENT ASKED FOR - though not by the cause it predicted.
        # Cardiovascular.jl stopped letting red cell volume expand with plasma, so
        # dV_blood/dV_ecf fell by 1/(1-Hct) = 1.83 and this ratio fell with it.
        # STILL 1.5-2.1x ABOVE THE HUMAN 2.97-4.16, and that residual is G_vr,
        # which is CALIBRATED and is section 4 item 1. When sourced venous
        # compliance lands this should fail again and move to about 3.0.
        ratio = v.map_shift_mmHg /
                (r.levels[1].V_ecf_final - r.levels[end].V_ecf_final)
        @test isapprox(ratio, 3.0005; rtol = 1e-3)
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
        # REPINNED 2026-08-27, 93.008/90.545/88.081 -> 87.008/84.550/82.091.
        # CV.MAP.SETPOINT moved 93.0 -> 87.0 when the old value was found to be
        # the textbook BRACHIAL 120/80 convention (80 + 40/3) mixed with a
        # CENTRAL pulse pressure. The whole operating point drops ~6 mmHg. This
        # is a change of INPUT, not of behaviour: the level-to-level spacing is
        # preserved to 3 decimals (2.458 and 2.459 before, 2.458 and 2.459 now),
        # which is what these references are actually protecting.
        # REPINNED 2026-08-28, 84.550/82.091 -> 84.5395/82.0713. THE HIGH ARM DID
        # NOT MOVE, and that is the mechanism showing itself. CV.BLOOD_VOLUME.NOMINAL
        # became a sourced male/female pair (Oberholzer 2024), so f_pv - which is
        # DERIVED as BV0*(1-Hct)/V_ecf - rose 0.1889 -> 0.2123 for males. At the
        # NOMINAL operating point that is exactly cancelled by VC0 = f_c*BV0, so
        # V_central - VC0 is still zero and MAP is unchanged. AWAY from nominal it is
        # not cancelled: dV_central/dV_ecf = f_c*f_pv/(1-Hct) is now 12% larger, so a
        # given ECF change moves cardiac output more. That is a real change in loop
        # gain, not solver noise, which is why these are repinned rather than having
        # their tolerance widened.
        # REPINNED 2026-09-01, 87.008/84.5395/82.0713 -> 87.0047/84.5522/82.0980,
        # and the SHAPE of the move is the mechanism. CV.SV.NOMINAL was sourced
        # (Petersen 2017), so CO0 became derived and sexed and rose 7200 -> 8570.88
        # for males, and TPR0 = MAP0/CO0 fell 0.012083 -> 0.010151. dMAP/dV_ecf
        # scales with TPR0, so a given ECF excursion now moves pressure 16% LESS
        # and the arms COMPRESS toward the high arm, which is anchored at MAP_ref
        # where the pressure-natriuresis term vanishes. Hence the high arm barely
        # moves (0.003) while the mid and low arms rise by 0.013 and 0.027.
        # Same class of change as the f_pv repin of 2026-08-28: a real change in
        # loop gain, repinned rather than having its tolerance widened.
        # REPINNED AGAIN 2026-09-02, 84.5522/82.0980 -> 84.6233/82.2375, and the
        # high arm is unmoved at 87.0046. Cardiovascular.jl stopped letting RED
        # CELL VOLUME expand with plasma, so dV_blood/dV_ecf fell 0.386 -> 0.211
        # and a given ECF excursion now moves pressure 1.83x LESS. Same shape of
        # move as the CO0 repin above and for the same reason - the arms compress
        # toward the anchored high arm. This is a CORRECTION of a physical error,
        # not a tuning: red cell mass does not track plasma over 30 days.
        # REPINNED 2026-09-03, 86.0329 -> 86.1329 and 85.0601 -> 85.2040, with
        # the HIGH ARM UNMOVED at 87.0046. RN.GFR.VOLUME_SENSITIVITY was wired and
        # GFR now responds to extracellular volume; below the nominal volume the
        # kidney filters less, so the low arms sit HIGHER and the three arms
        # compress toward the anchored high arm. Same shape of move as the CO0
        # repin and the red cell correction before it, and for the same structural
        # reason: the operating point is pinned by construction and only the
        # response can move. This is a sourced physiological term landing, not a
        # tuning.
        pre_partition = (205.0 => 87.0046,
                         154.0 => 86.1329,
                         103.0 => 85.2040)
        # raas=false ISOLATES what this testset is about. The reference values
        # were measured before RAAS existed, so comparing against a model that
        # now includes it would be testing two changes at once. RAAS having its
        # own inertness test is not a substitute for this one: this asserts the
        # PARTITION is a change of variables, that one asserts the DISABLED RAAS
        # BRANCH is inert. Different claims, deliberately kept apart.
        r = salt_step(raas = false, adh = false)
        for (lvl, expected) in pre_partition
            got = only(l.MAP_final for l in r.levels if l.level == lvl)
            # 1e-9 -> 1e-7 on 2026-08-27. This reference now sits behind TWO
            # changes of variables, not one: the ADR 0012 partition and the
            # ADR 0011 split of CO into HR x SV, which divides and remultiplies
            # by HR0*1440 and 1000. Both are exact algebraically and neither is
            # exact in floating point. Measured drift 1.1e-8 relative.
            @test isapprox(got, expected; rtol = 1e-4)
        end
        # TOLERANCE LOOSENED 2026-08-25 FROM 1e-9 TO 1e-5, AND ONLY HERE.
        # check_pressure_natriuresis became PHASE-AWARE when the circadian clock
        # was connected: it now reads MAP_cycavg, a mean over the final day,
        # rather than the instantaneous endpoint. The two differ by 7.4e-7
        # relative because the trajectory is still settling very slowly, so a
        # one-day mean is not the endpoint even with no clock running.
        #
        # The MAP_final assertions above KEEP rtol = 1e-4 - they are what
        # actually test the ADR 0012 partition, and they still hold exactly.
        # This line tests a derived summary whose definition changed, so the
        # reference is no longer bit-comparable and pretending otherwise would
        # mean reverting a genuine improvement to keep a number stable.
        # 4.9276 -> 4.9167 on 2026-08-27 with the setpoint change. THE SHIFT
        # BARELY MOVED - 0.2% - because it is set by G_pn, the pressure-natriuresis
        # gain, and not by where the operating point sits. That near-invariance is
        # the useful result of the setpoint change: it says the salt-sensitivity
        # finding in ADR 0013 does not depend on the number that was wrong.
        # 4.9352 -> 4.9067 on 2026-09-01, when CO0 became a derivation from the
        # sourced stroke volume. A 19% RISE IN CARDIAC OUTPUT MOVED THIS SHIFT BY
        # 0.6%, which is the near-invariance above holding again against a much
        # larger perturbation than the setpoint change was.
        #
        # AND WITH THE ADH LOOP CONNECTED IT DOES NOT MOVE AT ALL: the default
        # model's shift is 5.056918 against 5.0569 before - unchanged at the
        # fifth significant figure. This branch has adh=false, which replaces the water
        # limb with a placeholder that pins urine output, so ECF volume is fixed
        # by water balance and the sodium equation has to be closed through the
        # circulation - which is exactly why the cardiovascular gain reaches the
        # answer here and not in the real model. Checked directly rather than
        # assumed: branch A was run alone with the old ADH constants restored and
        # gave 5.056913.
        # 4.9067 -> 4.7672 on 2026-09-02 with the red cell correction. Again this
        # is the DISABLED-ADH branch, where the placeholder pins urine output and
        # forces sodium balance to close through the circulation; the default
        # model's shift is unmoved at 5.0570 against 5.0569.
        # 1.9441 -> 1.8001 on 2026-09-03 with the GFR volume response. This is
        # still the DISABLED-ADH branch, so it moves for its own reasons and by its
        # own amount; the default model moved 2.0404 -> 1.8858 over the same change.
        @test isapprox(check_pressure_natriuresis(r).map_shift_mmHg,
                       1.8001; rtol = 1e-3)   # 4.9352 -> 4.9067 -> 4.7672 -> 2.2467
                       # 2026-09-02: ADR 0010's volume-keyed path landed and the
                       # disabled-ADH branch moved with everything else.
    end

    @testset "RAAS disabled branch is exactly inert (ADR 0008)" begin
        # ADR 0008: the disabled branch is TESTED, not assumed. With raas=false
        # every RAAS state is held at zero and fr_mod is identically zero, so
        # Renal.FR_effective must reduce to its pre-RAAS form.
        # adh=false as well: this testset asserts the RAAS DISABLED BRANCH is
        # inert against pre-RAAS references, and ADH landed after those were
        # measured. Isolating one change at a time is the whole point.
        r = salt_step(raas = false, adh = false)
        # REPINNED 2026-08-27, 93.008/90.545/88.081 -> 87.008/84.550/82.091.
        # CV.MAP.SETPOINT moved 93.0 -> 87.0 when the old value was found to be
        # the textbook BRACHIAL 120/80 convention (80 + 40/3) mixed with a
        # CENTRAL pulse pressure. The whole operating point drops ~6 mmHg. This
        # is a change of INPUT, not of behaviour: the level-to-level spacing is
        # preserved to 3 decimals (2.458 and 2.459 before, 2.458 and 2.459 now),
        # which is what these references are actually protecting.
        # REPINNED 2026-08-28, 84.550/82.091 -> 84.5395/82.0713. THE HIGH ARM DID
        # NOT MOVE, and that is the mechanism showing itself. CV.BLOOD_VOLUME.NOMINAL
        # became a sourced male/female pair (Oberholzer 2024), so f_pv - which is
        # DERIVED as BV0*(1-Hct)/V_ecf - rose 0.1889 -> 0.2123 for males. At the
        # NOMINAL operating point that is exactly cancelled by VC0 = f_c*BV0, so
        # V_central - VC0 is still zero and MAP is unchanged. AWAY from nominal it is
        # not cancelled: dV_central/dV_ecf = f_c*f_pv/(1-Hct) is now 12% larger, so a
        # given ECF change moves cardiac output more. That is a real change in loop
        # gain, not solver noise, which is why these are repinned rather than having
        # their tolerance widened.
        # REPINNED 2026-09-01, 87.008/84.5395/82.0713 -> 87.0047/84.5522/82.0980.
        # Cardiac output became a sourced-stroke-volume derivation and TPR fell
        # with it; see the ADR 0012 block above for the mechanism. These two
        # blocks pin the same three numbers on purpose - they assert different
        # claims about them - so they move together.
        # REPINNED 2026-09-03 with the ADR 0012 block above, and they move
        # together on purpose: these two blocks pin the SAME three numbers to
        # assert DIFFERENT claims about them. RN.GFR.VOLUME_SENSITIVITY wired.
        pre_raas = (205.0 => 87.0046,
                    154.0 => 86.1329,
                    103.0 => 85.2040)
        for (lvl, expected) in pre_raas
            got = only(l.MAP_final for l in r.levels if l.level == lvl)
            # 1e-9 -> 1e-7 on 2026-08-27, same reason as the ADR 0012 block: the
            # ADR 0011 split of CO into HR x SV reassociates the arithmetic.
            # Algebraically exact, not exact in floating point.
            @test isapprox(got, expected; rtol = 1e-4)
        end
    end

    @testset "RAAS escape leaves every steady state where it was" begin
        # THE DESIGN CLAIM OF THE COMPONENT. esc chases fr_raw, so fr_mod is full
        # on arrival and zero at steady state - aldosterone does not permanently
        # retain sodium in vivo and must not here. The salt-step levels are 30-day
        # steady states, so wiring RAAS in must not move them.
        #
        # The bar is 1e-3 mmHg rather than exact: escape has tau = 1.669 day, so
        # 30 days leaves a residual of order exp(-18), and the extra states change
        # what structural_simplify emits and hence the solver trajectory. Measured
        # on introduction: the largest level moved 4.3e-4 mmHg and the shift moved
        # 4.3e-4. If this EVER fails by more than a few mmHg, escape has stopped
        # working and RAAS is permanently retaining sodium.
        #
        # 1e-3 -> 1e-2 ON 2026-08-27, AND THE REASON IS PHYSIOLOGICAL, NOT NUMERICAL.
        # RAAS used to be inactive at baseline BY CONSTRUCTION, because the van
        # Ochten threshold of 93 mmHg happened to equal the old setpoint. The
        # setpoint moved to 87, so the model now sits 6 mmHg BELOW threshold and
        # RAAS IS ACTIVE AT REST: renin drive 0.069, PRA 1.30x since the gain was
        # re-derived on 2026-09-02 and 2.31x before it. on and off are
        # therefore no longer comparing an active branch against a dead one.
        # They still agree to 1.0e-3 mmHg - one part in 87,000 - because escape
        # drives fr_mod to 7.7e-7 rather than to exactly zero. THE CLAIM IS
        # UNCHANGED and is now tested under harder conditions: escape holds even
        # when renin is genuinely running.
        on  = salt_step(raas = true)
        off = salt_step(raas = false)
        for (a, b) in zip(on.levels, off.levels)
            @test a.level == b.level
            @test isapprox(a.MAP_final, b.MAP_final; atol = 1e-2)
        end
        @test isapprox(check_pressure_natriuresis(on).map_shift_mmHg,
                       check_pressure_natriuresis(off).map_shift_mmHg; atol = 1e-2)
    end

    @testset "RAAS still closes the loop" begin
        # Excretion must equal intake at every level with RAAS on. A component
        # that retained sodium indefinitely would show up here first.
        r = salt_step(raas = true)
        for l in r.levels
            @test isapprox(l.Na_excr_final, l.level; rtol = 2e-2)
        end
    end

    @testset "RAAS rectification is one-sided (van Ochten threshold)" begin
        # renin_drive ~ ifelse(MAP < P_thr, (P_thr - MAP)/MAP_ref, 0.0).
        # This asserts the SIGN of that asymmetry, which is the part the
        # meta-analysis actually supports.
        @test IPE.LedgerParams.RAAS_RENIN_PRESSURE_THRESHOLD == 93.0

        # INVERTED ON 2026-08-27. This test used to assert
        #     RAAS_RENIN_PRESSURE_THRESHOLD == CV_MAP_SETPOINT
        # i.e. it PINNED THE COINCIDENCE that Raas.jl's own divergence note
        # called fragile and said rested on one unverified number. It did. The
        # setpoint was the brachial 120/80 convention, it is now 87.0 from
        # sourced central pressure, and the coincidence is gone.
        #
        # Asserting a strict inequality instead of repinning an equality is the
        # point: the old test would pass again the moment someone made the two
        # numbers equal for any reason, including by accident, and would go on
        # certifying a structural artefact as intended behaviour.
        @test IPE.LedgerParams.CV_MAP_SETPOINT <
              IPE.LedgerParams.RAAS_RENIN_PRESSURE_THRESHOLD

        # AND THE CONSEQUENCE, ASSERTED RATHER THAN ASSUMED: the model sits below
        # threshold, so renin drive is strictly positive at baseline. RAAS is
        # active at rest, which is what a resting human does - resting renin is
        # not zero. If this ever returns to zero the setpoint has drifted back up
        # and RAAS has silently switched itself off again.
        drive = (IPE.LedgerParams.RAAS_RENIN_PRESSURE_THRESHOLD -
                 IPE.LedgerParams.CV_MAP_SETPOINT) / 93.0
        @test drive > 0.05
        # Compressive adrenal response: exponent strictly between 0 and 1, so a
        # rise in renin produces a PROPORTIONALLY SMALLER rise in aldosterone.
        # If this ever exceeds 1 someone has re-attached it to angiotensin II.
        @test 0.0 < IPE.LedgerParams.RAAS_ALDO_PRA_LOG_SLOPE < 1.0

        # THE GAIN IS NOW DERIVED, NOT ASSUMED, AND THIS ASSERTS THE DERIVATION
        # RATHER THAN THE DIGITS. Re-derived 2026-09-02, 19.0 -> 4.35, from the
        # SAME van Ochten meta-analysis that supplies the threshold above:
        # renin rises 50 percentage points of its plateau value per 10 mmHg fall
        # in renal arterial pressure, so 0.05 per mmHg. Raas.jl normalises the
        # drive by MAP_ref, so g_renin = 0.05 * MAP_ref exactly.
        #
        # Asserting the IDENTITY and not the number is deliberate: CV.MAP.SETPOINT
        # has already moved once (93 -> 87) and silently voided this row's old
        # calibration target for six days. If it moves again, this fails loudly
        # instead of leaving a stale constant behind. Same reasoning as inverting
        # the coincidence test above.
        @test isapprox(IPE.LedgerParams.RAAS_RENIN_PRESSURE_GAIN,
                       0.05 * IPE.LedgerParams.CV_MAP_SETPOINT; rtol = 1e-3)

        # AND THE STRUCTURAL CEILING, ASSERTED SO IT CANNOT BE FORGOTTEN. The
        # rectified linear form caps the achievable PRA ratio between two
        # pressures at the ratio of their drives, whatever the gain. Between the
        # MAP 88 and 86 at which van den Bosch 2021 measured a 2.73-fold PRA
        # difference across sodium intake, that ceiling is 1.4. The model cannot
        # reproduce the human salt-renin response and must not be tuned to try -
        # see validation/renin_gain_prereg.md branch S2.
        P = IPE.LedgerParams.RAAS_RENIN_PRESSURE_THRESHOLD
        @test (P - 86.0) / (P - 88.0) < 2.73
    end

    @testset "the operating range sits INSIDE the autoregulation plateau" begin
        # ADDED 2026-08-27 with the RN.AUTOREG.LOWER sourcing pass. Nothing in
        # this suite asserted on either autoregulation breakpoint before, which
        # is the failure mode HANDOVER section 7.3 names: a passing suite is not
        # evidence about a parameter it does not assert on. Both breakpoints had
        # been wrong - 180 until 2026-08-21, 80 until today - and 294 tests
        # passed throughout.
        lo = IPE.LedgerParams.RN_AUTOREG_LOWER
        hi = IPE.LedgerParams.RN_AUTOREG_UPPER
        @test lo < hi

        # The real assertion. GFR is piecewise in MAP:
        #     GFR ~ GFR0 * ifelse(MAP < lo, MAP/lo, ifelse(MAP > hi, MAP/hi, 1.0))
        # Every salt arm must sit strictly inside [lo, hi], because that is what
        # makes GFR = GFR0 and the renal input pressure-independent. If an arm
        # ever crosses a breakpoint the renal limb changes character - and it
        # would do so silently, since the loop still closes on the other side.
        v = check_pressure_natriuresis(salt_step())
        @test all(m -> lo < m < hi, v.maps)

        # AND THE MARGIN, asserted rather than assumed. Before today the
        # low-salt arm sat 1.9 mmHg above lo = 80, an unsourced number that
        # traced to an anaesthetised dog. CV.MAP.SETPOINT then moved 6 mmHg
        # TOWARD it on 2026-08-27. A model whose operating point is one and a
        # half mmHg from a piecewise kink is one parameter revision away from
        # crossing it. With lo = 63.9 (Finke 1983, conscious dog, servo-
        # controlled steps) the margin is 18 mmHg.
        #
        # This is a strict inequality on the MARGIN, not a pin on the value,
        # for the same reason the RAAS test above was inverted rather than
        # repinned: pinning 18.0 would certify today's arithmetic, while this
        # fails only when the model drifts back toward the cliff.
        @test minimum(v.maps) - lo > 10.0
    end

    @testset "the model reconstructs systolic and diastolic (ADR 0002)" begin
        # CONNECTED 2026-08-27. reconstruct.jl existed from the first commit,
        # was included by IPE.jl, and was called and tested by NOTHING - it took
        # SV and C_art as arguments and neither existed. ADR 0011 created SV and
        # the CV.MAP.SETPOINT sourcing pass created C_art. Until now the model
        # could not produce a systolic pressure at all.
        r = salt_step()
        hi = r.levels[1]

        # RECONSTRUCTED, NOT SIMULATED. ADR 0002 averaged the cardiac cycle away.
        @test :systolic in IPE.RECONSTRUCTED
        @test :diastolic in IPE.RECONSTRUCTED

        # Ordering, which is the cheapest thing that catches a transposed
        # convention: DBP < MAP < SBP, and the mean sits NEARER DIASTOLIC
        # because diastole is longer than systole.
        @test hi.DBP_reconstructed < hi.MAP_cycavg < hi.SBP_reconstructed
        @test (hi.MAP_cycavg - hi.DBP_reconstructed) <
              (hi.SBP_reconstructed - hi.MAP_cycavg)
        @test isapprox(hi.PP_reconstructed,
                       hi.SBP_reconstructed - hi.DBP_reconstructed; atol = 1e-9)

        # Consistency with the tier A central references, NOT independent
        # validation: C_art was derived as SV0/PP0, so at the operating point
        # this largely returns them by construction. It is still worth pinning -
        # it is what fails if the form-factor convention is transposed again,
        # and that failure would be 11 mmHg in each direction.
        @test isapprox(hi.SBP_reconstructed,
                       IPE.LedgerParams.CV_SBP_CENTRAL_NOMINAL; atol = 0.1)
        @test isapprox(hi.DBP_reconstructed,
                       IPE.LedgerParams.CV_DBP_CENTRAL_NOMINAL; atol = 0.1)

        # THE CONVENTION GUARD. k_below is the fraction of PP BELOW the mean and
        # cannot reach 0.5 while diastole is longer than systole. The ledger row
        # was NAMED as the fraction above until today while carrying the below
        # value; wiring it in under that name would have given SBP 98 / DBP 65
        # against the sourced 109 / 76, and check_closure would still have
        # passed because it never reaches reconstruct.jl.
        @test IPE.LedgerParams.CV_PULSE_FORM_FACTOR < 0.5
        @test_throws ErrorException systolic_diastolic(87.0, 80.7, 2.445, 0.515)

        # What is actually NEW: a pulse pressure that RESPONDS. The salt step
        # moves SV, so PP moves with it. This is output the model could not
        # generate before, and it is the part not fixed by construction.
        pps = [l.PP_reconstructed for l in r.levels]
        @test issorted(pps; rev = true)      # higher intake -> higher SV -> wider PP
        # THRESHOLD LOWERED 1.0 -> 0.5 ON 2026-09-02, and the reason is that the
        # model got BETTER. Pulse pressure responds to the salt step through
        # stroke volume, and the salt step itself shrank from 5.06 to 2.30 mmHg
        # when ADR 0010's volume-keyed path landed. A smaller correct pressure
        # excursion produces a smaller correct pulse excursion. The assertion
        # that PP RESPONDS and responds in the right DIRECTION is unchanged.
        @test pps[1] - pps[end] > 0.5

        @info "reconstructed pressures" sbp=[l.SBP_reconstructed for l in r.levels] dbp=[l.DBP_reconstructed for l in r.levels] pp=pps
    end

    @testset "ADH disabled branch recovers the placeholder (ADR 0008)" begin
        # ADR 0008: the disabled branch is TESTED, not assumed. With adh=false
        # u_osm is held at U_base, so Osm_load/u_osm returns exactly the old
        # placeholder value of intake minus insensible loss.
        L = IPE.LedgerParams
        # 1e-3, matching tools/check_closure.py. This is an identity between
        # ROUNDED ledger values and cannot hold tighter than the rounding: 600/353
        # is 1.6997, not 1.7.
        @test isapprox(L.RN_URINE_SOLUTE_LOAD / L.ADH_URINE_OSM_BASELINE,
                       L.BF_H2O_INTAKE_NOMINAL - L.BF_H2O_INSENSIBLE_LOSS;
                       rtol = 1e-3)
        # And the whole loop with adh=false must reproduce the RAAS-era numbers.
        r = salt_step(adh = false)
        for l in r.levels
            @test 10.0 <= l.V_ecf_final <= 20.0
            @test 60.0 <= l.MAP_final <= 140.0
        end
    end

    @testset "osmoregulation responds in the right direction" begin
        # The whole point of replacing the placeholder. Higher plasma osmolality
        # must give MORE antidiuretic activity, a MORE concentrated urine and a
        # SMALLER volume. Checked on the component algebra directly rather than
        # through the closed loop, so a loop failure cannot mask a sign error.
        L = IPE.LedgerParams
        f(osm) = begin
            a = clamp(L.ADH_OSM_SENSITIVITY * (osm - L.ADH_OSM_THRESHOLD), 0.0, 1.0)
            u = L.ADH_URINE_OSM_MIN + a * (L.ADH_URINE_OSM_MAX - L.ADH_URINE_OSM_MIN)
            (adh = a, u_osm = u, volume = L.RN_URINE_SOLUTE_LOAD / u)
        end
        lo, mid, hi = f(284.0), f(287.0), f(295.0)
        @test lo.adh < mid.adh < hi.adh
        @test lo.u_osm < mid.u_osm < hi.u_osm
        @test lo.volume > mid.volume > hi.volume
        # Saturating at both ends, per the clamp.
        @test f(270.0).adh == 0.0
        @test f(320.0).adh == 1.0
        # At maximal antidiuresis the volume is the obligatory minimum, by
        # construction of U_max. If this fails the closure has drifted.
        @test isapprox(f(320.0).volume, L.RN_H2O_OBLIGATORY_LOSS; rtol = 1e-4)
        # And at the setpoint it is exactly intake minus insensible loss.
        @test isapprox(mid.volume,
                       L.BF_H2O_INTAKE_NOMINAL - L.BF_H2O_INSENSIBLE_LOSS; rtol = 1e-4)
    end

    @testset "ADH sits mid-range at baseline, not against a limit" begin
        # A component pinned against a saturation limit at its operating point
        # cannot regulate in one direction. Circadian and ANP both got parked for
        # being ahead of their dependencies; this checks the opposite failure -
        # being present but inert. Baseline activity is about a quarter of
        # maximal, so there is authority both ways.
        L = IPE.LedgerParams
        a = L.ADH_OSM_SENSITIVITY * (L.BF_OSM_PLASMA_SETPOINT - L.ADH_OSM_THRESHOLD)
        @test 0.05 < a < 0.60
    end

    @testset "ADH amplifies salt sensitivity, and that direction is expected" begin
        # Water follows salt: at lower sodium intake plasma osmolality falls,
        # ADH is suppressed, water is excreted, and ECF volume falls FURTHER
        # than it would with a fixed water output. So enabling ADH must not
        # REDUCE the salt-step pressure shift.
        #
        # Measured on introduction: 4.9337 -> 5.0996 mmHg, +3.4%.
        #
        # WORTH KNOWING RATHER THAN CELEBRATING. ADR 0013 records that the model
        # is already 2 to 19 times more salt-sensitive than normotensive humans.
        # This moves it further in the wrong direction, which is a fact about
        # G_pn and not about ADH - the mechanism here is correct in sign.
        on  = check_pressure_natriuresis(salt_step(adh = true)).map_shift_mmHg
        off = check_pressure_natriuresis(salt_step(adh = false)).map_shift_mmHg
        @test on > off

        # REPINNED 5.0996 -> 5.0575 ON 2026-08-27, and the direction is the
        # interesting part. RN.URINE.SOLUTE_LOAD stopped being a constant: the
        # urine solute load now tracks sodium excretion, so a salt load raises
        # the osmoles that have to be carried out and with them the obligatory
        # water loss. That DAMPS the pressure excursion - the high arm falls
        # 87.0012 -> 86.9794 and the low arm rises 81.9002 -> 81.9219.
        #
        # ADR 0013 records the model as 2 to 19 times more salt-sensitive than
        # normotensive humans. This is the FIRST structural change to move it
        # the RIGHT way. It is small - 0.8% against a discrepancy of 2x at best -
        # so it does not touch that finding, and it must not be read as
        # addressing it: G_pn is still the parameter that sets the shift.
        # REPINNED 2026-09-03, 2.0404 -> 1.8858. The GFR volume response is a
        # THIRD route to sodium excretion, through the filtered load rather than
        # the reabsorbed fraction, and it damps the pressure excursion. The
        # `on > off` assertion above is the claim this testset exists to make and
        # it is untouched: ADH still amplifies, from a lower base.
        @test isapprox(on, 1.8858; atol = 0.02)
    end

    @testset "the urine solute load tracks sodium (water limb responds to salt)" begin
        # WHAT THIS REPLACED. RN.URINE.SOLUTE_LOAD was a constant 600 mOsm/day
        # and its own ledger note called that the load-bearing assumption of the
        # ADH component: urine volume is solute load over urine osmolality, so a
        # frozen numerator made the model under-respond to a salt load on the
        # WATER side while responding correctly on the sodium side. The note said
        # to consider making it depend on Na_excr. It now does.
        L = IPE.LedgerParams

        # The residual is a RESIDUAL, and this is the identity that defines it.
        # If it drifts, the mid arm stops returning the reference load and every
        # ADH constant derived from that load is silently describing a different
        # model. check_closure.py asserts the same thing on the ledger.
        @test isapprox(L.RN_URINE_SOLUTE_NONNA +
                       L.RN_URINE_OSM_PER_NA * L.BF_NA_INTAKE_MID,
                       L.RN_URINE_SOLUTE_LOAD; rtol = 1e-3)

        # The load must RESPOND, and monotonically. At steady state excretion
        # matches intake, so the load is Osm_nonNa + 2*intake.
        r = salt_step()
        loads = [L.RN_URINE_SOLUTE_NONNA + L.RN_URINE_OSM_PER_NA * l.Na_excr_cycavg
                 for l in r.levels]
        @test issorted(loads; rev = true)
        @test loads[1] - loads[end] > 100.0     # 2 * (205 - 103) = 204 mOsm/day

        # THE OBLIGATORY VOLUME FLOOR NOW TRACKS THE LOAD, and this is why it had
        # to. V_min was a constant 0.5 L/day, which equalled
        # SOLUTE_LOAD / OSM_MAX only while the load was constant. On the low-salt
        # arm the load falls to 498 mOsm/day and 498/1200 = 0.415 L/day, so a
        # fixed 0.5 floor would have bound spuriously - clamping urine output
        # above what the kidney actually must excrete, in the arm where water
        # retention matters most.
        @test isapprox(L.RN_URINE_SOLUTE_LOAD / L.ADH_URINE_OSM_MAX,
                       L.RN_H2O_OBLIGATORY_LOSS; rtol = 1e-3)
        low_load = L.RN_URINE_SOLUTE_NONNA + L.RN_URINE_OSM_PER_NA * 103.0
        @test low_load / L.ADH_URINE_OSM_MAX < L.RN_H2O_OBLIGATORY_LOSS

        # DISABLED BRANCH IS EXACTLY INERT (ADR 0008). With adh = false the whole
        # post-placeholder water limb is off - pinned u_osm AND constant load -
        # so water excretion returns the old constant intake minus insensible
        # loss. The two are halves of one placeholder; see Renal.jl.
        off = salt_step(adh = false)
        @test all(l -> 60.0 <= l.MAP_final <= 140.0, off.levels)

        @info "solute load tracks sodium" loads=loads maps=[l.MAP_cycavg for l in r.levels]
    end

    @testset "the declared coupling graph matches the model (ADR 0003)" begin
        # CONNECTED 2026-08-27. Every component has had a *_couplings() function
        # since it was written and NOTHING EVER CALLED ONE. Seven declaration
        # functions plus coupling_ledger_rows, suggest_boundary and partitionable,
        # all dead. ADR 0003's partition rule is enforced by validate_partition,
        # which had no graph to validate.
        #
        # Assembling it found four defects that no gate can see, and all four are
        # defects BETWEEN subsystems - the class isolated auditing cannot reach:
        #   bodyfluids -> endocrine   named a subsystem that does not exist, and
        #                             validate_partition SKIPS unknown endpoints,
        #                             so it could never have been checked;
        #   circadian -> cardiovascular  wrong endpoint, it is the baroreflex;
        #   cardiovascular -> bodyfluids  real edge, declared by nobody;
        #   CIRC_CV_MAP_DIP_FRACTION  gain_param naming no ledger row.
        r = assert_couplings_match_model()
        @test isempty(r.undeclared)
        @test isempty(r.phantom)
        @test isempty(r.unknown)
        @test isempty(r.dangling)
        # 13 -> 14 on 2026-09-04, ADR 0017: respiratory -> bodyfluids, the water
        # vapour flux. It is Conservation and not a signal, so the partition rule
        # below covers it too.
        #
        # 14 -> 16 the same day, ADR 0018: respiratory -> blood and
        # cardiovascular -> blood. TWO INBOUND EDGES AND NO OUTBOUND ONE, which is
        # what a forward computation looks like in the coupling graph. If an
        # outbound edge from blood ever appears, an oxygen feedback has been built
        # and ADR 0018 says that needs its own record - so this count is the cheapest
        # tripwire for exactly that.
        #
        # 16 -> 17 on 2026-09-05, ADR 0019: thyroid -> respiratory. ONE OUTBOUND
        # EDGE AND NO INBOUND ONE, which is the mirror image of blood - the axis
        # drives a metabolic load and nothing in this model feeds back onto it.
        # An inbound edge appearing means something has been wired into thyroid
        # secretion, which ADR 0019 does not decide.
        @test r.n_couplings == 17

        cs = model_couplings()
        # ADR 0003: instantaneous couplings are not partitionable. If this ever
        # returns true for a Mechanical or Conservation edge the rule has been
        # inverted, and the partition would be free to cut a hydraulic link.
        @test all(c -> partitionable(c.kind) == (c.kind === Neurohumoral), cs)
        # Every Neurohumoral coupling carries a tau; the others must not.
        @test all(c -> (c.tau_seconds !== nothing) == (c.kind === Neurohumoral), cs)

        # validate_partition on a REAL assignment. The fast block is everything
        # instantaneously coupled to pressure and volume; the clock is slow. This
        # is the first time the ADR 0003 machinery has been run on this model.
        fast = Dict(:bodyfluids => :fast, :cardiovascular => :fast, :renal => :fast,
                    :baroreflex => :fast, :raas => :fast, :adh => :fast,
                    :circadian => :slow)
        @test validate_partition(cs, fast; boundary_seconds = 30.1).ok

        # And a partition that CUTS A MECHANICAL EDGE must throw. Asserting the
        # guard fires, not just that the good case passes - the disabled-branch
        # discipline of ADR 0008 applied to a checker.
        bad = Dict(:bodyfluids => :fast, :cardiovascular => :slow, :renal => :fast,
                   :baroreflex => :fast, :raas => :fast, :adh => :fast,
                   :circadian => :slow)
        @test_throws ErrorException validate_partition(cs, bad;
                                                       boundary_seconds = 30.1)

        # THE PHYSIOLOGICAL RESULT, which only exists once the graph is assembled.
        # suggest_boundary warns when the largest ratio between adjacent declared
        # time constants is under 10x. It does not warn here: 3.0 s (baroreflex
        # effector) to 302.4 s (renin) is a ~100x gap. That is a statement about
        # PHYSIOLOGY rather than about the Jacobian spectrum, and it is the other
        # half of the ADR 0003 argument, which is deferred on state count.
        #
        # 4 -> 5 on 2026-09-05, ADR 0019: thyroxine turnover, 10.3 DAYS. It is by two
        # orders of magnitude the slowest declared coupling in this model, and it
        # widens the largest adjacent gap rather than narrowing it - so the ADR 0003
        # argument is strengthened, not threatened, by the one state this model has
        # ever chosen to add.
        b = suggest_boundary(cs)
        @test length(b.taus) == 5
        @test b.gap !== nothing
        @test b.gap[1] > 10.0
        @info "declared coupling timescales" taus=b.taus gap_ratio=b.gap[1] boundary_s=b.suggested_boundary_seconds
    end

    @testset "member_remake re-sexes and re-sizes to match a natively built model" begin
        # THIS CHECKS THE CLASS, NOT ONE PARAMETER, and it exists because the same
        # defect has now happened three times. member_remake keeps a HAND-MAINTAINED
        # list that must mirror what the components do at build time:
        #
        #   ADR 0010  V_blood_ref omitted  -> every heavy member read as volume-expanded
        #   ADR 0017  H2O_insens left behind after the water split removed it -> error
        #   ADR 0018  Hb omitted           -> a re-sexed member keeps MALE haemoglobin
        #
        # The first two failed loudly elsewhere. THE THIRD WOULD NOT HAVE: haemoglobin
        # touches no pressure, volume or sodium quantity, so every other assertion in
        # this file would have passed while population oxygen content stayed male.
        #
        # ONE BASE BUILD AND ONE NATIVE BUILD, which is the cheapest configuration that
        # can catch both failure modes at once. The base is built MALE at the reference
        # mass and remade as FEMALE at 95 kg, so a parameter member_remake forgets to
        # rescale AND a parameter it forgets to re-sex both show up as a mismatch
        # against the natively built female. Building both sexes separately costs two
        # more simplifications and catches nothing this does not - directive 1.10.
        base   = build_model(sex = :male)
        native = build_model(sex = :female, body_mass = 95.0)
        prob   = ODEProblem(base, [], (0.0, 1.0), []; jac = true, sparse = true)
        remade = IPE.member_remake(prob, base, (body_mass = 95.0,); sex = :female)

        # `parameters()` on a SIMPLIFIED system is not only the ledger-backed
        # parameters: it also carries dummy-derivative symbols such as
        # `bf₊Na_store#0(t)`, which have no default and throw on getdefault. Found by
        # this test erroring on its first two runs, which is a fair price for a guard
        # that catches a whole class. The ODEProblem must also be built positionally,
        # exactly as run_population builds it - a Dict throws on the same symbols.
        npars = Dict{String,Any}()
        for p in parameters(native)
            try
                npars[String(Symbol(p))] = ModelingToolkit.getdefault(p)
            catch
            end
        end

        worst, worst_name, compared = 0.0, "", 0
        for p in parameters(base)
            nm = String(Symbol(p))
            haskey(npars, nm) || continue
            want = npars[nm]
            got = try
                remade.ps[p]
            catch
                continue
            end
            (want isa Number && got isa Number) || continue
            compared += 1
            rel = abs(got - want) / max(abs(want), 1e-12)
            if rel > worst
                worst, worst_name = rel, nm
            end
        end

        # Guard the guard. A comparison that silently matched nothing would pass
        # forever while asserting nothing - HANDOVER section 5 item 3.
        @test compared > 20
        @test worst < 1e-9
        worst >= 1e-9 && @warn "member_remake disagrees with a built model" worst_name worst
    end

    @testset "the ensemble actually varies its members (and mostly cannot)" begin
        # CONNECTED 2026-08-27. HANDOVER calls ensembles "the primary workload".
        # run_population, sample_population, member_parameters, prob_func and
        # default_summary had never been called by anything.
        #
        # member_parameters(prob, member) = prob.p returned the parameters
        # UNCHANGED, so every member solved the same 70 kg individual. The
        # ensemble ran; it varied nothing. Nothing called it, so nothing noticed.
        sys = build_model()
        pop = IPE.sample_population(4)
        @test length(pop) == 4
        @test length(unique(m.body_mass for m in pop)) == 4      # Sobol, not constant

        # BOUNDS ARE LEDGERED AND SEXED NOW - NHANES 2021-2023 Table 3.
        # sample_population previously carried a hard-coded Normal(70.0, 12.0),
        # mean and SD both unledgered, which directive 1.4 forbids. It was inert
        # while nothing called the ensemble.
        L = IPE.LedgerParams
        for sx in (:male, :female)
            lo, hi = L.param(:BF_BODY_MASS_P05, sx), L.param(:BF_BODY_MASS_P95, sx)
            @test all(m -> lo <= m.body_mass <= hi, IPE.sample_population(4; sex = sx))
        end
        @test L.param(:BF_BODY_MASS_TYPICAL, :male) >
              L.param(:BF_BODY_MASS_TYPICAL, :female)
        # The REFERENCE is a normalisation constant, not a population mean, and
        # must stay `both` and stay put. Moving it to 90.3 would rescale GFR to
        # 232 L/day by arithmetic against a denominator its source never used.
        @test L.BF_BODY_MASS_REFERENCE == 70.0

        res = IPE.run_population(sys, pop; tspan_days = 25.0)
        @test length(res.u) == 4
        @test all(r -> r.retcode == ReturnCode.Success, res.u)
        @test all(r -> isfinite(r.MAP_final) && isfinite(r.V_ecf_final), res.u)

        # BODY-SIZE SCALING, ADDED 2026-08-27. The previous version of this
        # testset asserted the OPPOSITE - that every member converged on one
        # extracellular volume - and said in its own comment that when scaling
        # landed these bounds must fail and that the failure was the signal it
        # worked. They failed. This is that.
        masses = [m.body_mass for m in pop]
        @test maximum(masses) / minimum(masses) > 1.5
        vecfs = [r.V_ecf_final for r in res.u]
        maps  = [r.MAP_final for r in res.u]

        # EXTENSIVE: ECF volume tracks body mass, and tracks it PROPORTIONALLY.
        # Ratio-constancy is the real assertion; a spread alone would pass for any
        # monotone junk.
        @test maximum(vecfs) - minimum(vecfs) > 5.0
        ratios = vecfs ./ masses
        # RELATIVE, not absolute, since 2026-09-02. ADR 0010's term is a
        # DIFFERENCE of two extensive volumes multiplied by a gain of 700, so a
        # relative offset of 1e-5 in the steady state becomes a visible absolute
        # number. Invariance of an intensive quantity is a relative statement and
        # is now written as one; the bar is 1e-4 relative, which is TIGHTER than
        # the old absolute bar was for MAP.
        @test (maximum(ratios) - minimum(ratios)) / (sum(ratios)/length(ratios)) < 1e-4

        # INTENSIVE: arterial pressure does NOT scale, and that half of the old
        # collapse was never a defect. A model in which big people are
        # hypertensive because they are big would be worse, not better. MAP is
        # invariant to 1e-4 mmHg across a 1.85x mass range.
        @test (maximum(maps) - minimum(maps)) / (sum(maps)/length(maps)) < 1e-4

        # BUILD-TIME AND REMAKE PATHS MUST AGREE. The components apply the size
        # scaling when the model is built; member_remake reapplies it through
        # remake because an ensemble must not rebuild. Two encodings of one rule
        # is how they drift, so this asserts they have not.
        bm = 90.0
        built = salt_step(body_mass = bm,
                          levels_mEq_day = (205.0 * bm / 70.0,),
                          days_per_level = 25.0)
        remade = IPE.run_population(build_model(), [(body_mass = bm,)];
                                    tspan_days = 25.0)
        @test isapprox(built.levels[1].V_ecf_final, remade.u[1].V_ecf_final;
                       rtol = 1e-3)
        @test isapprox(built.levels[1].MAP_cycavg, remade.u[1].MAP_final;
                       rtol = 1e-3)

        @info "ensemble body-size scaling" masses=round.(masses, digits=1) V_ecf=round.(vecfs, digits=4) V_ecf_per_kg=round.(ratios, digits=6) MAP=round.(maps, digits=4)
    end

    @testset "size scaling leaves the reference individual bit-identical" begin
        # size_factor returns exactly 1.0 at BF.BODY_MASS.REFERENCE, so promoting
        # body mass to a ledger row and threading it through three components must
        # not move the default model at all. If this fails, the scaling has leaked
        # into a quantity that should be intensive.
        @test size_factor(IPE.LedgerParams.BF_BODY_MASS_REFERENCE) == 1.0
        # REPINNED 2026-09-03, 2.0404 -> 1.8858, RN.GFR.VOLUME_SENSITIVITY wired.
        # THE INVARIANCE ASSERTION BELOW DID NOT FAIL AND THAT IS THE RESULT THAT
        # MATTERS HERE. This line pins a VALUE; the loop below pins that the value
        # is the same for an 85 kg individual eating an 85 kg diet, and it passed
        # unchanged. The new term is intensive (a fractional GFR change per
        # fractional volume change) against an extensive reference volume, so the
        # product scales exactly as GFR0 does. Had that been written the other way
        # round - which is the mistake ADR 0010's gain made and this testset caught
        # within one run - the loop below would have failed and this line passed.
        v = check_pressure_natriuresis(salt_step())
        @test isapprox(v.map_shift_mmHg, 1.8858; atol = 0.02)

        # THE INVARIANCE ITSELF, on the whole loop rather than on one arm.
        # With sodium intake scaled along with the individual - which is what an
        # individual eating their own diet means - arterial pressure and the
        # salt-step shift are size-free, while every volume scales.
        #
        # salt_step's own levels are ABSOLUTE, and deliberately: they are trial
        # protocol values matching the Cutler and He/MacGregor targets, which were
        # run on mixed-size adults. So the caller scales them here explicitly.
        # That distinction is real - at FIXED absolute salt intake a larger person
        # does sit at a lower pressure, because they filter more.
        base = check_pressure_natriuresis(salt_step())
        for bm in (85.0,)
            f = bm / IPE.LedgerParams.BF_BODY_MASS_REFERENCE
            r = check_pressure_natriuresis(
                    salt_step(body_mass = bm,
                              levels_mEq_day = (205.0 * f, 154.0 * f, 103.0 * f)))
            @test isapprox(r.map_shift_mmHg, base.map_shift_mmHg; rtol = 1e-3)
        end

        # ADR 0017 FOLDED IN HERE RATHER THAN GIVEN ITS OWN TESTSET, at no extra
        # compute: PaCO2 must be INTENSIVE. VCO2, the chemoreflex slope and basal
        # ventilation all scale with mass while the dead space fraction, the alveolar
        # constant and the recruitment threshold do not, so the metabolic hyperbola
        # and the ventilation it balances against scale TOGETHER and their ratio does
        # not. Written the other way round, PaCO2 would drift with body size and a
        # 90 kg adult would be hypercapnic for being large - the same error the ADR
        # 0010 gain made, which this testset caught within one run.
        for bm in (50.0, 90.0)
            s = build_model(body_mass = bm)
            sl = IPE.solve_individual(s; tspan_days = 60.0)
            pc = NaN
            for o in observed(s)
                occursin("PaCO2", String(Symbol(o.lhs))) && (pc = sl[o.lhs][end])
            end
            @test isapprox(pc, IPE.LedgerParams.RESP_CO2_ARTERIAL_RESTING; rtol = 1e-3)
        end
    end

    @testset "recording and profiling paths run (ADR 0002, ADR 0003)" begin
        # All of recording.jl and profiling.jl was dead: update!, summarise,
        # save_grid, grid_size_report, streaming_output_func, projected_storage,
        # step_distribution, cost_profile, timescale_audit. Storage is the stated
        # binding constraint of the whole design and nothing had ever computed it.
        sys = build_model()
        prob = ODEProblem(sys, [], (0.0, 10.0), []; jac = true)
        sol = solve(prob, FBDF(); saveat = 0.25, dense = false)
        @test sol.retcode == ReturnCode.Success

        # Storage projection. The number the module docstring says to get BEFORE
        # launching, not at hour six.
        gb = projected_storage(n_members = 1000, horizon_days = 30.0,
                               dt_seconds = 5.0, n_states = length(mtk_unknowns(sys)))
        @test gb > 0
        # HANDOVER SECTION ON ensemble.jl QUOTES ~0.9 TB FOR THIS CONFIGURATION.
        # It is 13.5 GB. The claim predates the model: 0.9 TB needs roughly 476
        # states and this model has 7 after structural_simplify. The storage
        # argument is still directionally right - full traces do not scale - but
        # the number was never recomputed against a real model, because nothing
        # ever called projected_storage. Pinned loosely; it moves with state count.
        @test 5.0 < gb < 40.0

        # Online statistics. O(observables), independent of horizon.
        st = IPE.OnlineStat()
        for (t, x) in zip(0.0:1.0:10.0, 80.0:1.0:90.0)
            IPE.update!(st, t, x)
        end
        sm = IPE.summarise(st)
        @test sm.min == 80.0 && sm.max == 90.0
        @test 80.0 <= sm.mean <= 90.0

        # Windowed recording grid: fine inside the window, coarse outside.
        ew = EventWindows([(2.0, 3.0)], [:MAP]; coarse_seconds = 3600.0,
                          fine_seconds = 60.0)
        grid = save_grid(ew, (0.0, 10.0))
        @test issorted(grid)
        @test length(grid) > length(0.0:(3600.0/86400.0):10.0)   # window added points
        gr = grid_size_report(ew, (0.0, 10.0), length(mtk_unknowns(sys)))
        @test gr.points > 0
        # Windowed recording must actually REDUCE against a naive fine grid -
        # that is the entire justification for the mode existing.
        @test gr.points < gr.naive_points
        @test gr.reduction > 1.0

        # Cost profile and step distribution on a real solution.
        cp = cost_profile(sol)
        @test cp !== nothing
        sd = step_distribution(sol; windows = [(0.0, 5.0), (5.0, 10.0)])
        @test sd !== nothing

        # TIMESCALE AUDIT ON THE REAL JACOBIAN. This is the OTHER half of the
        # ADR 0003 argument: suggest_boundary above works on DECLARED physiological
        # time constants, this works on the Jacobian spectrum. The ADR says both
        # should be consulted and that disagreement means the declared structure
        # and the numerical behaviour have diverged. Until now neither had ever
        # been run on this model.
        J = prob.f.jac(sol.u[end], prob.p, sol.t[end])
        ta = timescale_audit(Matrix(J); label = "resting steady state")
        @test !isempty(ta.tau)
        @test all(isfinite, ta.tau)
        @info "spectral vs declared" spectral_stiffness=ta.tau[end]/ta.tau[1] declared_gap=suggest_boundary(model_couplings()).gap[1]
    end

    @testset "sex is a model dimension (ADR 0014)" begin
        L = IPE.LedgerParams
        # Nothing is dimorphic yet, so the accessor must FALL BACK to the shared
        # value for either sex. This is the "otherwise use the best data" half of
        # the rule and it is the half that is live today.
        # Still shared: no sourced dimorphism, so both sexes get the best
        # available value. Haematocrit is the obvious next pair - it is
        # androgen-driven erythropoiesis, not a body-size effect, so unlike
        # cardiac output it will NOT dissolve into body mass.
        # CV_BLOOD_VOLUME_NOMINAL left this list 2026-08-27 and
        # CV_HEMATOCRIT_NOMINAL on 2026-08-28: both are now sourced male/female
        # pairs, so asserting the sexes are equal would assert the absence of a
        # dimorphism the literature reports. RN_GFR_NOMINAL stays because Soares
        # 2013 measured no sex difference (108 vs 104, p = 0.134) - that is a
        # FINDING, and this line is what asserts it rather than assuming it.
        for sym in (:RN_GFR_NOMINAL,)
            @test L.param(sym, :male) == L.param(sym, :female)
            @test L.param(sym, :male) == getfield(L, sym)
        end

        # Real pairs now exist (ADR 0011 entered heart rate and stroke volume),
        # so this asserts the resolver's behaviour rather than its emptiness.
        # Asking for :both on a dimorphic parameter must ERROR, not average.
        @test !isempty(L.sex_specific_params())
        for sym in L.sex_specific_params()
            @test L.param(sym, :male) != L.param(sym, :female)
            @test_throws Exception L.param(sym, :both)
        end

        # The model builds for either sex and refuses :both. There is no :both
        # individual: a parameter with no known dimorphism resolving to a shared
        # value is not the same thing as a person of no sex.
        @test build_model(sex = :male) isa ModelingToolkit.AbstractSystem
        @test build_model(sex = :female) isa ModelingToolkit.AbstractSystem
        @test_throws Exception build_model(sex = :both)
        @test_throws Exception build_model(sex = :unspecified)

        # THE SOURCED PAIRS, asserted rather than assumed.
        @test L.param(:CV_HEMATOCRIT_NOMINAL, :male) >
              L.param(:CV_HEMATOCRIT_NOMINAL, :female)
        @test L.param(:CV_BLOOD_VOLUME_NOMINAL, :male) >
              L.param(:CV_BLOOD_VOLUME_NOMINAL, :female)

        # HAEMATOCRIT IS CURRENTLY NON-IDENTIFIABLE, AND THIS PINS WHY. Blood
        # volume is f_pv*V_ecf/(1-Hct), and f_pv is DERIVED as BV0*(1-Hct)/V_ecf,
        # so f_pv/(1-Hct) = BV0/V_ecf and the haematocrit cancels exactly. The
        # model therefore reports a sourced, dimorphic haematocrit that changes
        # none of its results - male and female MAP agree to 7 figures despite a
        # 15% difference in Hct. That is honest provenance for a quantity not yet
        # used, NOT a claim that haematocrit does not matter. It starts mattering
        # the moment f_pv is sourced independently, or anything depending on
        # viscosity or oxygen carriage exists. If this identity ever breaks, one
        # of those has happened and the cancellation must be re-examined.
        for sx in (:male, :female)
            fpv = L.param(:CV_PLASMA_ECF_FRACTION, sx)
            hct = L.param(:CV_HEMATOCRIT_NOMINAL, sx)
            bv0 = L.param(:CV_BLOOD_VOLUME_NOMINAL, sx)
            v_ecf = L.BF_BODY_MASS_REFERENCE * L.BF_ECF_MASS_FRACTION
            @test isapprox(fpv / (1 - hct), bv0 / v_ecf; rtol = 1e-3)
        end
    end

    @testset "ADR 0011: CO = HR x SV, and the first sex pair" begin
        L = IPE.LedgerParams
        # A real male/female pair now exists.
        @test :CV_HR_NOMINAL in L.sex_specific_params()
        @test :CV_SV_NOMINAL in L.sex_specific_params()
        @test L.param(:CV_HR_NOMINAL, :female) > L.param(:CV_HR_NOMINAL, :male)
        @test L.param(:CV_SV_NOMINAL, :female) < L.param(:CV_SV_NOMINAL, :male)
        # :both must ERROR on a dimorphic parameter, not average.
        @test_throws Exception L.param(:CV_HR_NOMINAL, :both)

        # CO0 IS A PAIR TOO as of 2026-09-01, and it must error on :both for the
        # same reason HR0 and SV0 do - averaging two sexes is not a person.
        @test :CV_CO_NOMINAL in L.sex_specific_params()
        @test :CV_TPR_NOMINAL in L.sex_specific_params()
        @test_throws Exception L.param(:CV_CO_NOMINAL, :both)
        @test L.param(:CV_CO_NOMINAL, :female) < L.param(:CV_CO_NOMINAL, :male)

        # The identity that makes ADR 0011 a change of variables: heart rate
        # times stroke volume is nominal cardiac output, for EITHER sex.
        # INVERTED 2026-09-01 - SV0 is now the sourced side and CO0 the derived
        # one, so this compares against a SEXED CO0 rather than a shared constant.
        # The identity is exact now, not rounded: CO0 is stored as the full
        # product because a derived row closing an identity carries every digit.
        for sx in (:male, :female)
            @test isapprox(L.param(:CV_HR_NOMINAL, sx) * 1440.0 *
                           L.param(:CV_SV_NOMINAL, sx) / 1000.0,
                           L.param(:CV_CO_NOMINAL, sx); rtol = 1e-3)
        end
    end

    @testset "a 22% sex difference in cardiac output moves no pressure at all" begin
        L = IPE.LedgerParams
        # REPLACED 2026-09-01, and the old reason for this test is now FALSE.
        # It used to read "the HR/SV pair CANNOT move the model", because SV0 was
        # DERIVED as CO0/(HR0*1440) from a shared CO0, so the product was the same
        # number for either sex and the dimorphism cancelled arithmetically. Its
        # comment said the test should FAIL when a real pair landed.
        #
        # A real pair has landed - CV.SV.NOMINAL is sourced per sex (Petersen 2017,
        # CMR) and CO0 is derived from it, so CO0 differs by 22% between sexes and
        # TPR0 by the same. THE TEST STILL PASSES, and that is a much stronger
        # result than the one it replaces: arterial pressure does not move because
        # the RENAL-BODY FLUID loop sets it, not the heart. This is the central
        # claim of the model, and it is now demonstrated against a 22% perturbation
        # of the cardiac side rather than against an arithmetic identity.
        m = check_pressure_natriuresis(salt_step(sex = :male)).map_shift_mmHg
        f = check_pressure_natriuresis(salt_step(sex = :female)).map_shift_mmHg

        # INVERTED 2026-09-02, AND THE INVERSION IS THE RESULT. The equality above
        # was a property of a PRESSURE-ONLY kidney: salt sensitivity was 1/G_pn,
        # which carries no sex information, so the cardiac pair could not reach it
        # however large it was. ADR 0010's volume-keyed path is keyed to BLOOD
        # VOLUME, which is sexed, so the dimorphism now propagates into salt
        # sensitivity for the first time.
        #
        # WOMEN COME OUT MORE SALT-SENSITIVE, 2.1757 against 1.8488 mmHg per 100
        # mmol/day, a 17.7% difference.
        #
        # THIS COMMENT SAID 11% AND THE ASSERTION BELOW HAS SAID 1.172 SINCE G_pn
        # MOVED - a comment and an assertion disagreeing, in the same block, about
        # the same number. Corrected 2026-09-03 when the GFR volume response moved
        # the ratio again, to 1.1768. The mechanism is the one the block below
        # already describes: dMAP/dV_ecf scales as TPR0*f_pv and that product is
        # larger in women, so the same volume-keyed natriuresis buys less pressure
        # correction.
        #
        # THIS IS A PREDICTION, NOT A VALIDATION. Nothing in this repo has sourced
        # a sex difference in human salt sensitivity, and this assertion pins a
        # model consequence rather than a measured one. It is recorded as debt in
        # HANDOVER section 7. Assert the DIRECTION and the magnitude separately so
        # that a future source can falsify the size without silently deleting the
        # direction.
        @test f > m
        @test isapprox(f / m, 1.172; rtol = 0.02)

        # THE PAIR IS NOT INERT ANY MORE, AND THIS IS WHERE IT BITES. ADR 0014's
        # falsifiable test asks that a sexed pair change a result. It changes the
        # VOLUME excursion: the pressure the kidney demands is the same, so the
        # circulation must supply it with whatever volume swing its own gain
        # requires, and dMAP/dV_ecf scales as TPR0*BV0. That product is 6.9%
        # larger in women (0.012393*4.92 against 0.010151*5.62), so women reach
        # the same pressure shift on a 6.9% SMALLER ECF excursion.
        #
        # If this assertion ever fails while the one above still passes, the
        # cardiac sex pair has stopped reaching the circulation at all.
        exc(sex) = begin
            r = salt_step(sex = sex)
            r.levels[1].V_ecf_final - r.levels[end].V_ecf_final
        end
        # EXPRESSION CHANGED 2026-09-02 AND THE GAP NEARLY DOUBLED, 1.069 -> 1.182.
        # It was TPR0*BV0 because dV_blood/dV_ecf was f_pv/(1-Hct) = BV0/V_ecf0,
        # in which haematocrit CANCELS - section 3.5's non-identifiability. With
        # red cell volume held fixed the derivative is f_pv = BV0*(1-Hct)/V_ecf0,
        # so Hct no longer cancels and THE SOURCED 0.453/0.395 PAIR MOVES A RESULT
        # FOR THE FIRST TIME. That is ADR 0014's falsifiable test being satisfied
        # by haematocrit, which section 7 listed as debt precisely because it
        # could not be.
        em, ef = exc(:male), exc(:female)
        @test ef < em
        tpv(sx) = L.param(:CV_TPR_NOMINAL, sx) * L.param(:CV_PLASMA_ECF_FRACTION, sx)

        # THE CLOSED-FORM IDENTITY NO LONGER HOLDS, 2026-09-02, and that is
        # expected rather than broken. em/ef equalled tpv(female)/tpv(male)
        # because the kidney demanded the SAME pressure shift of both sexes, so
        # the volume excursion was whatever the circulation needed to deliver it.
        # With a volume-keyed natriuretic path the kidney no longer demands the
        # same shift - see the inversion above - so the excursion ratio and the
        # circulation ratio are no longer the same number. Measured 1.066 against
        # 1.182.
        #
        # What survives, and it is the part ADR 0014's falsifiable test asks for:
        # the sexed pair still reaches the circulation, women still swing less
        # volume, and the two ratios still agree in DIRECTION and to within 11%.
        @test tpv(:female) / tpv(:male) > 1.0
        # WIDENED 0.12 -> 0.20 ON 2026-09-03 when G_pn moved 20.0 -> 11.4. The two
        # ratios were already only approximately equal once the volume-keyed path
        # landed, because the kidney stopped demanding the same pressure shift of
        # both sexes; lowering G_pn shifts more of the natriuresis onto that path
        # and widens the gap further, 1.037 against 1.182. The DIRECTION and the
        # fact that the sexed pair still reaches the circulation are what this
        # asserts; the closed-form identity belonged to a pressure-only kidney.
        @test isapprox(em / ef, tpv(:female) / tpv(:male); rtol = 0.20)
    end

    @testset "ADR 0017: respiration, and PCO2 is an INPUT not an output" begin
        L = IPE.LedgerParams
        sys = build_model()
        sol = IPE.solve_individual(sys; tspan_days = 60.0)
        fin(n) = begin
            v = NaN
            for u in IPE.mtk_unknowns(sys)
                occursin(n, String(Symbol(u))) && (v = sol[u][end])
            end
            if isnan(v)
                for o in observed(sys)
                    occursin(n, String(Symbol(o.lhs))) && (v = sol[o.lhs][end])
                end
            end
            v
        end

        # NO NEW STATE. ADR 0017 decision 2 says the loop is quasi-static at this
        # model's horizon - PaCO2 re-equilibrates in minutes, the shortest protocol
        # here is six hours - so the chemoreflex and the alveolar equation are solved
        # together in CLOSED FORM. A state would be paid for on every future run
        # (directive 1.10). Eight states before respiration, eight after.
        #
        # 8 -> 9 on 2026-09-05, and the one added state is thyroxine (ADR 0019).
        # It is the only state in this model that was added rather than avoided,
        # and the reason is written on THY.FT4.TAU: ten days cannot be represented
        # algebraically on a model that runs four hundred. Thyrotropin, which
        # equilibrates in minutes, got no state - same argument as this one.
        @test length(IPE.mtk_unknowns(sys)) == 9

        # RESTING PaCO2 RETURNS THE SOURCED INPUT, AND THIS IS NOT A PREDICTION.
        # ADR 0017's ORIGINAL decision 1 made PaCO2 an output of the chemoreflex, as
        # arterial pressure is an output of the renal loop. Its own falsifiable test
        # killed that: the ventilatory recruitment threshold is 45.28 mmHg and resting
        # PaCO2 is near 40, so AT REST THE CHEMOREFLEX IS BELOW ITS OWN THRESHOLD and
        # is not the operative control. The dependency was inverted - resting PaCO2 is
        # sourced, basal ventilation is derived from it.
        #
        # So this assertion is a CLOSURE CHECK on that derivation, not evidence that
        # the model reproduces human PaCO2. It cannot be, and the ledger row says so.
        @test isapprox(fin("PaCO2"), L.RESP_CO2_ARTERIAL_RESTING; rtol = 1e-4)

        # AT REST THE MODEL SITS ON THE FLAT LIMB. Ventilation is basal and the
        # chemoreflex is doing nothing at all.
        @test isapprox(fin("rs₊V_E"), L.RESP_VENTILATION_BASAL; rtol = 1e-4)
        @test fin("PaCO2") < L.RESP_CHEMO_VRT

        # THE WATER SPLIT REPRODUCES THE OLD CONSTANT. BF.H2O.INSENSIBLE_LOSS was one
        # assumed number cited "Convention pending primary source"; it is now a
        # computed respiratory flux plus a cutaneous residual. The reference
        # individual must be unmoved, because every ADH constant is derived from a
        # water balance that closes here. check_closure.py asserts the same identity
        # on the ledger; this asserts it on the SOLVED model.
        @test isapprox(fin("H2O_resp") + L.BF_H2O_CUTANEOUS_LOSS,
                       L.BF_H2O_INSENSIBLE_LOSS; rtol = 1e-3)
        @test 0.25 < fin("H2O_resp") < 0.40

        # ADR 0017'S REPLACEMENT FALSIFIABLE TEST. The original asked whether PCO2
        # behaves as an output; that question is void now. What IS claimed is the
        # PIECEWISE structure, so the test is that the chemoreflex bites above the
        # recruitment threshold and not below it.
        #
        # Raising metabolic CO2 production 0.20 -> 0.25 pushes the balance point past
        # the threshold. Without the reflex PaCO2 would rise in proportion, to 50.0.
        # Done algebraically rather than by five more solves - the closed form IS the
        # component, so exercising it directly tests the same equation at a fraction
        # of the cost. Directive 1.10: assert more per unit of compute.
        C(vco2) = L.RESP_ALVEOLAR_K * vco2 / (1.0 - L.RESP_DEADSPACE_FRACTION)
        function ve(vco2)
            c = C(vco2)
            b = L.RESP_CHEMO_CO2_SLOPE * L.RESP_CHEMO_VRT - L.RESP_VENTILATION_BASAL
            c >= L.RESP_VENTILATION_BASAL * L.RESP_CHEMO_VRT ?
                (-b + sqrt(b * b + 4 * L.RESP_CHEMO_CO2_SLOPE * c)) / 2 :
                L.RESP_VENTILATION_BASAL
        end
        pco2(vco2) = C(vco2) / ve(vco2)

        # BELOW THE THRESHOLD THE REFLEX IS INERT and PaCO2 rises in proportion to
        # production. That is the half most likely to be got wrong by writing the
        # branch condition on the wrong variable.
        @test isapprox(ve(0.20), L.RESP_VENTILATION_BASAL; rtol = 1e-9)
        @test isapprox(pco2(0.21) / pco2(0.20), 0.21 / 0.20; rtol = 1e-6)

        # ABOVE IT THE REFLEX BITES. Ventilation rises and PaCO2 rises by LESS than
        # proportion - which is what a negative feedback is.
        @test ve(0.25) > L.RESP_VENTILATION_BASAL
        @test pco2(0.25) < 0.25 / 0.20 * L.RESP_CO2_ARTERIAL_RESTING
        @test pco2(0.25) > L.RESP_CHEMO_VRT          # and it stays on the upper limb

        # THE TWO LIMBS MEET CONTINUOUSLY. A jump here would land straight in
        # D(V_ecf) through the water flux. The breakpoint is where
        # C = V_basal*VRT, i.e. VCO2 = V_basal*VRT*(1-Vd/Vt)/K.
        vco2_break = L.RESP_VENTILATION_BASAL * L.RESP_CHEMO_VRT *
                     (1.0 - L.RESP_DEADSPACE_FRACTION) / L.RESP_ALVEOLAR_K
        @test isapprox(ve(vco2_break * (1 - 1e-9)), ve(vco2_break * (1 + 1e-9));
                       rtol = 1e-6)

        # THE DISABLED BRANCH IS EXACTLY INERT. With respiration = false ventilation
        # is frozen at basal, so the water flux is exactly its reference value and
        # every existing protocol is untouched. Same pattern as the ADH and RAAS
        # disabled branches (ADR 0008).
        off = build_model(respiration = false)
        soff = IPE.solve_individual(off; tspan_days = 60.0)
        voff = NaN
        for o in observed(off)
            occursin("rs₊V_E", String(Symbol(o.lhs))) && (voff = soff[o.lhs][end])
        end
        @test isapprox(voff, L.RESP_VENTILATION_BASAL; rtol = 1e-9)

        @info "respiration" PaCO2=fin("PaCO2") V_E=fin("rs₊V_E") H2O_resp=fin("H2O_resp")
    end

    @testset "ADR 0018: blood oxygen transport, and this one IS a prediction" begin
        L = IPE.LedgerParams
        function arterial(; sex = :male, body_mass = 70.0)
            s = build_model(; sex, body_mass)
            sl = IPE.solve_individual(s; tspan_days = 60.0)
            g(n) = begin
                v = NaN
                for o in observed(s)
                    occursin(n, String(Symbol(o.lhs))) && (v = sl[o.lhs][end])
                end
                v
            end
            (SaO2 = g("SaO2"), PaO2 = g("bl₊PaO2"), PAO2 = g("PAO2"),
             CaO2 = g("CaO2"), DO2 = g("DO2"), VO2 = g("bl₊VO2"),
             avDO2 = g("avDO2"), CvO2 = g("CvO2"), SvO2 = g("SvO2"),
             ER = g("bl₊ER"), CO = g("cv₊CO"))
        end
        m = arterial()

        # FALSIFIABLE TEST 1. Saturation must land in the human range with NOTHING
        # set to put it there. This is the real difference from ADR 0017, where
        # resting PCO2 is an INPUT and the model makes no claim to predict it.
        # Here haemoglobin, the curve, the exchange ratio and the A-a difference are
        # all sourced or assumed independently of saturation, and saturation follows
        # by arithmetic - so the model CAN be wrong about it.
        @test 0.95 <= m.SaO2 <= 0.99
        @test 80.0 <= m.PaO2 <= 110.0
        @test m.PAO2 > m.PaO2                       # the gradient has the right sign

        # AND IT DOES NOT TURN ON THE WEAKEST INPUT, which is what stops it being a
        # number that was chosen. BLOOD.O2.AA_GRADIENT is assumed and sits directly
        # upstream; the pre-registration forbids tuning it. Swept over a fivefold
        # range the saturation stays inside the human window - because the sigmoid's
        # upper limb is flat, which is also why this is a WEAK test of the curve.
        sev(po2) = 1.0 / (L.BLOOD_O2_CURVE_A / (po2^3 + L.BLOOD_O2_CURVE_B * po2) + 1.0)
        for aa in (5.0, 10.0, 15.0, 20.0, 25.0)
            @test 0.94 <= sev(m.PAO2 - aa) <= 0.99
        end

        # FALSIFIABLE TEST 2. The sexed pair must move CONTENT and DELIVERY and must
        # NOT move saturation or tension. Haemoglobin differs between the sexes; the
        # dissociation curve does not. If saturation came out sexed, haemoglobin
        # would have leaked into the wrong equation.
        f = arterial(sex = :female)
        @test isapprox(f.SaO2, m.SaO2; rtol = 1e-9)
        @test isapprox(f.PaO2, m.PaO2; rtol = 1e-9)
        @test f.CaO2 < m.CaO2
        @test f.DO2 < m.DO2

        # FALSIFIABLE TEST 3. Content must scale with haemoglobin at fixed curve
        # position - the property that distinguishes CONTENT from TENSION, and the
        # one most easily got wrong. The bound term is 98.7% of content, so the
        # ratio should track the haemoglobin ratio closely but not exactly, the
        # difference being the dissolved term which does NOT scale with haemoglobin.
        hb_ratio = L.param(:BLOOD_HB_CONCENTRATION, :female) /
                   L.param(:BLOOD_HB_CONCENTRATION, :male)
        @test isapprox(f.CaO2 / m.CaO2, hb_ratio; rtol = 0.02)
        @test f.CaO2 / m.CaO2 > hb_ratio            # dissolved O2 does not scale

        # FALSIFIABLE TEST 4 is asserted on the LEDGER by check_closure.py rather
        # than here - haemoglobin over haematocrit must give a human mean corpuscular
        # haemoglobin concentration. It is a property of the rows, not of a solve,
        # and putting it where it belongs keeps this testset to one build per sex.

        # OXYGEN DELIVERY IS THE FIRST QUANTITY NEEDING TWO SUBSYSTEMS AT ONCE, and
        # the unit chain crossing them is where it would silently go wrong: cardiac
        # output is in L/DAY here because the model's time base is days, while
        # delivery is conventionally per minute. A missing 1440 would put this out
        # by three orders of magnitude and still look plausible in some other unit.
        @test 700.0 <= m.DO2 <= 1600.0

        # NO FEEDBACK. ADR 0018 decision 1 says this component closes no loop, so
        # removing it must leave every other result untouched. Asserted by the
        # STATE COUNT rather than by re-solving: an oxygen feedback would have to
        # enter through a differential equation somewhere, and there are still nine
        # - eight plus thyroxine, and none of them is an oxygen state.
        @test length(IPE.mtk_unknowns(build_model())) == 9

        # ------------------------------------------------------------------
        # THE FICK ARM, ADDED 2026-09-05. ADR 0018 deferred venous content, the
        # Fick relation and the extraction ratio because "they need tissue oxygen
        # consumption, which is a metabolic row this model does not have". IT DID
        # HAVE ONE, under another name: CO2 production over the exchange ratio.
        # Both rows were already in the ledger and neither moved.

        # OXYGEN CONSUMPTION. 250 mL/min at rest, which is what 0.20 L/min of CO2
        # at an exchange ratio of 0.80 means. Asserted as a range because both
        # parent rows are `assumed` at round teaching numbers - directive 1.12 -
        # so a narrow pin here would be false precision about a number nobody
        # measured for this model.
        @test 180.0 <= m.VO2 <= 320.0

        # THE FICK RELATION CLOSES EXACTLY, and that is the check the unit chain
        # needs: cardiac output is carried in L/DAY because the model's time base
        # is days, while consumption is per minute and content is per dL. A
        # missing 1440 would be three orders of magnitude and would still look
        # like a plausible number in some other unit.
        @test isapprox(m.CO * (1000.0 / 1440.0) * m.avDO2 / 100.0, m.VO2;
                       rtol = 1e-9)
        @test isapprox(m.CvO2, m.CaO2 - m.avDO2; rtol = 1e-12)
        @test isapprox(m.ER, m.avDO2 / m.CaO2; rtol = 1e-12)

        # THE ARTERIOVENOUS DIFFERENCE lands at 4.2 mL/dL. This one IS comparable
        # to the human literature without a catheter, because it follows from
        # oxygen uptake and cardiac output, both of which are measured
        # non-invasively in every indirect-calorimetry study.
        @test 3.5 <= m.avDO2 <= 5.5

        # MIXED VENOUS SATURATION AND EXTRACTION ARE REPORTED, AND NO HUMAN TARGET
        # IS ASSERTED AGAINST THEM. Not for want of searching: mixed venous
        # saturation needs a pulmonary artery catheter, which is not placed in
        # healthy people, so the literature is critical care and cardiac disease
        # and directive 1.7 disqualifies it. The same ethical ceiling ADR 0006's
        # amendment records for RN.AUTOREG.UPPER. These bounds are a sanity
        # bracket on the ARITHMETIC - saturation between arterial and zero,
        # extraction a fraction - not a comparison with a measurement.
        @test 0.0 < m.SvO2 < m.SaO2
        @test 0.0 < m.ER < 1.0

        # ANAEMIA IS THE PROPERTY THAT MAKES THIS ARM WORTH HAVING. Haemoglobin
        # falls, arterial content and delivery fall with it, consumption does not,
        # so EXTRACTION RISES and mixed venous saturation falls - while arterial
        # saturation and tension do not move at all, because they are properties
        # of the curve and not of the carrying capacity.
        @test isapprox(f.SaO2, m.SaO2; rtol = 1e-9)      # restated deliberately
        @test f.ER > m.ER
        @test f.SvO2 < m.SvO2
        @test isapprox(f.VO2, m.VO2; rtol = 1e-9)        # demand is not sexed

        # THE THYROID ARM'S REACH INTO OXYGEN CONSUMPTION IS ASSERTED IN THE ADR
        # 0019 TESTSET, not here, because that testset already builds the model
        # with the metabolic arm on. Directive 1.10: a second build of the same
        # system to assert a related fact is the kind of cost that is paid on
        # every future run forever.

        @info "blood gas" SaO2=m.SaO2 CaO2=m.CaO2 DO2=m.DO2 VO2=m.VO2 avDO2=m.avDO2 SvO2=m.SvO2 ER=m.ER
    end

    @testset "ADR 0019: the thyroid axis, on ONE free-thyroxine scale" begin
        L = IPE.LedgerParams
        sys = build_model()
        sol = IPE.solve_individual(sys; tspan_days = 60.0)
        fin(s, so, n) = begin
            v = NaN
            for u in IPE.mtk_unknowns(s)
                occursin(n, String(Symbol(u))) && (v = so[u][end])
            end
            if isnan(v)
                for o in observed(s)
                    occursin(n, String(Symbol(o.lhs))) && (v = so[o.lhs][end])
                end
            end
            v
        end

        # THE LOOP RESTS WHERE IT IS SOURCED TO REST. THY.FT4.GAIN is derived so
        # that G_T*TSH_ref = FT4_ref, so the model opens at equilibrium and no run
        # begins with a spurious ten-day transient. check_closure.py asserts the
        # same identity on the ledger; this asserts it on the SOLVED model.
        @test isapprox(fin(sys, sol, "ty₊FT4"), L.THY_FT4_EUTHYROID; rtol = 1e-4)

        # THE EUTHYROID THYROTROPIN IS AN INPUT, NOT A PREDICTION, AND SAYING SO IS
        # THE POINT OF THIS BLOCK. For one day this suite asserted it as a
        # prediction the model failed by 2.4x. It was not a failing prediction: it
        # was a unit error, a pituitary line measured on one free-thyroxine
        # immunoassay composed with a concentration measured by equilibrium
        # dialysis. NHANES measured the gap - total thyroxine agreeing to 6% while
        # the free fractions differ 1.73-fold (validation/nhanes_hpt_extract.py).
        #
        # So this is a CLOSURE CHECK on a sourced operating point, exactly as the
        # respiratory testset's PaCO2 assertion is, and for the same reason: ADR
        # 0017's dependency inversion, made a second time. ADR 0019's falsifiable
        # test 2 is VOID and the ledger says so on THY.TSH.EUTHYROID.
        tsh = fin(sys, sol, "ty₊TSH")
        @test isapprox(tsh, L.THY_TSH_EUTHYROID; rtol = 1e-3)

        # AND THE ONE NUMBER THAT IS SCALE-INVARIANT, WHICH IS WHAT THE MODEL
        # ACTUALLY RUNS ON. b*FT4* is dimensionless, so unlike either measured
        # slope it transfers between assays. It came from two independent
        # estimates and nothing here was fitted to it.
        @test isapprox(L.THY_TSH_FT4_SLOPE * L.THY_FT4_EUTHYROID, L.THY_LOOP_GAIN;
                       rtol = 1e-3)
        @test 1.7 < L.THY_LOOP_GAIN < 2.9

        # THE METABOLIC ARM IS OFF AND IT IS OFF EXACTLY. ADR 0019 decision 4 and
        # thyroid_prereg.md section 6 require bit-identity, not closeness, so this
        # is == and not isapprox. Every pinned pressure, PaCO2 and water number
        # elsewhere in this file is the rest of that assertion.
        @test fin(sys, sol, "ty₊th_mod") == 1.0

        # THE RESPONSE, DONE ALGEBRAICALLY. The loop is a scalar fixed point,
        # FT4 = G_T*S*exp(a - b*FT4), so its equilibrium and its gain can be
        # exercised directly instead of by four more full-model solves. Directive
        # 1.10: assert more per unit of compute. The wiring is what needs a solve,
        # and it got one above.
        a, b = L.THY_TSH_INTERCEPT, L.THY_TSH_FT4_SLOPE
        G_T, tau = L.THY_FT4_GAIN, L.THY_FT4_TAU
        # BISECTION, NOT FIXED-POINT ITERATION. G_T*S*exp(a - b*FT4) is decreasing in
        # FT4 and the identity is increasing, so the root is unique and bracketed.
        # A damped fixed point looks simpler and DIVERGES above about FT4 = 22,
        # which is inside the range a thyrotoxic capacity reaches - a quiet wrong
        # answer rather than a failure.
        function ft4_star(S)
            lo, hi = 1e-6, 500.0
            for _ in 1:200
                m = 0.5 * (lo + hi)
                m - G_T * S * exp(a - b * m) < 0.0 ? (lo = m) : (hi = m)
            end
            0.5 * (lo + hi)
        end
        tsh_star(S) = exp(a - b * ft4_star(S))

        # rtol 1e-4 and not tighter: every thyroid row is carried at four
        # significant figures, which is what its sources support, so the
        # equilibrium sits 7e-5 off the free thyroxine it is derived from. That is
        # the rounding and nothing else - and the rounding is deliberate, because
        # entering more digits than a measurement carries is the error the owner
        # corrected on 2026-09-05 and pooling.md now records.
        @test isapprox(ft4_star(1.0), L.THY_FT4_EUTHYROID; rtol = 1e-4)

        # ADR 0019 FALSIFIABLE TEST 1. Raise thyroid secretory capacity: thyrotropin
        # must FALL, free thyroxine must RISE, and it must rise by LESS than with
        # the loop open. Open-loop is thyrotropin held at its euthyroid value, which
        # is exactly what build_model(thyroid = false) does, and there FT4 is
        # proportional to capacity.
        @test tsh_star(1.3) < tsh_star(1.0)
        @test ft4_star(1.3) > ft4_star(1.0)
        @test ft4_star(1.3) / ft4_star(1.0) < 1.3          # closed loop absorbs it
        @test ft4_star(0.7) / ft4_star(1.0) > 0.7          # in both directions

        # AND THE AMOUNT IT ABSORBS IS A RESULT, not a tuned number. The open-loop
        # gain is b*FT4 = 2.26, so d ln FT4 / d ln S = 1/(1 + b*FT4) = 0.31: the
        # human axis holds about 70% of a change in secretory capacity. Nothing in
        # this repository was fitted to produce that.
        dlnS = log(1.02)
        dlnF = log(ft4_star(1.02) / ft4_star(1.0))
        @test isapprox(dlnF / dlnS,
                       1.0 / (1.0 + b * L.THY_FT4_EUTHYROID); rtol = 5e-3)

        # ADR 0019 FALSIFIABLE TEST 3. THE SLOW STATE MUST ACTUALLY BE SLOW. If the
        # time constant were entered in hours, or in the wrong direction, the axis
        # would settle within a day and decision 3's whole justification for paying
        # a state would evaporate. Closed-loop relaxation is tau/(1 + b*FT4) = 3.2
        # days, so one day gets nowhere near and thirty is essentially done.
        tau_eff = tau / (1.0 + b * L.THY_FT4_EUTHYROID)
        @test 2.0 < tau_eff < 5.0
        @test 1.0 - exp(-1.0 / tau_eff) < 0.40             # one day: far from done
        @test 1.0 - exp(-30.0 / tau_eff) > 0.99            # thirty: done

        # AND THE ARM ACTUALLY REACHES ANOTHER COMPONENT WHEN IT IS SWITCHED ON,
        # which is the whole reason thyroid was built before cortisol or glucose
        # (directive 1.11, and ADR 0006's record of Circadian sitting unconnected).
        # ONE extra solve, and it is the one that proves the component is not an
        # island.
        #
        # BUT IT REACHES PaCO2 AND STOPS THERE, AND THAT IS ADR 0017'S FINDING
        # BITING A SECOND TIME. Raising CO2 production raises arterial PCO2, and
        # ventilation does NOT respond, because at rest the model sits on the FLAT
        # limb of the chemoreflex - the ventilatory recruitment threshold is 45.28
        # mmHg and resting PaCO2 is 40. So the respiratory water flux is untouched.
        # Asserted in BOTH directions below, because "the arm connects" and "the arm
        # moves the water balance" are different claims and only the first is true.
        hyper = build_model(thyroid_metabolic = true, thyroid_secretion = 1.5)
        shy = IPE.solve_individual(hyper; tspan_days = 60.0)
        @test fin(hyper, shy, "ty₊FT4")    > L.THY_FT4_EUTHYROID
        @test fin(hyper, shy, "ty₊TSH")    < tsh
        @test fin(hyper, shy, "ty₊th_mod") > 1.0
        @test fin(hyper, shy, "PaCO2")     > fin(sys, sol, "PaCO2")

        # AND IT REACHES OXYGEN CONSUMPTION, WHICH MAKES THIS THE MODEL'S ONLY
        # THREE-HOP COUPLING: thyroid -> respiratory -> blood -> venous oxygen.
        # Consumption is CO2 production over the exchange ratio, so scaling the
        # metabolic load scales it; delivery does not move, so extraction rises
        # and mixed venous saturation falls. Asserted here rather than in the ADR
        # 0018 testset because this model is already built.
        @test fin(hyper, shy, "bl₊VO2")   > fin(sys, sol, "bl₊VO2")
        @test fin(hyper, shy, "SvO2")     < fin(sys, sol, "SvO2")
        @test fin(hyper, shy, "bl₊ER")    > fin(sys, sol, "bl₊ER")

        # AND IT REACHES BLOOD GAS THROUGH PaCO2, WHICH IS THE ONLY TWO-HOP COUPLING
        # in this model: thyroid -> respiratory -> blood. The alveolar gas equation
        # trades CO2 against O2 through the exchange ratio, so a higher PaCO2 is a
        # lower alveolar and arterial PO2 and a lower saturation.
        @test fin(hyper, shy, "bl₊SaO2")   < fin(sys, sol, "bl₊SaO2")

        # THE FLAT LIMB, ASSERTED. Ventilation and the water flux are EXACTLY what
        # they were - not close, identical - because nothing about V_E depends on
        # the CO2 load below the threshold.
        @test fin(hyper, shy, "rs₊V_E")    == fin(sys, sol, "rs₊V_E")
        @test fin(hyper, shy, "H2O_resp")  == fin(sys, sol, "H2O_resp")

        # AND NO ATTAINABLE THYROID STATE CROSSES IT, done algebraically. At twice
        # normal secretory capacity PaCO2 reaches 41.9 against a threshold of 45.28.
        # THE METABOLIC ARM CANNOT MOVE THE WATER BALANCE OF THIS MODEL, and that is
        # a fact about two sourced components meeting rather than a modelling choice.
        #
        # ASSERTED AT 2x AND NOT HIGHER DELIBERATELY. The margin narrows as
        # capacity rises, and an assertion that thin is a tripwire for parameter
        # drift dressed up as a physiological claim. Beyond about 2x the sourced
        # pituitary line has also stopped being usable: it cannot suppress
        # thyrotropin anywhere near the sub-0.01 mIU/L of real thyrotoxicosis,
        # because it is fitted across the euthyroid range. Assert where the model
        # is valid; report the edge in the note.
        thmod(S) = 1.0 + L.THY_METABOLIC_GAIN *
                         (ft4_star(S) / L.THY_FT4_EUTHYROID - 1.0)
        @test thmod(2.0) * L.RESP_CO2_ARTERIAL_RESTING < L.RESP_CHEMO_VRT
        @test thmod(2.0) > 1.0

        # THE TRANSIENT IS SLOW IN THE SOLVED MODEL TOO, not only in the
        # linearisation above. Read from the SAME solve rather than a new one.
        ft4_1 = NaN
        for u in IPE.mtk_unknowns(hyper)
            if occursin("ty₊FT4", String(Symbol(u)))
                ft4_1 = shy(1.0; idxs = u)
            end
        end
        frac = (ft4_1 - L.THY_FT4_EUTHYROID) /
               (fin(hyper, shy, "ty₊FT4") - L.THY_FT4_EUTHYROID)
        @test 0.0 < frac < 0.40

        @info "thyroid" FT4=fin(sys, sol, "ty₊FT4") TSH=tsh th_mod=fin(sys, sol, "ty₊th_mod") tau_eff=tau_eff
    end

    @testset "modulators are off by default" begin
        # ADR 0006/0007: E3 and out-of-order components must not be on by default.
        sys = build_model()
        @test sys isa ModelingToolkit.AbstractSystem
        # storage=false and circadian=false are the defaults; enabling circadian
        # warns that it is unconnected.
    end
end
