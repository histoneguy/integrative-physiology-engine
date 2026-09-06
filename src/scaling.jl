"""
Body-size scaling.

CONNECTED 2026-08-27, after running the ensemble for the first time showed a
population of six adults spanning 49 to 91 kg converging on ONE extracellular
volume, 14.55 L for all of them, to within 10 mL.

THE RULE, AND IT IS DIMENSIONAL RATHER THAN EMPIRICAL

  EXTENSIVE quantities - volumes, masses, flows, intakes - scale with body size.
  INTENSIVE quantities - pressures, concentrations, osmolalities, fractions,
  rates - do not.

A 90 kg adult has more extracellular fluid, filters more plasma per day, ejects
more blood per beat and eats more sodium than a 50 kg adult. Both have an
arterial pressure near 87 mmHg and a plasma sodium near 140 mEq/L. That is what
the two words mean here.

WHAT THIS CORRECTS, AND WHAT IT DELIBERATELY DOES NOT

The ensemble collapse had two halves and only ONE was a defect. `V_ecf` failing
to scale is wrong. `MAP` failing to scale is RIGHT - arterial pressure is
intensive, and a model that made big people hypertensive would be worse, not
better. So this scaling is designed to leave MAP invariant, and the test suite
asserts that it does.

TWO FACTORS SINCE 2026-09-05, NOT ONE

  `mass_factor`  m/m_ref            for FLUID COMPARTMENTS and their contents.
  `size_factor`  (m/m_ref)^k        for everything in the metabolic, renal and
                                    cardiac-output chain, with k = 0.5083 from
                                    BF.SIZE.EXPONENT.

The second is the correction this docstring used to record as debt against
itself. Body surface area grows sub-linearly with mass, so scaling glomerular
filtration and cardiac output linearly overstated their spread; at 95 kg the
factor falls from 1.357 to 1.168.

`size_factor` KEEPS ITS NAME AND CHANGES ITS MEANING, which is a thing to be
careful about rather than proud of: every existing call site meant "the extensive
scale", and most of them meant the surface-like one. The few that meant mass were
switched to `mass_factor` by hand and are named in the components. The guard is
the body-size testset's pressure-invariance assertion, which fails loudly if any
one of them is on the wrong factor.

k IS A POPULATION REGRESSION AND NOT A GEOMETRIC LAW. It is 0.51 where the
surface law gives 2/3, because in a real adult population mass varies more from
adiposity than from frame size and fat adds mass with little surface. That is the
right exponent for the question the ensemble asks - how does a heavier PERSON
differ - and the wrong one if body_mass is ever read as frame size.

WHY IT CLOSES CONSISTENTLY

Write `s` for the SURFACE factor and `m` for the MASS factor. Then in the steady
state:

  Na balance     Na_intake ~ s   and   Na_excr = GFR*C_Na*(1-FR) ~ s   because
                 GFR ~ s and C_Na is intensive. BOTH SIDES ARE SURFACE-LIKE, and
                 they have to be: give intake and clearance different exponents
                 and a big person is in permanent sodium surplus.
  FR_effective   G_pn*(MAP-MAP_ref)/Na_filtered is INVARIANT, because G_pn ~ s
                 and Na_filtered ~ s. So the reabsorbed fraction is intensive,
                 which is what makes the pressure-natriuresis loop size-free.
  ANP term       anp_sig/Na_filtered must also be invariant, and the argument
                 for it is the subtle one in this list. Its target is
                 G_anp*(V_blood - V_blood_ref). Both volumes are mass-like and
                 CANCEL at the operating point for any body size, so what the
                 gain multiplies is a DEVIATION - and the deviation a salt step
                 produces is sodium-driven and therefore SURFACE-like, matching
                 the Na_filtered underneath it. G_anp stays INTENSIVE.
                 Reasoning from the volumes instead of the deviation gives s/m,
                 which leaves every resting state exactly right and moves the
                 salt-step response by 8 percent at 85 kg. That mistake was made
                 here on 2026-09-05 and only the body-size testset saw it.
  Filling        SV = SV0*f(V_central/VC0). SV0 is surface-like and the RATIO is
                 invariant because V_central and VC0 are both mass-like, so the
                 Frank-Starling relation crosses the two factors without either
                 leaking into the pressure.
  Pressure       CO ~ s and TPR ~ 1/s, so MAP = CO*TPR is invariant. TPR must
                 carry the reciprocal: it is a resistance, and resistance falls
                 as the vascular bed gets bigger.
  Water          Osm_load ~ s and u_osm is intensive, so H2O_excr ~ s, matching
                 H2O_intake - H2O_insensible ~ s. Both halves of insensible loss
                 are surface-like, which for the CUTANEOUS half is not an
                 analogy - it is evaporation from a surface.
  ADH constants  U_max = solute/obligatory_volume and U_base = solute/(intake -
                 insensible) are RATIOS OF TWO SURFACE-LIKE QUANTITIES, so they
                 are invariant and every closure derived from them survives.

That last line is the reason this can be done at all without re-deriving the ADH
component: the derived urine osmolalities are ratios, and ratios of quantities
that scale the same way do not scale.

WHAT IS STILL WRONG, AND IT IS NOW THE WEAKER HALF. Volumes are linear in mass
because extracellular volume is entered as a mass FRACTION. Fat carries less
water than lean tissue, so the model overstates the fluid volumes of heavy people
exactly as it used to overstate their filtration. Fixing it needs a
body-composition row this model does not have.

THE DEBT THIS DOCSTRING USED TO RECORD IS DISCHARGED. It read: "Correcting that
needs height, which this model does not carry, and a BSA formula, which would
need its own extraction." Height is now BF.HEIGHT.REFERENCE, measured in 9300
NHANES adults; the formula is Du Bois; the exponent is BF.SIZE.EXPONENT,
regressed over those adults. See validation/body_size_scaling_extract.py.

NARROWING A SPREAD IS NOT THE SAME AS MAKING IT RIGHT. Nothing here compares the
model's population spread of glomerular filtration or cardiac output against a
measured spread, and the pre-registration forbade claiming otherwise.
"""

"""
    mass_factor(body_mass)

Dimensionless MASS factor, `body_mass / BF.BODY_MASS.REFERENCE`.

For fluid compartments and their contents, which this ledger enters as mass
fractions and as mL/kg and which are near-linear in body mass.

Returns exactly 1.0 at the reference mass.
"""
mass_factor(body_mass) = body_mass / LedgerParams.BF_BODY_MASS_REFERENCE

"""
    size_factor(body_mass)

Dimensionless SURFACE factor, `(body_mass / BF.BODY_MASS.REFERENCE)^k`, with
`k = BF.SIZE.EXPONENT`.

For everything in the metabolic, renal and cardiac-output chain - the quantities
conventionally indexed to body surface area.

RETURNS EXACTLY 1.0 AT THE REFERENCE MASS FOR ANY EXPONENT, which is why changing
k leaves every existing result bit-identical and moves only the population
spread. That property is what made this change safe in one pass, and branch S3 of
validation/body_size_scaling_prereg.md is the assertion of it.
"""
size_factor(body_mass) =
    (body_mass / LedgerParams.BF_BODY_MASS_REFERENCE) ^ LedgerParams.BF_SIZE_EXPONENT
