-- Event log for an AI coding agent (SQLite).
-- One row per event. Automatic rows come from a hook after every tool call (source = 'auto');
-- deliberate rows come from the agent itself through the log script (source = 'agent').
-- log-event.ps1 runs this file's statements itself (CREATE ... IF NOT EXISTS), so running it by
-- hand is optional.

PRAGMA journal_mode = WAL;          -- several sessions may write at the same time

CREATE TABLE IF NOT EXISTS events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now','localtime')),
    session_id  TEXT,                       -- id of the agent session
    issue_id    TEXT,                       -- ticket or work item, free text (e.g. CHG0012345)
    tool_name   TEXT,                       -- Read, Edit, Bash, ... ; empty for deliberate events
    success     INTEGER,                    -- 1 = ok, 0 = the tool call failed
    source      TEXT    NOT NULL DEFAULT 'auto' CHECK (source IN ('auto','agent')),
    event_type  TEXT,                       -- empty for automatic rows; decision, blocker, milestone, ...
    level       TEXT    NOT NULL DEFAULT 'info'
                        CHECK (level IN ('verbose','progress','info','warning','error')),
    category    TEXT,                       -- free grouping, used for filtering and cleanup
    summary     TEXT,                       -- what happened, short (masked, max 200 characters)
    detail      TEXT,                       -- tool output (masked, max 2000 characters)
    agent_name  TEXT    NOT NULL DEFAULT 'unknown',
    topic       TEXT    NOT NULL DEFAULT 'unknown'
);

CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_session   ON events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_issue     ON events(issue_id);
CREATE INDEX IF NOT EXISTS idx_events_type      ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_level     ON events(level);
CREATE INDEX IF NOT EXISTS idx_events_agent     ON events(agent_name);
