---
name: decision-table
description: "Fixed format for putting decisions to the owner: one table with, per decision, the question, the purpose, a plain explanation and a concrete advice, fully self-contained (no bare ticket references, no reliance on the owner's memory). Use when one or more decisions or choices wait for the owner, when a summary contains open points the owner must judge, when the owner asks for context on a choice, or when the owner invokes the skill. Keywords: decision, decisions, put a decision, approval needed, open questions, which option, what should I decide, decision for the owner, context for a choice, decision table."
version: "1.0"
---

# Decision table

## Why this skill exists

Decisions used to be presented as bare lines: "agree on hook X?", "ticket 50 v1 set?". The owner multitasks, does not always read the text between tool calls, and does not carry ticket numbers or abbreviations in their head. Twice per session they had to ask for context.

Every decision put to the owner must be decidable on its own: everything needed to choose is next to the question. A bare line forces the owner to go back and look things up. Repeating context is cheap. Reconstructing it is expensive, and the owner pays for it.

## The format: a mandatory table plus advice

For every decision you put to the owner (at the end of an answer, or bundled on request):

| # | Question | Purpose (why this decision exists) | Explanation (what is going on, in plain words) | Advice |
|---|---|---|---|---|

**Per column:**

- **Question.** The decision as a concrete yes/no or choice question, with its object ("May I put hook X in the settings file?", not "agree on hook?").
- **Purpose.** What the decision delivers or prevents, the why in one sentence.
- **Explanation.** The history, plus what happens on yes and on no. Understandable without having followed the session. Ticket references always as `number + title + role in this decision`. Spell out abbreviations at first use. No analogies, plain language.
- **Advice.** Your recommendation and the reason in half a sentence, so that one word ("route B", "close it") is enough as an answer.

## Rules

1. **Self-contained is hard.** If the owner reads only the table and nothing before it, they can decide.
2. **One row per decision.** No combined questions. For a choice between two or more options, do not cram the options into the Explanation cell. The Explanation holds only origin and what is going on. The options go in a separate options table directly under the decision table, with columns `Option | What it is | Pro | Con`, and the Advice refers to the option letter.
3. **Do not merge columns, no bare references.** A clogged combined cell is unreadable. Every ticket reference in every cell is number + title + one sentence of content. A bare "covers ticket 128" is noise the owner cannot judge. The Advice column names the concrete action ("close", "set the field", "route B"), never "agree", which only mirrors the question.
4. **Show data, not only a description.** A ticket number is an empty label to the owner, even with a title. Make the underlying data visible before they judge: the measurement, the concrete list, the report excerpt. If the data does not fit compactly in the table, put it on a separate page (rule 12) and let the row point to it.
5. **Order by urgency, blocking first.** Mark which rows block other rows.
6. **Origin per row.** Name the chain in the Explanation: ticket, parent, epic, each with title and purpose, plus what triggered the decision. Without the chain the owner does not recognise what it is about, and an already handled topic looks like a new request.
7. **One decision moment.** Present only when all data is in. If subagent reports or checks that touch the same decisions are still running, do not send a partial table. Say "decision follows when X is in". Presenting in pieces forces re-posting in changing shapes and destroys the owner's overview.
8. **Never re-post, number stably.** A table that was sent is not sent again or renumbered. New decisions get follow-up numbers. Refer to open ones as "decision #N is still open". An answered topic returns only with a genuinely new fact, with a reference to the earlier answer.
9. **Purpose and chain in plain words, jargon defined.** Per row, the problem the ticket solves (not only its name) and the chain upward. Every term outside the owner's own vocabulary gets a definition in brackets at first use. Test: a cold reader without tools must be able to say from the table alone what it is about. In the author's own use, two of four rows once failed this test.
10. **No hidden question in the Advice.** If the advice depends on information only the owner has (calendar room, planning, preference), that is a separate row. The decision itself must be answerable in one word.
11. **Absolute dates.** Not "last time" or "earlier this week". Write "on 23 August ..." or name the event itself.
12. **Large decisions go on a page.** When the explanation needs more than about 1500 characters, keep the row compact and offer the detail as a separate page (see the cockpit package in this catalog, or any page your agent can publish). The row points to it.
13. **A drawing for routes between three or more parties.** If a decision concerns a direction or route between three or more parties (machines, zones, people), add a drawing. Without one, the owner once read the direction of a design exactly backwards. Text is skipped when the owner is overloaded, a picture is not.
14. **After the owner answers:** write the decision and the reason as a comment on the ticket in your tracker. Do not leave it only in the chat.

## A small filled example

Fictional, generic. Decision table:

| # | Question | Purpose | Explanation | Advice |
|---|---|---|---|---|
| 1 | May I disable the old firewall rule "guest-to-printer" today? | Remove an open path that nobody uses, before the quarterly audit. | Origin: ticket 42 "Retire legacy guest-network rules", part of the epic "Tighten the guest network", which exists because the audit flagged unused allow rules. The rule allows guests to reach the printer VLAN (the separate network segment for printers). Over the last 30 days the rule's hit counter shows 0 connections (data below). On yes: the rule is disabled, not deleted, and stays restorable. On no: the finding stays open in the audit. | Disable it today, keep it for 30 days, then delete. |
| 2 | Which log retention do you want for the firewall? | Decide how long logs are kept; it fixes the disk budget. | Origin: ticket 57 "Firewall log disk fills up", child of the epic "Stable log pipeline". Logs currently use 80% of the disk after 45 days. The options are in the table below. | Option B, because it fits the disk with margin. |

Data for #1: hit counter 0 over the last 30 days, last hit 2026-09-30.

Options for #2:

| Option | What it is | Pro | Con |
|---|---|---|---|
| A | Keep 45 days, add a second disk | Nothing is lost | Costs a disk and a change |
| B | Keep 30 days | Fits the current disk | Older incidents cannot be reconstructed |
| C | Keep 90 days compressed | Longest history | Compression load on the host |

## Triggers to use the format spontaneously

Do not wait for the skill to be invoked.

- An answer ends with one or more open questions or approvals for the owner.
- A session summary or status report contains an "open for you" list.
- The owner reacts with "which one?", "what is X?" or "I need context". That is the signal that the previous presentation missed this format. Repair it directly in this format.

## Common mistakes

| Mistake | Instead |
|---|---|
| Question without object ("agree on the hook?") | Name the object and the action in the question |
| Advice "agree" or "yes" | Name the concrete action |
| Options inside the Explanation cell | Separate options table under the decision table |
| Bare ticket reference | Number + title + one sentence |
| Explaining the topic but showing no data | Show the measurement, the list or the excerpt |
| Partial table while reports are still pending | Say what you wait for, present once |
| Re-posting or renumbering an earlier table | Keep numbers, add follow-ups, refer to open ones |
| Undefined jargon | Define at first use, then run the cold-reader test |
| "Last time" or a session number as a date | Absolute date or the event itself |
| A route between three parties in text only | Add a drawing |
| Answer only in the chat | Record decision and reason on the ticket |
