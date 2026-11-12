# logging-agent-events: the installable part

| File | What it is |
|---|---|
| `log-event.ps1` | Hook target and deliberate logger (PowerShell 7, module PSSQLite) |
| `schema.sql` | The `events` table; the script applies it itself on every call (`IF NOT EXISTS`) |
| `hooks.example.json` | The two hook entries for Claude Code (after a tool call, after a failed tool call) |

## Two kinds of events

| Kind | Written by | When | `source` |
|---|---|---|---|
| Automatic | the hook | after every tool call, successful or failed | `auto` |
| Deliberate | the agent, by calling the script | decision, blocker, milestone, lesson, frustration, success | `agent` |

A minimal set of deliberate `event_type` values:

| Value | When |
|---|---|
| `start` / `end` | beginning and end of a work block or session |
| `decision` | a choice was made; put the reason in the summary |
| `blocker` | work is stuck; say on whom or what it waits |
| `milestone` | something is done and checked |
| `frustration` | broken tool, conflicting instructions, three or more failed attempts |
| `success` | something worked notably well, so the improvement list is not only complaints |

## Reading the log

Any SQLite client works. Give the agent a small script with fixed queries instead of letting it write its own SQL: fixed queries give predictable output and no invented columns. Examples:

```sql
-- what happened today
SELECT timestamp, agent_name, tool_name, success, summary
FROM events WHERE timestamp >= date('now','localtime') ORDER BY id DESC LIMIT 50;

-- failed tool calls (not the same as deliberate event_type 'failure')
SELECT timestamp, tool_name, summary FROM events WHERE success = 0 ORDER BY id DESC LIMIT 20;

-- decisions and blockers of one session
SELECT timestamp, event_type, summary FROM events
WHERE session_id = '<session-id>' AND source = 'agent' ORDER BY id;

-- which source fills the log (run this monthly)
SELECT COALESCE(category, tool_name, event_type) AS source_of_rows, COUNT(*) AS n
FROM events GROUP BY 1 ORDER BY n DESC LIMIT 10;
```

## Growth

Rule of thumb: **events per day × 700 bytes × 30 = growth per month.** About 700 bytes per row is what the author measured, indexes included; most of it is the `detail` column.

| Situation | Events per day | Per month | Per year |
|---|---|---|---|
| One person, quiet | 3,000 | about 60 MB | about 0.75 GB |
| One person, busy, two or three sessions at once | 10,000 | about 210 MB | about 2.5 GB |
| Plus one source that logs every internal step | 50,000+ | about 1 GB or more | over 12 GB |

One row per tool call is manageable. What makes growth run away is a single writer that logs every internal step; you only see it when you count per source.

## Lessons

| What happened | What to do instead |
|---|---|
| The original script masked nothing; commands were stored as typed | Mask in the script (this package does) and keep the rule "never put a secret value in a command" |
| No retention; the file passed 1 GB | Decide retention per level up front (below) |
| One helper wrote two progress lines per call: 30 % of all rows | Decide at the source what goes to the event log; progress goes to a plain log file |
| Several sessions write at the same time | WAL mode and a busy timeout (this package sets both) |
| A failing hook script fails quietly on purpose (one stderr line, exit 1, never blocks), and an async hook usually shows that nowhere | A daily check: "are there events today?" |
| Every tool call starts a PowerShell process, loads the SQLite module and applies the schema | Fine for one person, because the hook runs async; at high volume use a lighter writer or batch the rows |
| Start-up did not read the log by itself | Put "read the last events" in the start-up instruction, or use a start-up hook if your platform has one |

## Cleanup by level

Decide for every kind of event where it goes and how long it stays. The level is the most practical key.

| Level or kind | Goes to | Keep |
|---|---|---|
| `verbose`, `progress` | a plain log file only, never the event log | short (the author keeps two weeks) |
| automatic tool call | event log | clear `detail` after about 30 days, delete the row after 90 to 180 days |
| `warning`, `error` | event log | 180 days |
| deliberate: decision, blocker, milestone, frustration, success | event log | keep (few rows, high value) |
| decisions an agent takes under a mandate (audit) | a separate append-only table | never delete |

Triggers:

| Trigger | Then |
|---|---|
| Age: a row is older than the retention of its level | cleanup job at a fixed moment, for example weekly |
| Size: the file passes a limit you chose | tell the owner, run the cleanup earlier |
| Share: one source or category passes about 20 % of the rows | change the **source** (lower its level or send it to a plain log), do not only delete rows |
| New writer: a script starts writing to the event log | set its level and retention before it goes live |

Always: copy the file first, run a dry count, then delete. `VACUUM INTO` refuses an existing file, so give every backup a new name, for example with the date.

```sql
VACUUM INTO 'events-backup-2026-11-12.db';                        -- 1. copy
SELECT COUNT(*) FROM events
WHERE source = 'auto' AND detail IS NOT NULL
  AND timestamp < strftime('%Y-%m-%dT%H:%M:%S','now','localtime','-30 days');   -- 2. dry count
UPDATE events SET detail = NULL
WHERE source = 'auto' AND detail IS NOT NULL
  AND timestamp < strftime('%Y-%m-%dT%H:%M:%S','now','localtime','-30 days');   -- 3. clear detail
```

## Privacy

The log holds what the agent saw and did: commands, file paths and up to 2,000 characters of tool output.

Masking is a safety net, not a guarantee. It catches values of secret-looking keys (`token=`, `password:`, `X-Api-Key:`, `export GITHUB_TOKEN=`), `Bearer` and `Basic` credentials, `user:password@` in URLs, `password <value>` and `--password`, private-key blocks, and long token-like strings of 32 characters or more. Side effects: a 40-character git commit hash is masked too, and so is the word after "password" in ordinary text ("the password *** required").

Known gaps: a password glued to a short flag (`-pSecret`), keys whose name is only `key` or `credential`, tokens shorter than 32 characters, and secrets in unusual shapes. So keep the rule "never put a secret value in a command", keep the database out of version control (`.gitignore`, with its `-wal` and `-shm` files) and readable only for yourself.

Before you install this at work, check that a local log like this is allowed, where it may live, how long it may be kept and who may read it.
