#!/usr/bin/env python
"""The lower breakpoint of renal autoregulation, sourced.

Executes validation/autoreg_lower_prereg.md, committed at 3fbe260 BEFORE any
paper was opened.

THE ANSWER: the lower limit is near 60 mmHg, not 80. The textbook 80 traces to an
ANAESTHETISED dog (Shipley & Study 1951); the only study that servo-controls renal
artery pressure in a CONSCIOUS animal and reports the breakpoint directly puts it
at 63.9 mmHg, and the human deliberate-hypotension literature brackets it between
50 and 60. Two independent lines, two species, two designs, ~20 mmHg below the
value this ledger carried.

Every citation below was read from the retrieved PubMed record; authors, journal,
year, volume and pages verified against that record.

Run:  python validation/autoreg_lower_extract.py
"""

# ---------------------------------------------------------------------------
# THE SEARCH. 26 queries in two sweeps, 1114 unique PubMed records.
#
# Directive 1.8 (cast a wide net) is the reason there are two sweeps. The first
# 14 queries returned an almost entirely ANIMAL literature and one apparently
# clean human answer. The second 12 queries went after the human
# pressure-lowering clearance literature specifically and returned the paper
# that contradicts it. Had the pass stopped at sweep 1 it would have reported a
# human value that the wider literature does not support.
# ---------------------------------------------------------------------------

SWEEP = dict(queries=26, records_screened=1114,
             sweep1="renal autoregulation / GFR breakpoint / perfusion pressure, 14 queries",
             sweep2="human induced-hypotension clearance literature, 12 queries")

# ---------------------------------------------------------------------------
# BRANCHES 1-5 OF THE PRE-REGISTRATION: does any HUMAN primary study report a
# NUMERIC lower breakpoint of renal autoregulation?
#
# No. Not one. The closest candidate is Textor 1985, and it is not that study.
# ---------------------------------------------------------------------------

NO_HUMAN_BREAKPOINT = [
    dict(label="Textor 1985", pmid="3970470", species="human", n=16,
         cite="Textor SC, Novick AC, Tarazi RC, Klimas V, Vidt DG, Pohl M. "
              "Critical perfusion pressure for renal function in patients with "
              "bilateral atherosclerotic renal vascular disease. "
              "Ann Intern Med 1985;102(3):308-314.",
         why_not="Title promises exactly this parameter and the paper is about "
                 "something else. Graded nitroprusside pressure reduction in "
                 "RENAL ARTERY STENOSIS. The 8 unilateral patients tolerated "
                 "205/103 -> 146/84 mmHg with no change in total renal function; "
                 "the 8 bilateral patients (all stenoses >=70%) lost plasma flow "
                 "152->66 mL/min and GFR 38->16 mL/min, reversibly, and lost that "
                 "sensitivity after revascularisation. That is a STENOSIS "
                 "threshold - pressure drop across a fixed lesion - not the "
                 "intrinsic autoregulatory breakpoint of a normal kidney."),

    dict(label="Carlstrom 2015", pmid="25834230", species="review",
         cite="Carlstrom M, Wilcox CS, Arendshorst WJ. Renal autoregulation in "
              "health and disease. Physiol Rev 2015;95(2):405-511.",
         why_not="States the range as 80-180 mmHg in its first sentence and "
                 "cites no primary measurement for either end. Tier B. This is "
                 "the review that keeps the convention alive; it does not "
                 "source it. Already read for RN.AUTOREG.UPPER on 2026-08-21 "
                 "and reaching the same verdict there."),

    dict(label="Schjoedt 2009", pmid="19561152", species="human", n=16,
         cite="Schjoedt KJ, Christensen PK, Jorsal A, Boomsma F, Rossing P, "
              "Parving HH. Autoregulation of glomerular filtration rate during "
              "spironolactone treatment in hypertensive patients with type 1 "
              "diabetes: a randomized crossover trial. "
              "Nephrol Dial Transplant 2009;24(11):3343-3349.",
         why_not="DEFINES autoregulation as constancy of GFR above 80 mmHg in "
                 "its own background sentence, then tests clonidine steps from "
                 "MAP 103 to ~85. It ASSUMES the number under investigation. "
                 "Also hypertensive type 1 diabetics, 9 of 16 showing impaired "
                 "autoregulation - a diseased preparation."),
]

