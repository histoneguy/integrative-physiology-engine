# Incoming patches

Drop generated `.patch` files here, then:

    python sprint.py

sprint.py shows you the diff, waits for explicit confirmation, applies with
`git am --signoff`, runs the ledger check and tests, and pushes a PR branch.
Nothing is applied before you confirm; nothing is pushed if verification fails.

## Why signoff rather than direct commit

Authorship stays with whoever generated the patch; your `Signed-off-by` is added on
top. Git distinguishes who wrote a change from who takes responsibility for it, and
this project's central claim is documented provenance - generated commits should
remain visibly generated.

This is the standard DCO mechanism and reads correctly to anyone auditing the history
later.

## If a patch will not apply

It was generated against a different base. Either check out that base, or ask for the
series to be regenerated against current `main`. Do not force it with `git apply -3`
unless you intend to review the merge resolution as carefully as the patch itself.
