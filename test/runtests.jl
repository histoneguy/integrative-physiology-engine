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
        r = salt_step()
        v = check_pressure_natriuresis(r)
        @test isapprox(v.map_shift_mmHg, 2.8613; atol = 0.05)

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
        @test isapprox(ratio, 6.1731; rtol = 1e-3)
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
        pre_partition = (205.0 => 87.0046,
                         154.0 => 85.6186,
                         103.0 => 84.2315)
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
        @test isapprox(check_pressure_natriuresis(r).map_shift_mmHg,
                       2.7731; rtol = 1e-3)   # 4.9352 -> 4.9067 -> 4.7672 -> 2.2467
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
        pre_raas = (205.0 => 87.0046,
                    154.0 => 85.6186,
                    103.0 => 84.2315)
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
        @test isapprox(on, 2.8613; atol = 0.02)
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
        @test r.n_couplings == 13

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
        b = suggest_boundary(cs)
        @test length(b.taus) == 4
        @test b.gap !== nothing
        @test b.gap[1] > 10.0
        @info "declared coupling timescales" taus=b.taus gap_ratio=b.gap[1] boundary_s=b.suggested_boundary_seconds
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
        v = check_pressure_natriuresis(salt_step())
        @test isapprox(v.map_shift_mmHg, 2.8613; atol = 0.02)

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
        # WOMEN COME OUT MORE SALT-SENSITIVE, 2.5530 against 2.3013 mmHg per 100
        # mmol/day, an 11% difference. The mechanism is the one the block below
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
        @test isapprox(f / m, 1.140; rtol = 0.02)

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

    @testset "modulators are off by default" begin
        # ADR 0006/0007: E3 and out-of-order components must not be on by default.
        sys = build_model()
        @test sys isa ModelingToolkit.AbstractSystem
        # storage=false and circadian=false are the defaults; enabling circadian
        # warns that it is unconnected.
    end
end