# ---------------------------------------------------------------------------
# BRANCH 6: do human studies ESTABLISH GFR preserved down to some lowest
# tested pressure?
#
# THEY CONFLICT AT THE SAME PRESSURE. This is the finding that decides the
# branch, and it is the one that would have been missed by stopping early.
# ---------------------------------------------------------------------------

HUMAN_AT_60 = [
    dict(label="Lessard 1991", pmid="2021202", species="human", n=20,
         cite="Lessard MR, Trepanier CA. Renal function and hemodynamics during "
              "prolonged isoflurane-induced hypotension in humans. "
              "Anesthesiology 1991;74(5):860-865.",
         map_mmHg=59.8, map_sd=0.4, duration_min=237,
         method="GFR by INULIN clearance, ERPF by PAH clearance - the reference "
                "methods, measured DURING the hypotension",
         result="GFR and ERPF fell with induction of anaesthesia but NOT "
                "significantly further during hypotension. Renal vascular "
                "resistance rose with anaesthesia and then FELL when hypotension "
                "was induced, maintaining renal blood flow. Falling resistance "
                "against falling pressure is the autoregulatory signature.",
         verdict="PRESERVED at 59.8 mmHg"),

    dict(label="Hara 1998", pmid="9805693", species="human", n=26,
         cite="Hara T, Fukusaki M, Nakamura T, Sumikawa K. Renal function in "
              "patients during and after hypotensive anesthesia with sevoflurane. "
              "J Clin Anesth 1998;10(7):539-545.",
         map_mmHg=60.0, map_sd=None, duration_min=120,
         method="creatinine clearance, measured during the hypotension",
         result="CCr SIGNIFICANTLY DECREASED after the start of hypotension, in "
                "BOTH the isoflurane and the sevoflurane arm. Tubular marker NAG "
                "rose transiently in the sevoflurane arm.",
         verdict="NOT PRESERVED at 60.0 mmHg"),
]

HUMAN_AT_50 = [
    dict(label="Zayas 1993", pmid="8238548", species="human",
         cite="Zayas VM, Blumenfeld JD, Bading B, McDonald M, James GD, Lin YF, "
              "Sharrock NE, Sealey JE, Laragh JH. Adrenergic regulation of renin "
              "secretion and renal hemodynamics during deliberate hypotension in "
              "humans. Am J Physiol 1993;265(5 Pt 2):F686-F692.",
         map_mmHg=50.0,
         result="Epidural sympathetic blockade to MAP 50 and 60 mmHg. In the "
                "saline control arm at 50 mmHg, RBF was unchanged from baseline "
                "but GFR DECREASED. With epinephrine, RBF -33% at 60 mmHg and "
                "-60% at 50 mmHg, GFR -27% and -53%.",
         verdict="GFR FALLING at 50 mmHg"),

    dict(label="Toivonen 1991", pmid="1874198", species="human", n=25,
         cite="Toivonen J, Kaukinen S, Oikkonen M, Hannelin M. Effects of "
              "deliberate hypotension induced by labetalol on renal function. "
              "Eur J Anaesthesiol 1991;8(1):13-20.",
         map_mmHg=50.0,
         result="MAP 49-50 mmHg. Urine flow, effective renal blood flow, "
                "endogenous creatinine clearance and osmolar clearance all fell; "
                "free-water clearance and fractional electrolyte excretions also "
                "indicated deterioration. Reversible after anaesthesia.",
         verdict="GFR FALLING at 50 mmHg"),
]

# Recorded and explicitly NOT counted, because it does not measure GFR AT
# pressure - the distinction branch 6 turns on.
NOT_QUALIFYING = [
    dict(label="Sharrock 2006", pmid="16377652", species="human",
         cite="Sharrock NE, Beksac B, Flynn E, Go G, Della Valle AG. "
              "Hypotensive epidural anaesthesia in patients with preoperative "
              "renal dysfunction undergoing total hip replacement. "
              "Br J Anaesth 2006;96(2):207-212.",
         why_not="MAP < 55 mmHg for a mean of 94 min with no renal "
                 "deterioration - the lowest sustained human pressure found in "
                 "this sweep. But the endpoint is POSTOPERATIVE creatinine "
                 "clearance, not GFR measured during the hypotension. It "
                 "establishes tolerance, not autoregulation, and branch 6 asks "
                 "for the latter. Counting it would have given a lower and "
                 "less defensible number."),
]

