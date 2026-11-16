# Knowledge file for the it-leader agent

Everything below is a paraphrase in the author's own words of widely discussed ideas from two books
and from Theory of Constraints. No passages are copied. Status labels:

- CONFIRMED: checked by the author against a publisher excerpt, a publisher timeline or at least two
  independent summaries.
- UNCONFIRMED: taken from a single summary, general knowledge or earlier notes, not checked against a
  source. A judgement that rests on it must say so.
- (derived): the author's own reading, not a claim about the books.

Books (not affiliated with this package): *The Phoenix Project* (Gene Kim, Kevin Behr, George Spafford)
and *The Unicorn Project* (Gene Kim).

## 1. The constraint (Theory of Constraints) - CONFIRMED

Every system has a limiting step that sets the pace of the whole. In the first book this is an
overloaded expert through whom a large share of the important work has to pass. Five steps:
identify the constraint; get the most out of it; subordinate everything else to that decision; raise
its capacity; when it is lifted, go back to step 1 because a new constraint appears.
Applied to a person: keep them off work others can do, make their queue visible, move knowledge out of
their head into procedures and other people, and automate the repeating part. After one constraint is
removed the next one shows up; in the second book deployment and later product management become the
next constraints.

## 2. The four types of work - CONFIRMED

1. Business projects (work for the customer-facing side).
2. Internal projects (work on the infrastructure and tooling itself).
3. Changes (fixes, version updates and improvements that follow from the first two).
4. Unplanned work (incidents and recovery). The most damaging type: it interrupts and displaces the
   three planned types.
Typical review questions: which type is each piece of work, which type is not counted at all, and how
much capacity does unplanned work quietly eat?

## 3. Work in progress and wait time - CONFIRMED

Too many parallel projects mean everything is half done. A wait-time view (how long a task waits versus
how long it is worked on) shows that a small task can take weeks because it waits for the constraint.
A visible board with a limit on work in progress makes queues and invisible work visible.

## 4. The change process - CONFIRMED (core), UNCONFIRMED (freeze)

- A change board can exist on paper and still be dead: nobody uses the tool, the form is too heavy,
  approval is slow, so everybody labels everything an emergency.
- Agree on what counts as a change: in short, anything done to the systems behind a service that could
  affect that service. Reaching this shared definition takes real discussion.
- Visible change cards: one change per card, who plans it, which system, one sentence of what.
  Approved cards sit on a shared calendar.
- Triage by risk (roughly 80/20: a small share of the changes carries most of the risk): fragile,
  critical systems always go through the board; routine changes that usually go well are approved in
  advance (still reported); the middle group is the submitter's responsibility to coordinate.
- A regular weekly board rhythm; manual handling is acknowledged as not sustainable and meant to be
  automated later.
- A temporary freeze on new feature work to stabilise (UNCONFIRMED: only its existence and order are
  known, not its content).

## 5. The Three Ways - CONFIRMED

1. Flow: work moves from left to right (development to operations to customer), made visible and kept
   in small batches.
2. Feedback: information moves from right to left, quickly, so problems are caught near where they
   arise.
3. Continual learning and experimentation: a culture of repeated practice, improvement and learning
   from failure.

## 6. The Five Ideals (second book)

| Ideal | Core | Status |
|---|---|---|
| 1. Locality and Simplicity | A team can do most of its work without waiting for many other groups; coupling and dependencies are the bottleneck | CONFIRMED |
| 2. Focus, Flow and Joy | Small batches and fast feedback; a slow build-and-deploy loop destroys focus | CONFIRMED (names), UNCONFIRMED (any specific time threshold) |
| 3. Improvement of Daily Work | Improving the work counts more than doing the work; pay down technical debt | CONFIRMED (technical debt), UNCONFIRMED (stop-the-line image) |
| 4. Psychological Safety | Problems can be reported without fear of punishment | CONFIRMED (the idea), UNCONFIRMED (the claimed chain from prevention to honesty to fear) |
| 5. Customer Focus | Test whether work matters to the customer; would the customer pay for it | UNCONFIRMED |

## 7. Reading the first phase (derived)

The first phase of the first book is not one "change management" step but a sequence: make the work
visible (wait-time view, board, work types), protect the constraint (log everything, no small side
fixes), limit work (fewer projects, a freeze), stabilise and measure (monitoring, practice drills), and
introduce a rhythm (a regular change board that is adjusted after each round). A complete bottleneck
review therefore covers: what is the work (four types), who or what is the constraint, where is the wait
time, what unplanned work exists, which limits on work in progress exist, which changes bypass the
process.

## 8. What this file does not contain

No lists of questions that the books themselves pose; the review questions above are the author's own
derivation. Details of individual scenes beyond what is stated here are not covered.
