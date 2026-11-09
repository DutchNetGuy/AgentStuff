---
name: exploring-first
description: "Use when information must be gathered before conclusions are drawn: technical (logs, system state, files) or non-technical (research, context, examples, project history, past decisions). Use before troubleshooting, diagnosing, recommending or designing, and before re-opening an existing decision. Triggers: three or more tool calls expected, inventory of a codebase or system, multi-source research, diagnosis, 'what was decided about X', 'is this already covered', 'did we choose Y and why'. Includes an optional factcheck pass with three modes (A mandatory for lasting artifacts, B skip for throwaway info, C forced on request). Keywords: explore subagent, gather first, premature conclusion, research first, project history, past decision, factcheck, verify against primary source."
version: "1.0"
---

# Exploring First

## Why this skill exists

An agent trained to give complete answers combines two jobs in one response: gathering information and drawing a conclusion. The result is a premature conclusion built on whatever the first few queries returned.

This is structural behaviour, not carelessness, so an instruction like "think before you answer" does not hold under pressure. A subagent does. It makes the pause between data and analysis mechanical: the data arrives as a separate result, and the main agent has to stop and present it before analysing.

The agent also underestimates how much it needs to look up. It thinks "one call and I know", then makes five or more calls inside the main conversation, mixed with conclusions. Delegating the gathering removes that failure.

## The pattern

```
Without this skill:
  Question -> [gather + reason + conclude] -> answer
                one response, one shot

With this skill:
  Question -> Explore subagent gathers
           -> (optional) independent factcheck subagent checks against the primary source
           -> present raw findings, no conclusions
           -> pause, wait for go-ahead
           -> only then: analysis by the main agent
```

## When to use it, when not

Threshold: **expect three or more tool calls to answer the question? Use a subagent.**

| Use a subagent | Do it yourself |
|---|---|
| Three or more tool calls needed | Reading one file at a known path |
| Inventory of a codebase, tracker or system | A grep for one specific symbol |
| Diagnosis across several sources | Checking one API endpoint |
| Project history: issues, decisions, research docs | A fact already in your context |
| Research on an unfamiliar topic | A simple yes/no confirmation |
| Advice on something you do not fully know yet | One `ls` or `cat` |

**Exception: loading your own start-up context.** The threshold applies to research and diagnosis questions. It does not apply to reading the files that set up your own session (instructions, notes, the last session log). Read those yourself, however many calls it takes. The goal is that the content ends up in your context. A subagent summary of it brings back the failure this skill exists to prevent: title-only reading and summary bias.

### Hard rule for project history

If a question touches a decision recorded in your tracker or docs, always use an Explore subagent, however short the lookup feels. Typical triggers:

- "What was decided about X?" or "do we meet requirement Y?"
- "Is this already covered anywhere?" or "does an issue about this exist?"
- "Why did we not choose Z?"
- Any question that ends in an architecture recommendation or in reversing a decision.

Search order for project history:

1. Your project tracker: the issue body and its comments (latest decision).
2. Documents the issue refers to.
3. Memory or notes you keep.
4. Your own reasoning, only when 1 to 3 are empty.

If you have a local knowledge base or search index, put it at the front of that order. It is cheap and returns the right document directly. The subagent only searches what you tell it about, so write the search order into its prompt.

## The five steps

**Step 1. Start an Explore subagent.**
- Tell it WHAT to retrieve, WHERE to look and HOW to return it.
- Do not tell it what you expect to find. That steers the result.
- Add: "RESEARCH ONLY, no implementation and no conclusions."
- Ask it to mark verifiable claims (figures, quotes, names, paper details).
- Choose the model by the shape of the task (see below).

**Step 2. Factcheck (see the three modes).** A second, independent subagent reads the primary source itself and checks each marked claim. It returns a table: claim, status, source and page.

**Step 3. Present the raw findings.** Show what came back, plus the factcheck result if there was one. No interpretation, no conclusion.

**Step 4. Ask for the go-ahead.** For example: "The information is in. Do you want me to analyse it now?"

**Step 5. Analyse.** Only now do you draw conclusions, in the main agent.

## Model choice

Choose the subagent's model by the shape of the task, not the size of the files. Measuring file size first costs calls of its own and says little about difficulty.

| Task shape | Model tier |
|---|---|
| Pure locating or listing: which file, line or path, does X exist | Light |
| Reading, understanding and reporting (the default) | Medium |
| Heavy multi-source synthesis or a judgement-heavy review | Heavy, chosen on purpose and named in your answer |

Too light a model means a missed finding, and a redo costs more than the saving. The subagent's understanding becomes your decision input, so do not economise on the default.

## Factcheck pass: three modes

The factcheck is a second, independent subagent. It does no new research. It checks the first pass's claims against the primary source for literal wording, page numbers, names, order and figures, and marks each claim as confirmed, wrong, nuanced or not found.

It catches errors that the author and the first subagent share as a blind spot.

**Mode A: mandatory for lasting artifacts.** Use it when the research ends in something that stays and can be acted on later: a document on disk, a tracker issue or comment, a memory entry, a plan for implementation. Once a claim is written down, someone will rely on it, and the cost of a wrong claim outweighs the cost of a second pass.
- If all sources are local and cheap to re-read (your own repo, docs, logs), a spot-check of the load-bearing claims is enough. Load-bearing means a decision or follow-up action depends on it: figures, quotes, "exists" and "does not exist" statements.
- If a source is external (web, PDF, paper), do the full pass.
- If a knowledge-base document already states that its claims were checked, do not check them again. Check only new or derived claims.

**Mode B: skip for throwaway information.** Trivial lookups, known codebase facts, internal status, an answer that stays in the conversation, a single source with few claims. The pass costs more than it protects.

**Mode C: forced on request.** The owner can ask for it when they see you under pressure: a long session, a lot of context, many topic switches, doubt about quality. Typical phrases: "factcheck this", "validate against the source". The pass is a safety net for when the drive to answer completely wins over care.

| Mode | Extra tokens | Justified when |
|---|---|---|
| A | about 2x the research | A lasting artifact: the cost of an error exceeds the cost of a second pass |
| B | none | Throwaway information |
| C | about 2x the research | The owner accepts the cost as a quality net |

### What the factcheck subagent does

1. Reads the primary source itself. It receives only the summary to validate, nothing else from pass one.
2. Goes through every concrete claim, quote, figure, name and structural statement.
3. Marks each as confirmed, wrong, nuanced or not found, with the page or location.
4. Returns a table and a short summary: counts and the three most important deviations.
5. Gives no recommendations and no analysis. Validation only.
6. If you keep a log of factcheck results, record the outcome so a trend becomes visible over time.

### Primary sources only

Check against the primary source: the PDF, the paper, the original document. Do not check against blogs, wiki summaries or the references of the report itself. They can pass on the same error.

## Common mistakes

- Gathering and concluding in the same response. The mechanical brake does not work.
- Telling the subagent what you expect to find. It shapes what comes back.
- Starting the analysis without a pause. The owner cannot review the data first.
- Using the pattern only for technical tasks. It applies to all information gathering.
- Presenting numbers without checking them against the primary source. This is the silent error.
- Factchecking against secondary sources.
- Skipping Mode A for a lasting artifact because "I can do this myself". The mode is mechanical, not a judgement call. The author cannot see their own blind spot.
- Asking the pass-one subagent to "also validate it quickly". It is not independent and has the same blind spot. Always use a fresh subagent.