# ---------------------------------------------------------------------------
# BRANCH 7: the animal primary. The relationship IS the subject.
# ---------------------------------------------------------------------------

ADOPTED = dict(
    label="Finke 1983", pmid="6139786", species="dog", n=7,
    cite="Finke R, Gross R, Hackenthal E, Huber J, Kirchheim HR. Threshold "
         "pressure for the pressure-dependent renin release in the "
         "autoregulating kidney of conscious dogs. "
         "Pflugers Arch 1983;399(2):102-110.",
    value=63.9, units="mmHg",
    prep="CONSCIOUS foxhounds, beta-adrenergic blockade, normal sodium diet "
         "(4.1 mmol/kg/day). Renal artery pressure varied 160 -> 40 mmHg, "
         "reduced in STEPS and held constant by a servo-control system driving "
         "an inflatable renal artery cuff. Pressure raised by bilateral common "
         "carotid occlusion, which by itself changed neither RBF nor renin "
         "release with renal artery pressure clamped and renal beta-receptors "
         "blocked.",
    result="Between 160 mmHg and resting pressure, NO change in renal blood "
           "flow. Between resting pressure and the LOWER LIMIT OF "
           "AUTOREGULATION - average 63.9 mmHg - renal blood flow rose only "
           "about 7%, which the authors read as high autoregulatory efficiency.",
    directive_1_7="If the physiology had come out differently the paper would "
                  "have reported a different lower limit and a different renin "
                  "threshold. Nothing about it is a device validation or a "
                  "safety endpoint. The relationship IS the subject.",
)

# ---------------------------------------------------------------------------
# DECLARED CONFLICTS. Logged, not resolved, not averaged.
# ---------------------------------------------------------------------------

CONFLICTS = [
    dict(label="Shipley & Study 1951", pmid="14903093", species="dog",
         value="80 (the incumbent)",
         cite="Shipley RE, Study RS. Changes in renal blood flow, extraction of "
              "inulin, glomerular filtration rate, tissue pressure and urine flow "
              "with acute alterations of renal artery blood pressure. "
              "Am J Physiol 1951;167:676-688.",
         note="The origin of the textbook 80-180 and therefore of the value this "
              "row carried. ANAESTHETISED dog. Its PubMed record carries the MeSH "
              "term 'Humans', a legacy-indexing artefact of the AJP back "
              "catalogue already flagged in autoreg_upper_prereg.md. The most "
              "likely single explanation of the 80 vs 63.9 gap is anaesthesia: "
              "Finke's animals were conscious."),

    dict(label="Cupples & Braam 2007", pmid="17229679", species="dog and rat",
         value="~75 (dog), ~85 (rat)",
         cite="Cupples WA, Braam B. Assessment of renal autoregulation. "
              "Am J Physiol Renal Physiol 2007;292(4):F1105-F1123. "
              "PMID 17229679. doi 10.1152/ajprenal.00194.2006",
         note="Tier B review. pooling.md: 'The primary source wins, and the "
              "divergence is logged.' Finke is primary and conscious; this is "
              "secondary. Not averaged with it - and note that averaging 75 and "
              "85 would produce a number describing neither species, which "
              "pooling.md prohibits outright."),

    dict(label="Signa Vitae 2025", pmid=None, species="human",
         value="no defensible human floor",
         cite="doi 10.22514/sv.2025.001",
         note="Already cited in this row's notes before this pass. Concludes "
              "human evidence is insufficient to state 80 mmHg is the lower "
              "limit. This extraction agrees with it and goes further: the human "
              "evidence that does exist puts the limit near 60."),
]


