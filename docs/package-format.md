# Package format

A package is one shareable thing for an AI coding agent. It lives in `packages/<name>/` and has a
fixed layout so people and agents both know where to look.

## Layout

```
packages/<name>/
  README.md          people: why it exists, the problem, the flow drawing, evidence it works
  README.nl.md       Dutch twin of the README
  flow.svg           drawing of what happens when the package is used
  manifest.json      agents: type, version, install target, compatibility (schema below)
  skill/             the installable part for type "skill" (contains SKILL.md)
  agent/             the installable part for type "agent" (agent profile file)
  addition/          the installable part for type "addition" (hook, instruction block, config)
  examples/          how the author uses it, generalised (see PUBLISHING.md)
```

Exactly one of `skill/`, `agent/`, `addition/` is present; it matches `type` in the manifest.

## README sections (people)

1. **Why** - the behaviour or problem that made this package necessary, in plain words.
2. **What it does** - two or three sentences.
3. **Flow** - the drawing, with one sentence under it saying what you see.
4. **When to use it, when not** - a short table.
5. **Evidence** - what happened before and after, dated if possible.
6. **Install** - copy from `install.source` to `install.target`, plus anything to adapt.

## manifest.json (agents)

```json
{
  "name": "exploring-first",
  "type": "skill",
  "version": "1.0.0",
  "summary": "Separate gathering information from drawing conclusions by delegating the gathering to a subagent.",
  "problem": "An agent trained to answer completely mixes research and conclusion in one response, which produces premature conclusions.",
  "triggers": ["troubleshooting", "diagnosis", "research", "project history", "three or more tool calls expected"],
  "install": {
    "source": "skill/",
    "target": ".claude/skills/exploring-first/"
  },
  "compatible_with": ["claude-code"],
  "requires": [],
  "docs": {
    "readme": "README.md",
    "readme_nl": "README.nl.md",
    "flow": "flow.svg"
  },
  "origin": {
    "author": "DutchNetGuy",
    "generalised_from": "the author's private agent environment",
    "first_published": "2026-11-09"
  }
}
```

| Field | Required | Meaning |
|---|---|---|
| `name` | yes | folder name, lowercase, hyphens |
| `type` | yes | `skill`, `agent` or `addition` |
| `version` | yes | semantic version of the package |
| `summary` | yes | one sentence, what it does |
| `problem` | yes | one sentence, why it exists |
| `triggers` | yes | words or situations that should make an agent think of this package |
| `install.source` | yes | folder inside the package to copy |
| `install.target` | yes | where it goes in the user's project, relative to the project root |
| `compatible_with` | yes | agent platforms it was used with |
| `requires` | no | other packages from this catalog it depends on |
| `docs` | yes | relative paths to the README, Dutch README and flow drawing |
| `origin` | yes | author, where it was generalised from, first publication date |

## The index

`index/catalog.json` is generated from all manifests by the scripts in `scripts/`. It contains
`generated` (date) and `packages`, a list with per package: `name`, `type`, `version`, `summary`,
`problem`, `triggers`, `path` (relative, `packages/<name>/`). `index/catalog.md` is the same list as
a table for people. Never edit either by hand; change the manifest and regenerate.
