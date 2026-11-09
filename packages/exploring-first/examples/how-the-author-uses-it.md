# How the author uses it

The author runs a personal assistant called Jarvis on top of Claude Code. This is how exploring-first is set up there. Adapt it to your own environment.

## Threshold

Three tool calls. If Jarvis expects to need three or more calls to answer a question, it starts an Explore subagent instead of searching in the main conversation. A lookup that "feels like one call" in project history goes to a subagent as well, because the agent's estimate of its own call count is the thing that proved unreliable.

## When the skill is loaded

At the start of every session. The skill body is in context from the first message, so the rule is present before the first question arrives, not looked up after the habit has already formed.

The one exception is the agent's own start-up reading: instructions, notes and the last session log. Jarvis reads those itself, because a subagent summary would defeat the purpose of loading them.

## Search order

The subagent prompt always includes the order, because the subagent knows nothing about the environment beyond what the prompt says:

1. The project tracker: issue body and comments.
2. The research documents the issue refers to.
3. Memory notes.
4. Own reasoning, only when 1 to 3 are empty.

A local search index sits in front of this and is tried first. It costs almost no model tokens and returns the right document directly.

## Model choice

The author uses three tiers by task shape: a light model to locate, a medium model as the default for reading and reporting, and a heavy model only for synthesis or review, named in the answer when chosen. The heavy model was tried as a default and turned out to be overkill that counts fully against the usage budget.

## Factcheck

Research that ends in a lasting document gets a factcheck (Mode A). When every source is local, a spot-check of the load-bearing claims is enough. For web or PDF sources the pass is complete.

Each factcheck result is logged to a small database, and a second script shows the trend. The point is not a score. It is to see whether the pass keeps finding errors, which would mean the first pass needs a better brief.

## What went wrong at first

- The subagent was told what to expect, and it found it.
- Findings were presented together with a recommendation, so the pause never happened.
- The factcheck was handed to the same subagent that did the research.

Each of these is now a line in the skill's list of common mistakes.
