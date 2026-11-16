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

## 8. Example patterns (own words)

These patterns are general situations written in our own words; they are not scenes from the books.

- **One overloaded expert** - *Situation:* a large share of the important work passes through one person who also fixes things on the side; a small change waits weeks for their attention. *What it signals:* a person as the constraint. *Concept:* section 1. *Review question:* what share of the work needs this person, and what could others do instead?
- **Wait time hidden behind short work time** - *Situation:* a task takes minutes to do but weeks to finish, because it queues for a scarce resource; the clock only shows the working time. *What it signals:* queue time at the constraint is invisible. *Concept:* section 3. *Review question:* for a typical small task, how long is it worked on versus how long does it wait, and where?
- **A change process that exists on paper but is bypassed** - *Situation:* the form is so heavy and approval so slow that everyone marks every change as an emergency. *What it signals:* a dead control that gives false comfort. *Concept:* section 4. *Review question:* which changes actually go through the process, and which route around it?
- **No shared definition of a change** - *Situation:* teams disagree about what needs approval; some count only big releases, others count every configuration edit. *What it signals:* invisible work and uneven risk handling. *Concept:* section 4. *Review question:* is there one written definition that everyone applies the same way?
- **Triage by risk in three classes** - *Situation:* all changes are treated alike, so either everything is blocked or nothing is checked. A better split is: fragile, critical systems always reviewed; routine changes that usually go well pre-approved but still reported; the middle group coordinated by the submitter. *What it signals:* review effort not matched to risk. *Concept:* section 4. *Review question:* which systems are fragile enough to always need review, and which changes are routine enough to pre-approve?
- **An amnesty period before enforcement** - *Situation:* a new rule is introduced; for a first period changes are only counted and made visible, and only afterwards is the rule enforced. *What it signals:* a way to introduce control without freezing delivery. *Concept:* section 4. *Review question:* is the rule enforced before people know what counts, or after the volume is understood?
- **A weekly rhythm, adjusted after each round** - *Situation:* a short, recurring review of upcoming changes at a fixed time, whose rules are tuned after each round; the first version is manual and everyone admits it will not scale. *What it signals:* control through cadence rather than through one-off approvals. *Concept:* section 4. *Review question:* is there a fixed rhythm, and is manual handling planned to be automated?
- **A freeze to stabilise** - *Situation:* new feature work stops for a short, explicit period so the backlog of unplanned work can be cleared and the base becomes stable. *What it signals:* the organisation was creating work faster than it could finish it. *Concept:* sections 3 and 4 (the content of the freeze is UNCONFIRMED). *Review question:* what is the stop condition, and who may bypass the freeze?
- **Unplanned work crowds out planned work** - *Situation:* every week incidents and recoveries displace projects, so projects slip and more fixes become urgent. *What it signals:* a vicious circle in which the fourth type of work starves the other three. *Concept:* section 2. *Review question:* how much capacity does unplanned work take, and is it counted at all?
- **Too many projects in parallel** - *Situation:* everything is started, nothing is finished, and each project waits for the same few people. *What it signals:* missing limit on work in progress. *Concept:* section 3. *Review question:* what is the limit on work in progress, and who enforces it?
- **Make the constraint person log everything and stop small fixes** - *Situation:* the overloaded expert is asked to record all work in the shared queue and to stop doing small side fixes outside it. *What it signals:* protecting the constraint by making its demand visible and removing work others can do. *Concept:* section 1. *Review question:* what does this person do that someone else could do, and is all of it in the queue?
- **Getting knowledge out of one head** - *Situation:* the expert's know-how is turned into procedures, shared with others and the repeating part is automated, so their capacity grows without more hours. *What it signals:* raising the capacity of the constraint. *Concept:* section 1. *Review question:* which tasks exist only in one person's memory, and which repeat often enough to automate?
- **Monitoring and drills** - *Situation:* after the work is visible, the team adds monitoring so problems are noticed before users report them, and runs regular practice drills for failures. *What it signals:* stabilising and learning from failure. *Concept:* sections 5 and 7. *Review question:* how are problems detected today, and when was a failure last practised?
- **The constraint moves** - *Situation:* after one bottleneck is lifted, the next one appears elsewhere (for example deployment, and then deciding what to build). *What it signals:* the work is not done after one fix. *Concept:* section 1. *Review question:* if this bottleneck disappeared tomorrow, where would the work pile up next?
- **A team that waits on many other groups** - *Situation:* shipping a small change needs scheduling and sign-off from many other teams at once. *What it signals:* coupling and dependencies as the bottleneck. *Concept:* section 6, ideal 1. *Review question:* what share of this team's work can it finish without anyone outside the team?
- **Slow build and feedback loop** - *Situation:* a build and deploy cycle is so slow that developers batch up work and find problems late. *What it signals:* large batches and delayed feedback. *Concept:* sections 5 and 6, ideal 2. *Review question:* how long from change to feedback, and what makes people batch?

## 9. What this file does not contain

No lists of questions that the books themselves pose; the review questions above are the author's own
derivation. Details of individual scenes beyond what is stated here are not covered.
