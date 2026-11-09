# AgentStuff

A catalog of **packages for AI coding agents**: skills, agent profiles and additions to agents.
Every package comes with two faces:

- a **README for people** that explains *why* the package exists, what problem it solves, and a
  drawing of the flow (what actually happens when you use it);
- a **manifest for agents** (`manifest.json`) so an agent can read the catalog, pick a package and
  know where it goes.

Most repositories that share agent skills share the folder and nothing else. This one tries to share
the understanding too. A skill you do not understand is a rule you will drop under pressure.

Dutch version of this page: [README.nl.md](README.nl.md). Every package README has a Dutch twin as well.

## How to use a package (people)

1. Open `packages/<name>/README.md` and read the *Why* and the flow drawing.
2. Copy the folder named in the manifest's `install.source` to the path in `install.target`
   (for a Claude Code skill: `packages/<name>/skill/` to `.claude/skills/<name>/`).
3. Read `examples/` to see how the author uses it, then adapt it to your own environment.

## How to use this repository (agents)

1. Read `index/catalog.json`. One entry per package: name, type, one-line problem, triggers, path.
2. Open the package's `manifest.json` for install details and compatibility.
3. Never read more than you need: the catalog is the map, the package is the territory.

## Structure

```
AgentStuff/
  README.md / README.nl.md     this page
  PUBLISHING.md                what may be published here, and how it is generalised
  LICENSE                      MIT
  docs/package-format.md       the package layout and the manifest schema
  index/
    catalog.json               for agents (generated, do not edit by hand)
    catalog.md                 the same list for people (generated)
  packages/
    <name>/
      README.md                why, problem, flow, evidence
      README.nl.md             Dutch twin
      flow.svg                 what happens when you use it
      manifest.json            type, version, install target, compatibility
      skill/ | agent/ | ...    the installable part
      examples/                how the author uses it (generalised)
  scripts/                     index generator (PowerShell and Python)
```

## Packages

See [index/catalog.md](index/catalog.md).

## Publishing policy

Everything here is **generalised**: no hostnames, IP addresses, ticket numbers, internal paths,
secrets or people other than the author. The author's own setup appears only under `examples/`,
with placeholders. Details: [PUBLISHING.md](PUBLISHING.md).

## License

MIT, see [LICENSE](LICENSE).
