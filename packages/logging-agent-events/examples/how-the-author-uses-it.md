# How the author uses it

One person, one Linux machine, Claude Code in a terminal, usually two or three agent sessions at the same time. The event log has run since April 2026. Names below are placeholders.

## Three layers of working memory

| Layer | Question | Where |
|---|---|---|
| Tasks | What should happen? | a project tracker |
| **Events** | **What happens?** | **this event log, filled by the hook** |
| Context | What does the agent remember? | memory files, read at session start |

The tracker is for what the owner must know (start, blocker, done). The event log is for everything: the audit trail.

## What the log is used for

| Use | Question it answers |
|---|---|
| Audit | What did the agent do, per session, day or ticket? |
| Troubleshooting | Which tool calls failed? |
| Session start | Where were we? The start-up instruction tells the agent to read the latest events. |
| Decisions and blockers | When was what decided, what was stuck and on what? |
| Improvement list | Where did the agent get stuck (broken tool, conflicting instructions, three failed attempts), and what worked well? The owner reviews these to improve instructions. |
| Parallel agents | Every row carries the agent name and topic, so two sessions working at once stay apart. |

The same database file also holds a few small tables next to `events` that are not part of this package: a session-number registry (so an agent never invents its session number), a chat table that parallel agents use as a fallback when built-in messaging loses messages, a factcheck-result table, and an append-only table for decisions agents take under a mandate.

## Numbers after seven months

| Measure | Value |
|---|---|
| Events | about 1.58 million |
| Average per day | about 7,500 |
| A busy day | over 12,000 |
| File size | about 1.1 GB |
| Per event | about 700 bytes |

## What changed along the way

- **Progress lines moved out.** A heavily used helper wrote two progress lines per call into the log: over 600,000 rows in less than two weeks, 30 % of the database at that time, read by nobody. Now `verbose` and `progress` lines of listed categories go only to a plain log file, which is kept two weeks.
- **Masking.** The private script still masks nothing; the rule "never a secret value in a command" carries all the weight. The version in this package masks in the script.
- **Identity per row.** Agent name and topic come from environment variables that are set before a worker session starts, because hooks inherit the environment at launch and cannot be changed mid-session.

## Hook configuration (placeholders)

```json
"PostToolUse":        [{ "matcher": "*", "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File <project-root>/tools/agent-events/log-event.ps1", "timeout": 10, "async": true }] }],
"PostToolUseFailure": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "pwsh -NoProfile -File <project-root>/tools/agent-events/log-event.ps1", "timeout": 10, "async": true }] }]
```

Other hooks in the author's setup run before a tool call (gates that can block). They do not write to this table.
