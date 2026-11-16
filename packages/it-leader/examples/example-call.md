# How the author calls it

The author runs a personal assistant called Jarvis on top of Claude Code. The lead agent writes a
problem analysis, then asks the reviewer for a second viewpoint before the analysis is accepted.
Adapt the wording to your own setup.

## Example call (placeholders)

> Review the analysis in `<project-root>/docs/analysis/<topic>/problem-report.md` as the IT leader.
> Scope: the first phase of stabilising how work flows through <team or system>. Supporting material:
> `<project-root>/docs/analysis/<topic>/signals.md` and `inventory.md`. Do not follow my conclusions in
> the report; mark where you disagree. Return the fixed five-part verdict.

## What comes back

A five-part text verdict: bottlenecks found in the analysis with evidence and a status, bottlenecks the
analysis misses, disagreements with the caller's framing, open questions for the owner, and judgements
that lean on unconfirmed claims. No solutions.

## How the caller uses it

- The verdict is one source with blind spots of its own. The caller weighs it against the intent of the
  work instead of copying it.
- Part 4 (open questions) goes to the owner by the caller; the reviewer never contacts the owner.
- Run it one-shot: the review comes back as a final report, which is more reliable than a long
  back-and-forth with the reviewer.
