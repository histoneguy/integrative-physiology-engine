"""
Cardiovascular mechanics - MINIMAL.

STRUCTURE SOURCES
  MAP = CO x TPR: definitional.
  Venous return / Frank-Starling dependence of cardiac output on filling:
    Guyton AC, Coleman TG, Granger HJ. Annu Rev Physiol 1972;34:13-46.

EVIDENCE (ADR 0006)
  E1  MAP = CO x TPR. Definitional.
  E1  Cardiac output rises with venous return, which rises with blood volume.
  --  The linearised SENSITIVITY of CO to blood volume is CALIBRATED. See ledger.

STRUCTURE (ADR 0012)
  Blood volume is partitioned into a central (intrathoracic) and a peripheral
  compartment, and cardiac output is keyed to CENTRAL filling. At stage 1 the
  central fraction is constant, so the partition is a change of variables and
  every result is bit-identical - see the note on the CO equation.

STRUCTURE (ADR 0011)
  Cardiac output is HEART RATE x STROKE VOLUME. Heart rate is a parameter,
  not a state, until a chronotropic baroreflex exists. Stroke volume carries
  the filling dependence and is the quantity reconstruct.jl has needed since
  the repository began.

WHAT THIS DELIBERATELY OMITS
  Contractility, arterial and venous compliance as states, regional flows,
  and the circadian modulation in ADR 0005.

  Splanchnic and limb capacitance are ONE peripheral compartment and cannot be
  told apart. Per ADR 0012 that disqualifies any paradigm which dissociates them
  from calibrating the partition.

  TPR is no longer a constant - the baroreflex scales it (ADR 0009). RAAS will
  scale it further when it lands, multiplicatively on the same tpr_mod path.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    CV_VENOUS_RETURN_SENSITIVITY,
    CV_CENTRAL_FRACTION, CV_CENTRAL_CO_SENSITIVITY,
    RBC_LIFESPAN, RBC_PRODUCTION_GAIN,
    BF_BODY_MASS_REFERENCE

"""
    Cardiovascular(; name)

Blood volume from extracellular fluid, cardiac output from blood volume, pressure
from cardiac output.

Inputs   V_ecf (L)
Outputs  MAP (mmHg), CO (L/day), V_blood (L)

