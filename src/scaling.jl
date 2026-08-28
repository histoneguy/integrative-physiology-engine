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

WHY IT CLOSES CONSISTENTLY

Write `s` for the size factor. Then in the steady state:

  Na balance     Na_intake ~ s   and   Na_excr = GFR*C_Na*(1-FR) ~ s   because
                 GFR ~ s and C_Na is intensive.
  FR_effective   G_pn*(MAP-MAP_ref)/Na_filtered is INVARIANT, because G_pn ~ s
                 and Na_filtered ~ s. So the reabsorbed fraction is intensive,
                 which is what makes the pressure-natriuresis loop size-free.
  Pressure       CO ~ s and TPR ~ 1/s, so MAP = CO*TPR is invariant. TPR must
                 carry the reciprocal: it is a resistance, and resistance falls
                 as the vascular bed gets bigger.
  Water          Osm_load ~ s and u_osm is intensive, so H2O_excr ~ s, matching
                 H2O_intake - H2O_insensible ~ s.
  ADH constants  U_max = solute/obligatory_volume and U_base = solute/(intake -
                 insensible) are RATIOS OF TWO EXTENSIVE QUANTITIES, so they are
                 invariant and every closure derived from them survives untouched.

That last line is the reason this can be done at all without re-deriving the ADH
component: the derived urine osmolalities are ratios, and ratios of extensive
quantities do not scale.

SCALING IS LINEAR IN MASS, AND THAT IS AN APPROXIMATION WITH A KNOWN DIRECTION.
Extracellular volume and blood volume genuinely are near-linear in body mass -
they are already entered in this ledger as mass fractions and as mL/kg. GFR and
cardiac output are conventionally normalised to BODY SURFACE AREA, which grows
sub-linearly with mass, so linear scaling OVERSTATES their spread across a
population. Correcting that needs height, which this model does not carry, and a
BSA formula, which would need its own extraction. Recorded as debt rather than
approximated with an unsourced exponent.
"""

"""
    size_factor(body_mass)

Dimensionless body-size factor, `body_mass / BF.BODY_MASS.REFERENCE`.

Returns exactly 1.0 at the reference mass, so every existing result is unchanged
by construction and the default model is bit-identical to the pre-scaling one.
"""
size_factor(body_mass) = body_mass / LedgerParams.BF_BODY_MASS_REFERENCE
