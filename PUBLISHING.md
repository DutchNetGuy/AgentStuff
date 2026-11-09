# Publishing policy

**Rule: everything published here is generalised.** The private environment where these packages
were born is the source of truth; this repository receives a copy with the environment removed.

## What never goes in

| Category | Examples | Replace with |
|---|---|---|
| Network identity | hostnames, IP addresses, VLAN numbers, domain names | `<your-host>`, `<server>` |
| Work tracking | ticket numbers, board names, session numbers | the decision or lesson itself, dated |
| Internal paths | absolute paths of the private environment | `<project-root>/...` or a relative path |
| Secrets | tokens, keys, account names, vault names | nothing; describe the mechanism, not the value |
| People | names other than the author | a role ("the owner", "the reviewer") |
| Private tooling | container names, internal scripts, internal databases | a generic description of what the tool does |

## What does go in

- The **why**: the problem the package solves and the evidence that it does. Dates are fine; the
  story is what makes a package usable.
- The **flow**: a drawing of what happens when the package is used.
- The **installable part**, written so it works in a fresh environment.
- **Examples** of the author's own use under `examples/`, with the table above applied.

## Procedure before a push

1. Grep the package for the categories above (a dotted IPv4, a `-[0-9]+` ticket pattern, the private
   root path, the author's internal tool names).
2. Read the README once as a stranger: does every sentence stand without the private environment?
3. Regenerate the index (`scripts/`) so `index/catalog.json` matches the manifests.
4. Push.

## Why this policy exists

Shared skill folders usually leak the author's environment by accident: a path here, a ticket
number there. Readers then cannot tell what is essential and what is local. Generalising forces the
author to separate the idea from the installation, which is the same separation a reader needs.

Nederlandse versie: [PUBLISHING.nl.md](PUBLISHING.nl.md).