MAP is an OUTPUT of the closed loop, not a setpoint. Nothing in this component
regulates it. Its stability comes entirely from renal pressure natriuresis acting
through fluid volume - which is the central claim of the Guyton formulation and is
what this minimal model exists to demonstrate.
"""
function Cardiovascular(; name, sex::Symbol = :male,
                        body_mass = BF_BODY_MASS_REFERENCE)

    # SURFACE-like for the flows, MASS-like for the volumes - see src/scaling.jl.
    # Cardiac output and stroke volume are conventionally indexed to body surface
    # area; blood volume is entered in this ledger as mL/kg.
    sz = size_factor(body_mass)
    mz = mass_factor(body_mass)

    # THE REFERENCE RED CELL VOLUME, RESOLVED ONCE IN JULIA, ADR 0023. It is the
    # initial condition for V_rbc, and it has to be a NUMBER rather than the
    # symbolic product Hct*BV0: a symbolic state default becomes an initialization
    # EQUATION, which then collides with every caller that supplies its own u0 -
    # which is every salt-step level, every ensemble member and every perturbation.
    #
    # Resolved once and used for the parameter defaults AND the state default, so
    # the reference is stated in exactly one place. Writing it twice is failure
    # mode 21 and it is how two copies of a constant drift apart.
    hct_ref  = LedgerParams.param(:CV_HEMATOCRIT_NOMINAL, sex)
    bv0_ref  = mz * LedgerParams.param(:CV_BLOOD_VOLUME_NOMINAL, sex)
    vrbc_ref = hct_ref * bv0_ref

    pars = @parameters begin
        # EXTENSIVE: a flow and two volumes.
        # SEXED as of 2026-09-01. CO0 is now DERIVED from the sourced stroke
        # volume and heart rate (CO0 = HR0*SV0*1440/1000), and both of those are
        # male/female pairs, so this is one too. It was a shared `both` row while
        # it carried the conventional 5 L/min, which is what made the HR/SV pair
        # cancel out of every result.
        CO0    = sz * LedgerParams.param(:CV_CO_NOMINAL, sex)
        # SEXED as of 2026-08-27 (Oberholzer 2024, CO rebreathing): 80.3 mL/kg in
        # men, 70.3 in women. f_pv and VC0 are DERIVED from it and are sexed with
        # it, so all three go through the ADR 0014 accessor.
        BV0    = bv0_ref
        # TPR CARRIES THE RECIPROCAL, and this is the line that keeps arterial
        # pressure intensive. MAP = CO*TPR, CO ~ s, so TPR ~ 1/s or big people
        # would be hypertensive. Physically that is right: resistance falls as
        # the vascular bed gets larger. See src/scaling.jl.
        # DERIVED as MAP0/CO0 and therefore sexed with CO0.
        TPR0   = LedgerParams.param(:CV_TPR_NOMINAL, sex) / sz   # scaled by reflex
        # Resolved through the sex-aware accessor rather than read as a bare
        # constant. While CV.HEMATOCRIT.NOMINAL carries a single `both` row this
        # returns that value for either sex; the moment a male/female pair is
        # entered it starts returning the right one, with no change here.
        Hct    = hct_ref
        f_pv   = LedgerParams.param(:CV_PLASMA_ECF_FRACTION, sex)   # DERIVED from BV0
        G_vr   = CV_VENOUS_RETURN_SENSITIVITY      # CALIBRATED - see ledger
        f_c    = CV_CENTRAL_FRACTION               # PLACEHOLDER - cancels, see below
        VC0    = mz * LedgerParams.param(:CV_CENTRAL_VOLUME_NOMINAL, sex)  # = f_c*BV0
        # G_vc is dCO/dV_central. Both numerator and denominator are extensive,
        # so the SENSITIVITY is intensive and must NOT scale.
        G_vc   = CV_CENTRAL_CO_SENSITIVITY         # DERIVED = G_vr / f_c
        # HR is INTENSIVE - resting heart rate does not track body mass in
        # adults - so stroke volume carries the whole of the cardiac scaling.
        HR0    = LedgerParams.param(:CV_HR_NOMINAL, sex)   # 1/min, SEX-SPECIFIC
        SV0    = sz * LedgerParams.param(:CV_SV_NOMINAL, sex)   # mL, EXTENSIVE
        # ADR 0023. BOTH INTENSIVE: a lifespan is a time and the gain is
        # dimensionless, so neither scales with body mass. The extensive part of
        # erythropoiesis is the reference red cell volume Hct*BV0, which scales
        # through BV0 as it already did - the mistake HANDOVER section 3.30
        # records for G_vn, avoided here by construction because the gain is
        # stated as a fractional response to a fractional signal.
        tau_life = RBC_LIFESPAN            # day; the model's time base IS days
        G_epo    = RBC_PRODUCTION_GAIN     # dimensionless
    end

    vars = @variables begin
        # All algebraic - no defaults. V_ecf arrives by connection; the rest
        # follow from it. Defaults here would overdetermine initialization.
        V_ecf(t)        # L        INPUT from body fluids
        tpr_mod(t)      # unitless INPUT from baroreflex (1.0 = no reflex action)
        hr_mod(t)       # unitless INPUT from baroreflex, ADR 0022 (1.0 = none)
        sat_rel(t)      # unitless INPUT from blood, ADR 0023 (1.0 = at reference)
        o2_deficit(t)   # unitless fractional deficit in oxygen CAPACITY
        V_plasma(t)     # L
        V_rbc(t) = vrbc_ref    # L  STATE, ADR 0023 - red cell volume
        Hct_eff(t)      # fraction live red cell fraction of blood volume
        V_blood(t)      # L
        V_central(t)    # L        intrathoracic; the filling variable (ADR 0012)
        V_periph(t)     # L        everything else; V_central + V_periph = V_blood
        SV(t)           # mL       stroke volume (ADR 0011)
        HR(t)           # 1/min    heart rate, reflex-modulated (ADR 0022)
        CO(t)           # L/day
        TPR(t)          # mmHg/(L/day)
        MAP(t)          # mmHg     OUTPUT
    end

    eqs = [
        V_plasma ~ f_pv * V_ecf,

        # RED CELL VOLUME IS CONSTANT. CORRECTED 2026-09-02.
        #
        # This read V_blood ~ V_plasma / (1 - Hct) with Hct a constant PARAMETER,
        # which makes red cell volume expand in proportion to plasma. Over the
        # 30-day salt step this model runs, red cell mass does not move at all -
        # erythrocyte lifespan is ~120 days and erythropoiesis answers to EPO, not
        # to sodium. A plasma expansion DILUTES the haematocrit; it does not
        # recruit erythrocytes.
        #
        # Hct*BV0 is the red cell volume at the nominal operating point, and it is
        # EXTENSIVE, so it scales with body mass through BV0 as it should.
        #
        # THE NOMINAL POINT IS BIT-IDENTICAL AND THAT IS BY CONSTRUCTION. f_pv is
        # DERIVED as BV0*(1-Hct)/V_ecf0, so at V_ecf = V_ecf0
        #
        #     V_plasma + Hct*BV0 = (1-Hct)*BV0 + Hct*BV0 = BV0
        #
        # exactly. What changes is the DERIVATIVE, which is the whole point:
        #
        #     dV_blood/dV_ecf   was  f_pv/(1-Hct) = 0.386
        #                       now  f_pv         = 0.211
        #
        # a factor of 1/(1-Hct) = 1.83. That term sets dMAP/dV_ecf, which ADR
        # 0013's falsifiable test found to be 2.7-5.2x too stiff against seven
        # human primaries. This closes 1.83x of it; the rest is G_vr, which is
        # CALIBRATED and is HANDOVER section 4 item 1.
        #
        # AND IT MAKES HAEMATOCRIT IDENTIFIABLE FOR THE FIRST TIME. Section 3.5
        # records that Hct cancels: f_pv is derived FROM it, so f_pv/(1-Hct) =
        # BV0/V_ecf0 and the sourced male/female pair could not move any result.
        # It cancels in the LEVEL. It does not cancel in the DERIVATIVE, which is
        # now f_pv = BV0*(1-Hct)/V_ecf0 - so the 0.453/0.395 pair finally bites.
        # RED CELL VOLUME IS A STATE. ADR 0023, 2026-09-16, AND IT REPLACES THE
        # CONSTANT ABOVE - the comment above this one is the 2026-09-02 correction
        # that made red cells stop expanding with plasma, and it was right as far
        # as it went. What it left is a term that can be LOST AND NEVER RECOVERED,
        # which the haemorrhage perturbation measured: a 1 L bleed settles at
        # 16.65 L of extracellular fluid against a starting 14.56, permanently,
        # because replacing 0.453 L of red cells with plasma costs 2.15 L of
        # extracellular expansion. The acute limb was right and the chronic limb
        # was a fiction.
        #
        # BV0 STILL APPEARS AND IT IS NOW ONLY THE REFERENCE. Hct*BV0 is the red
        # cell volume the ledger is stated at; it sets the production rate and the
        # initial condition, and it never moves. That split - reference parameter
        # against live variable - is erythropoiesis_prereg.md section 2, fixed
        # before any source was opened, because section 3.8 records what happened
        # last time haematocrit played two roles at once.
        #
        # PRODUCTION EQUALS DESTRUCTION AT THE REFERENCE BY CONSTRUCTION, NOT BY
        # TUNING. At o2_deficit = 0 the first term is exactly Hct*BV0/tau_life and
        # the second is V_rbc/tau_life, so the state is stationary at V_rbc =
        # Hct*BV0 identically, for any gain and any lifespan. The operating point
        # cannot move, which is what the pre-registration required and what
        # check_closure.py now asserts.
        #
        # THE LOOP GAIN IS THE RECOVERY RATE, AND THAT IS THE WHOLE IDENTIFIABILITY
        # STORY. Linearising, the deficit decays with time constant
        # tau_life/(1+G_epo) = 120/5 = 24 days. Lifespan and gain are therefore NOT
        # separately identified by the recovery data they came from - only their
        # ratio is - and RBC.LIFESPAN's note says so rather than pretending the
        # split is measured. Nothing in this model reads the lifespan alone.
        #
        # DESTRUCTION IS FIRST-ORDER AND THAT IS A NAMED SIMPLIFICATION. Real red
        # cells die at a fixed AGE: survival is near-rectangular, not exponential.
        # This gets the mean lifespan right and the distribution wrong, which
        # matters to a cohort-labelling experiment and does not matter to a volume
        # balance. Declared in the pre-registration section 5, before building.
        # THE SENSED SIGNAL IS TOTAL OXYGEN-CARRYING CAPACITY AGAINST ITS
        # REFERENCE - red cell mass times how well it is saturated - AND IT IS NOT
        # ARTERIAL CONTENT. erythropoiesis_prereg.md section 4 pre-registered
        # content, and content was wrong. THE PRE-REGISTRATION WAS WRONG AND THE
        # TEST SUITE IS WHAT CAUGHT IT, which is the only reason to write one.
        #
        # WHAT WENT WRONG: content is a CONCENTRATION. Expand the plasma and it
        # falls with no red cell lost, so a content-keyed loop reads a salt load as
        # anaemia and grows erythrocytes. Measured, before this was changed: across
        # the 205 -> 103 mEq/day salt step red cell volume moved 2.546 -> 2.507 L
        # and salt sensitivity went 2.98 -> 4.24, a 42% shift in the model's
        # headline result. That is HANDOVER section 3.8's defect exactly - red
        # cells expanding with plasma - returning through a different door five
        # weeks after it was closed, and the comment forty lines above this one
        # states the physiology it violates: a plasma expansion DILUTES the
        # haematocrit, it does not recruit erythrocytes.
        #
        # WHY CONTENT IS WRONG PHYSIOLOGICALLY, WHICH IS THE PART THAT MATTERS:
        # dilutional anaemia does not drive erythropoiesis, because the kidney
        # senses oxygen DELIVERY against its own consumption and flow rises to meet
        # the fall in concentration. That is why normovolaemic haemodilution is
        # tolerated at all.
        #
        # AND DELIVERY WAS TRIED AND IS NOT AVAILABLE HERE. CO*CaO2 would be the
        # right reduction, but this model's cardiac output is far too insensitive
        # to blood volume to supply the compensation - the venous return term gives
        # an elasticity of 0.22, so delivery still carries three quarters of the
        # dilution artefact. The correction cannot be made with what the model has.
        #
        # SO THE LOOP REGULATES CAPACITY, NOT CONCENTRATION, and the cost is stated
        # rather than hidden: the deficit is deliberately NOT normalised by blood
        # volume. Every volume perturbation this model can express is a PLASMA
        # perturbation, and it has no viscosity, no renal blood flow and no renal
        # oxygen consumption with which to tell dilution from depletion. Keying to
        # capacity gets the cases the model HAS right and gives up a case it does
        # not have.
        #
        # SATURATION IS STILL IN IT, AND THAT IS WHY THE EDGE FROM BLOOD SURVIVES.
        # A fall in arterial saturation raises production at unchanged red cell
        # mass, so the hypoxic limb is built and will work the day an inspired
        # oxygen fraction or an altitude becomes an input. Today FiO2 and the
        # barometric pressure are constants, so sat_rel is 1.0 and this term is
        # inert - the same discipline the thyroid metabolic arm is wired under.
        # THE REFERENCE HERE IS THE SYMBOLIC Hct*BV0 AND NOT THE JULIA CONSTANT
        # vrbc_ref, AND THE DIFFERENCE IS NOT COSMETIC. vrbc_ref is resolved at
        # BUILD time, so it is baked into the compiled equation and `remake` cannot
        # move it; every ensemble member would then be judged against the 70 kg
        # male reference. Measured before this was corrected: a heavy member read
        # its own perfectly normal red cell mass as polycythaemia, suppressed
        # production, lost blood volume, and the kidney compensated out to 20.7 L
        # of extracellular fluid against a natively built 18.7.
        #
        # vrbc_ref survives for the INITIAL CONDITION only, where a number is
        # exactly what is required. Reference in the equations, number in the
        # state default, one source for both.
        o2_deficit ~ 1.0 - sat_rel * (V_rbc / (Hct * BV0)),

        # PRODUCTION AND DESTRUCTION, AND THE GAIN IS EXACTLY THE RECOVERY RATE.
        # Because the deficit is now proportional to the red cell mass deficit with
        # a coefficient of ONE, linearising gives d(dV)/dt = -(1+G_epo)/tau_life *
        # dV, so the time constant is tau_life/(1+G_epo) = 120/5 = 24 days - which
        # is RBC.RECOVERY_TAU, the number the gain was derived from. THAT WOULD NOT
        # HAVE HELD UNDER THE PRE-REGISTERED CONTENT SIGNAL: the coefficient there
        # is (1-Hct) = 0.55, the closed loop would have run at 33 days rather than
        # 24, and the ledger row would have been asserting an identity the model
        # did not satisfy - failure mode 22, a calibrated parameter quietly
        # re-estimated by a second path.
        D(V_rbc) ~ (Hct * BV0 / tau_life) * (1.0 + G_epo * o2_deficit) -
                   V_rbc / tau_life,

        V_blood  ~ V_plasma + V_rbc,

        # THE LIVE HAEMATOCRIT, AND IT IS A DIFFERENT OBJECT FROM THE PARAMETER Hct
        # THREE LINES UP. Hct is the reference the ledger is stated at and it may
        # never move; Hct_eff is what a centrifuge would read now. Conflating them
        # would move every derived cardiovascular row, which is why the split was
        # written down in advance.
        Hct_eff  ~ V_rbc / V_blood,

        # ADR 0012 stage 1: the central/peripheral partition. f_c is constant in
        # time, so this is a CHANGE OF VARIABLES and nothing else. VC0 = f_c*BV0
        # and G_vc = G_vr/f_c are both derived from f_c, so
        #
        #     G_vc * (V_central - VC0) == G_vr * (V_blood - BV0)
        #
        # identically, for any f_c. Every result is bit-identical to the version
        # before the partition existed, which is ADR 0012 falsifiable test 3 and
        # is asserted in the test suite. The point of stage 1 is not to change a
        # number - it is that V_central EXISTS, so that a natriuretic term and
        # the cardiopulmonary receptors have a variable with a receptor behind it,
        # and so that immersion is expressible as a different constant f_c at
        # unchanged V_blood. Stage 2 makes f_c posture-dependent, at which point
        # it stops cancelling and MUST be sourced first.
        V_central ~ f_c * V_blood,
        V_periph  ~ V_blood - V_central,

        # ADR 0011: CARDIAC OUTPUT IS HEART RATE TIMES STROKE VOLUME.
        #
        # Stroke volume carries the filling dependence; heart rate is a parameter
        # until a chronotropic baroreflex exists (ADR 0009 gives the reflex one
        # effector, tpr_mod, and a second is its own decision).
        #
        # G_vc is a sensitivity of CO to central volume in (L/day)/L, so dividing
        # by beats per day converts it to a stroke-volume sensitivity, and the
        # 1000 puts SV in mL. Written this way the identity
        #
        #     HR0 * 1440 * SV == CO0 + G_vc * (V_central - VC0)
        #
        # holds exactly, so this is a CHANGE OF VARIABLES like ADR 0012 stage 1
        # and moves nothing. What it buys is that HR and SV EXIST: separately
        # measurable in humans where G_vr never was, a stroke volume for
        # reconstruct.jl which has taken one as an argument since the repo began,
        # and the variable a chronotropic reflex will act on.
        #
        # SEX ENTERS HERE AND CURRENTLY CANCELS. HR0 and SV0 are a male/female
        # pair, but SV0 is DERIVED as CO0/(HR0*1440) and CO0 is shared, so their
        # product is CO0 for either sex and the model does not move. That is not a
        # failure of the wiring - it is what it means for cardiac output to have
        # no sex-specific row yet. Katori 1979 found no sex difference in cardiac
        # INDEX or stroke INDEX once normalised to body surface area, so the real
        # dimorphism is body size, and body_mass is still a hard-coded 70.0.
        SV  ~ max(0.0, SV0 + (G_vc / (HR0 * 1440.0)) * (V_central - VC0) * 1000.0),
        # ADR 0022: HEART RATE IS NOW REFLEX-MODULATED. hr_mod arrives from the
        # baroreflex and is EXACTLY 1.0 at every steady state, because the reflex
        # resets - so this line is bit-identical to `CO ~ HR0*1440*SV/1000` at
        # rest and differs only in transients. That is asserted, not assumed.
        #
        # STROKE VOLUME DELIBERATELY KEEPS THE UNMODULATED HR0 IN ITS
        # DENOMINATOR. Putting hr_mod there too would make filling depend on the
        # reflex, which is a force-interval or filling-time coupling that nothing
        # here sources and that would silently change what CV.SV.NOMINAL means.
        # The identity HR0*1440*SV == CO0 + G_vc*(V_central - VC0) therefore
        # still holds exactly, and cardiac output is that quantity times hr_mod.
        #
        # WHAT THIS DOES NOT REPRESENT: heart rate responding to atrial stretch.
        # Jensen 2013's Table 4 measures pulse rate RISING about 3 beats/min on a
        # 23 mL/kg saline load while systolic pressure stays flat, and an arterial
        # baroreflex cannot produce that. The candidate is the cardiopulmonary
        # limb, which ADR 0009 names as a separate component and which this model
        # does not have. See ADR 0022's falsifiable test 5.
        # HEART RATE IS A NAMED OUTPUT NOW THAT IT VARIES. It was implicit in the
        # cardiac output expression while it was a constant; a quantity the reflex
        # moves should be readable, and the GUI reads this.
        HR  ~ HR0 * hr_mod,
        CO  ~ HR * 1440.0 * SV / 1000.0,

        # TPR is now a STATE-DEPENDENT quantity, scaled by baroreflex outflow.
        # It was a constant until the baroreflex landed; tpr_mod = 1.0 recovers
        # the previous behaviour exactly.
        TPR ~ TPR0 * tpr_mod,

        MAP ~ CO * TPR,
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    cardiovascular_couplings()

All Mechanical: volume to filling to output to pressure is a hydraulic chain with
no lag at this resolution. Per ADR 0003 no partition may cut across any of it.
"""
function cardiovascular_couplings()
    return [
        Coupling(:bodyfluids, :cardiovascular, Mechanical,
                 note = "V_ecf -> plasma -> blood volume -> venous return"),
        Coupling(:cardiovascular, :renal, Mechanical,
                 note = "MAP drives filtration and pressure natriuresis"),
        # DECLARED 2026-08-27. This edge exists in assemble.jl as
        # `bf.MAP ~ cv.MAP` and was declared nowhere, so the declared graph and
        # the built model disagreed. It is currently INERT: BodyFluids takes MAP
        # as an input and no equation there consumes it, so structural_simplify
        # removes it. It is the hook ADR 0010 needs for a volume-natriuresis /
        # ANP path. Declared rather than deleted so the two graphs match, and
        # recorded as Mechanical, which means the partition rule forbids cutting
        # across it - a precautionary constraint until something reads bf.MAP.
        Coupling(:cardiovascular, :bodyfluids, Mechanical,
                 note = "MAP to body fluids; INERT - no equation consumes bf.MAP " *
                        "yet. ADR 0010 ANP hook."),
    ]
end
