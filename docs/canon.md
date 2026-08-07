# Source Canon

## Design rationale (Tier C - architecture and reasoning only)

- Guyton AC, Coleman TG, Granger HJ. Circulation: overall regulation.
  *Annu Rev Physiol* 1972;34:13-46.
  The systems-analysis formulation of cardiovascular-renal integration; ~150 variables.
  Source of the renal-body fluid feedback architecture.

- Coleman TG, Randall JE. HUMAN: a comprehensive physiological model.
  *The Physiologist* 1983;26:15-21.
  Extension beyond circulation; distributed as Fortran source at the time.

- Abram SR, Hodnett BL, Summers RL, Coleman TG, Hester RL. Quantitative circulatory
  physiology: an integrative mathematical model of human physiology for medical education.
  *Adv Physiol Educ* 2007;31:202-210.

- Hester RL, Brown AJ, Husband L, Iliescu R, Pruett D, Summers R, Coleman TG. HumMod: a
  modeling environment for the simulation of integrative human physiology.
  *Front Physiol* 2011;2:12. doi:10.3389/fphys.2011.00012
  Describes the modeling environment: block-structured calculation grouping, algebraic and
  differential equation elements, curve functions specified as (X, Y, slope) triples, and
  XML-based physiology description. ~5000 variables across cardiovascular, respiratory,
  renal, neural, endocrine, skeletal muscle, and metabolic systems.

- Hester RL, Iliescu R, Summers R, Coleman TG. Systems biology and integrative physiological
  modelling. *J Physiol* 2011;589(5):1053-1060.

## Related open implementations (evaluate licensing before any use)

- Physiomodel / HumMod-Golem Edition - Modelica reimplementations from the Kofranek group.
  Matejak M, Kofranek J. Physiomodel: an integrative physiology in Modelica.
  *EMBC* 2015:1464-1467.
- Physiome Model Repository (CellML), BioModels, Open Systems Pharmacology suite.

Reviewing these is a **build-versus-adopt** question, not a source question. If any is
adopted under licence, that is a deliberate decision recorded here, and this project's
independence claim is scoped accordingly.

## Reference data (Tier A)

- ICRP Publication 89: Basic anatomical and physiological data for use in radiological
  protection - reference values.
- NHANES anthropometric and clinical reference data.

## Subsystem primary literature

Maintained per subsystem as implementation proceeds. Each module's header block lists the
sources its structure came from.
