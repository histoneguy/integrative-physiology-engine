# Integrative Physiology Engine

> Rename this repository and this heading before first push.

An independent, high-performance implementation of whole-body integrative human physiology,
built from the peer-reviewed literature.

## What this is

A clean implementation in the Guyton–Coleman tradition of integrative physiological modeling,
written from published sources. The scientific lineage is acknowledged and cited. The
implementation is our own.

**Primary goal:** substantially faster execution than existing interpreted implementations,
without loss of physiological fidelity.

**This is not** a fork, port, translation, or modification of any existing model
distribution. See `SOURCES.md`.

## Provenance

Every parameter traces to a cited source recorded in `ledger/parameters.csv`. Every module
declares the literature its structure came from. The source whitelist in `SOURCES.md` is
binding on all contributors, and the git history of this repository is the project's
contemporaneous evidence of independent construction.

## Validation

Validated against published experimental and clinical data — never against another model's
outputs. See `validation/targets.md`.

## Layout

    SOURCES.md              Source whitelist policy (binding)
    CONTRIBUTING.md         Contributor rules
    docs/canon.md           Bibliography and design-rationale sources
    docs/exposure-declaration.md
    ledger/schema.md        Parameter ledger field definitions
    ledger/parameters.csv   The ledger
    validation/targets.md   Challenge protocols and validation datasets

## Licence

**TODO before first push.** Choose deliberately. If any commercial use is contemplated,
resolve licensing and any contractual exposure with counsel first. Note that a permissive
licence on our own code says nothing about obligations a contributor may have separately
accepted elsewhere.

## Citation

TODO — CITATION.cff once the first release is tagged.