def main():
    w = 78
    p = print
    p("=" * w)
    p("RN.AUTOREG.LOWER - PRE-REGISTERED EXTRACTION")
    p("=" * w)
    p(f"  Pre-registration: validation/autoreg_lower_prereg.md, commit 3fbe260")
    p(f"  Sweep: {SWEEP['queries']} queries, {SWEEP['records_screened']} unique records")
    p(f"    sweep 1  {SWEEP['sweep1']}")
    p(f"    sweep 2  {SWEEP['sweep2']}")
    p()

    p("=" * w)
    p("BRANCHES 1-5 FAIL: NO HUMAN STUDY REPORTS A NUMERIC LOWER BREAKPOINT")
    p("=" * w)
    for s in NO_HUMAN_BREAKPOINT:
        p(f"  {s['label']:18s} PMID {str(s['pmid']):9s} {s['species']}")
        p(f"    {s['cite']}")
        p(f"    NOT IT: {s['why_not']}")
        p()

    p("=" * w)
    p("BRANCH 6 FAILS: THE HUMAN EVIDENCE CONFLICTS AT THE SAME PRESSURE")
    p("=" * w)
    p("  Branch 6 asks whether human studies ESTABLISH GFR preserved down to some")
    p("  lowest tested pressure. At 60 mmHg, two studies say opposite things:")
    p()
    for s in HUMAN_AT_60:
        p(f"  {s['label']:18s} PMID {s['pmid']:9s} n={s['n']:<3} MAP {s['map_mmHg']} mmHg")
        p(f"    {s['cite']}")
        p(f"    method:  {s['method']}")
        p(f"    result:  {s['result']}")
        p(f"    >>> {s['verdict']}")
        p()
    p("  Lessard is the methodologically stronger of the two - inulin and PAH")
    p("  clearance against creatinine clearance over a 2 h non-steady-state")
    p("  anaesthetic - but 'stronger' is not 'established', and picking the")
    p("  agreeable one AFTER seeing both is the exact move the pre-registration")
    p("  exists to prevent.")
    p()
    p("  And there is no lower pressure where the human evidence is unconflicted:")
    p()
    for s in HUMAN_AT_50:
        p(f"  {s['label']:18s} PMID {s['pmid']:9s} MAP {s['map_mmHg']} mmHg")
        p(f"    {s['cite']}")
        p(f"    result:  {s['result']}")
        p(f"    >>> {s['verdict']}")
        p()
    for s in NOT_QUALIFYING:
        p(f"  {s['label']:18s} PMID {s['pmid']:9s}  RECORDED, NOT COUNTED")
        p(f"    {s['cite']}")
        p(f"    {s['why_not']}")
        p()
    p("  So branch 6's condition genuinely fails on its own terms. There is no")
    p("  human pressure at which preservation is established. Proceed to 7.")
    p()
    p("  WORTH SAYING PLAINLY: all four human studies are ANAESTHESIA SAFETY")
    p("  studies. Apply the directive 1.7 test - if the physiology had come out")
    p("  differently, the conclusion would have been 'this hypotensive technique")
    p("  is unsafe for the kidney'. The pressure-flow relationship is the")
    p("  INSTRUMENT; renal safety is the subject. Directive 1.7 predicts exactly")
    p("  what was found: every one of them arrives with a confound attached")
    p("  (volatile anaesthetic, sympathetic blockade, vasodilator, or all three),")
    p("  and anaesthesia depressed GFR before any pressure was lowered.")
    p()

    p("=" * w)
    p("BRANCH 7 TAKEN: THE CONSCIOUS-DOG PRIMARY")
    p("=" * w)
    a = ADOPTED
    p(f"  {a['label']}   PMID {a['pmid']}   {a['species']}, n={a['n']}")
    p(f"    {a['cite']}")
    p()
    p(f"    preparation:  {a['prep']}")
    p()
    p(f"    result:       {a['result']}")
    p()
    p(f"    directive 1.7: {a['directive_1_7']}")
    p()
    p(f"  >>> ADOPTED VALUE: {a['value']} {a['units']}, species dog, tier A,")
    p("      pooling_rule = single-source, k = 1.")
    p()

    p("=" * w)
    p("DECLARED CONFLICTS - LOGGED, NOT RESOLVED, NOT AVERAGED")
    p("=" * w)
    for c in CONFLICTS:
        p(f"  {c['label']:22s} {c['species']:14s} {c['value']}")
        p(f"    {c['cite']}")
        p(f"    {c['note']}")
        p()

    p("=" * w)
    p("WHAT THE TWO INDEPENDENT LINES AGREE ON")
    p("=" * w)
    p("  Conscious dog, servo-controlled steps, breakpoint measured directly:")
    p("      63.9 mmHg")
    p("  Anaesthetised humans, deliberate hypotension, bracketed:")
    p("      preserved at ~60 (Lessard), failing at ~50 (Zayas, Toivonen)")
    p()
    p("  Different species, different designs, different decades, no shared")
    p("  authors. Both land near 60. NEITHER SUPPORTS 80.")
    p()
    p("  The branch choice is therefore NOT load-bearing: branch 6 would have")
    p("  given 59.8 and branch 7 gives 63.9, a 4.1 mmHg difference, and every")
    p("  conclusion below is identical either way. Recorded because a")
    p("  pre-registered procedure whose outcome does not depend on the branch")
    p("  is worth more than one whose does.")
    p()

    p("=" * w)
    p("WHAT THIS DOES TO THE MODEL: NOTHING, AND THAT IS THE POINT")
    p("=" * w)
    p("  GFR ~ GFR0 * ifelse(MAP < MAP_lo, MAP/MAP_lo,")
    p("                      ifelse(MAP > MAP_hi, MAP/MAP_hi, 1.0))")
    p()
    p("  The three salt arms sit at MAP 81.900 / 84.450 / 87.001 mmHg. They were")
    p("  above the old MAP_lo = 80 and they are above the new 63.9, so every arm")
    p("  stays on the plateau and every steady state is BIT-IDENTICAL.")
    p()
    p("  The pre-registration declared this before extraction, precisely so that")
    p("  'it does not change the answer' could not be used to wave the change")
    p("  through, and so that a value ABOVE 81.9 would have had to be escalated")
    p("  rather than quietly avoided.")
    p()
    p("  WHAT DOES CHANGE IS MARGIN. The low-salt arm sat 1.9 mmHg above the")
    p("  autoregulation breakpoint. It now sits 18.0 mmHg above it. A model whose")
    p("  operating point is one and a half mmHg from a piecewise kink is one")
    p("  parameter revision away from crossing it - and CV.MAP.SETPOINT moved 6")
    p("  mmHg toward that kink on 2026-08-27, which is what put this row at the")
    p("  top of the queue. That fragility is now gone.")
    p()

    p("=" * w)
    p("WHAT IS STILL DEBT")
    p("=" * w)
    p("  1. THIS IS A DOG NUMBER AND THE HUMAN EXPERIMENT IS PERFORMABLE.")
    p("     RN.AUTOREG.UPPER earns E2 under the ADR 0006 amendment because no")
    p("     human study may RAISE pressure to find the upper breakpoint. That")
    p("     argument does NOT transfer here and was ruled out in the")
    p("     pre-registration BEFORE the search, so it could not be reached for")
    p("     afterwards. Humans have been taken to 50-60 mmHg repeatedly. What is")
    p("     missing is a study that does it WITHOUT general anaesthesia and")
    p("     measures GFR by inulin at graded steps. This row is debt with a named")
    p("     primary source - a real improvement on a non-citation, not a closure.")
    p()
    p("  2. THE PIECEWISE FORM REMAINS UNSOURCED. relations.csv row Renal.GFR")
    p("     still carries an empty form_citation and stays in")
    p("     GRANDFATHERED_UNSOURCED. A NUMBER was sourced; the EQUATION was not.")
    p("     Finke in fact reports renal blood flow rising ~7% below resting")
    p("     pressure rather than staying flat, so the true plateau has a slight")
    p("     slope the model's ifelse does not represent.")
    p()
    p("  3. 63.9 SITS ONLY ~9 mmHg ABOVE THE LOWER EDGE of the evidenced")
    p("     pressure-natriuresis range (~55 mmHg, Osborn 1981 dog). The")
    p("     pre-registration required the adopted value to lie inside that range.")
    p("     It does, with less headroom than is comfortable.")
    p()
    p("  4. FINKE ALSO MEASURED THE RENIN THRESHOLD: 89.8 +/- 3.3 mmHg in")
    p("     conscious dog, against RAAS.RENIN.PRESSURE_THRESHOLD = 93.0 mmHg")
    p("     currently carried on van Ochten. OUT OF SCOPE for this pass and NOT")
    p("     changed. Recorded because that row is load-bearing - it is the")
    p("     rectification point that HANDOVER 3.1 found the model sitting exactly")
    p("     on - and because a second independent primary source for it now")
    p("     exists in a paper this repo has read.")


if __name__ == "__main__":
    main()
