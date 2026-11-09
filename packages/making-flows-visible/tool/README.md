# Flow board (tool)

A static page that shows flows and what they lean on. You describe flows in small JSON files, a Python script checks them and writes one data file, and `index.html` computes and draws everything in the browser. No server code, no dependencies beyond Python 3 (standard library only).

What the page shows:

- **One row per flow**: a bar of lead time split into work (agent or script), human action and waiting, with percentages.
- **Dependency chips** per flow, with a letter for the type: S system, D data, R right (access or permission), P process, M person, T tool.
- **Single points of knowledge**: a dependency that exactly one person or agent knows is marked red ("only X"). A dependency nobody knows is marked "nobody".
- **Who carries the most**: per person, how many dependencies they know, how many flows lean on that knowledge, and where they are the only one.
- **Detail per flow**: your drawing, the timeline per actor, the waiting time per external party, the steps with their own dependencies, and the versions (current, design, retired) side by side.

## Run it

```
python3 -I tools/generate_bord.py            # check the model and write data/bord.js
python3 -I tools/generate_bord.py --controleer   # check only, write nothing
python3 -I tools/generate_bord.py --lijst        # list the ids and roles you may use
python3 -I tools/generate_bord.py --formatteer   # rewrite the model files in a tidy fixed layout
```

Then serve this folder with any static web server and open `index.html`:

```
python3 -m http.server 8900
```

Exit code 0 means the model is valid. Exit code 1 means the JSON has errors; each one is reported with file and place, and `data/bord.js` is not touched. The messages of the generator are in Dutch.

Settings in `model/config.json`: `taal` (`"nl"` or `"en"`, default `"nl"`) sets the language of the page, `titel` sets the heading. Flow and step names stay as you write them; only the interface text is translated.

## Add a flow (6 steps)

1. Copy `model/flows/_template.json` to `model/flows/<id>.json`. The id is a capital plus a digit, for example `H3`, and must equal the file name.
2. Fill in the fields at the top: name, one-sentence goal, kind (`flow` repeats, `taak` happens once), priority and, for a flow, the frequency.
3. List what it leans on under `afhankelijkheden`. If a dependency does not exist yet, add it to `model/afhankelijkheden.json` first, with the people who know it under `kennis`.
4. Write one version with one line per step: what happens, who does it, the kind (`mens`, `werk`, `wacht`) and the hours per ticket. Optional per step: `start`, `eind`, `meetpunt` and the step's own `afhankelijkheden`.
5. Run `python3 -I tools/generate_bord.py` and fix what it reports.
6. Reload the page. Add a drawing later by putting an SVG in a folder next to `index.html` and naming its path in `tekening`.

## The model

The generator expects Dutch file names and keys. They are deliberately not renamed, so existing boards keep working. Here is what they mean.

Files in `model/`:

| File | Content |
|---|---|
| `config.json` | the knobs of the board |
| `mensen.json` | people and agents, with a role |
| `afhankelijkheden.json` | everything flows lean on |
| `flows/<id>.json` | one flow or task per file; files starting with `_` are ignored |

Keys (Dutch, meaning):

| Key | Where | Meaning |
|---|---|---|
| `taal`, `titel` | config | page language (`nl`, `en`) and heading |
| `werkdagen_per_jaar`, `werkweken_per_jaar`, `maanden_per_jaar` | config | how many workdays, weeks and months a year count, used to turn a frequency into a yearly number |
| `uren_per_fte` | config | hours in one full-time equivalent |
| `fte_rollen` | config | roles whose human steps count as owner time in the FTE estimate |
| `rollen` | config | roles you may use in `wie` besides ids of people and dependencies |
| `id`, `naam`, `rol` | mensen | short id, display name, role text |
| `type` | afhankelijkheden | `systeem` system, `data` data, `recht` right, `proces` process, `mens` person, `tool` tool |
| `kennis` | afhankelijkheden | ids of the people or agents who know or run it |
| `extern` | afhankelijkheden | `true` for a party outside your organisation |
| `onderhoud.uren_per_maand` | afhankelijkheden | hours a month to keep it running, shared over the flows that use it |
| `soort` | flow | `flow` repeats and is measurable per ticket, `taak` happens once |
| `doel` | flow | one sentence goal |
| `groep` | flow | free text shown under the name |
| `prio` | flow | whole number, lower is higher on the board |
| `tekening` | flow | path to an SVG, or empty |
| `frequentie` | flow | `aantal` (count) per `per`: `werkdag`, `week` or `maand` |
| `heeft_nodig` | flow | other flows that must exist first, bare id or `{id, waarom}` |
| `afhankelijkheden` | flow, step | ids of what it leans on |
| `versies` | flow | one or more versions of the way of working |
| `versie`, `naam`, `bron` | version | number, name, where the hours come from |
| `status` | version | `huidig` current, `ontwerp` design, `vervallen` retired |
| `onderhoud` | version | `uren_per_maand` plus optional `stappen`, `afhankelijkheden`, `kennis` |
| `stappen` | version | the timeline of one ticket |
| `wie` | step | person id, dependency id or role |
| `soort` (step) | step | `mens` human works on it, `werk` agent or script works on it, `wacht` nobody of ours works on it |
| `uren` | step | hours of this step per ticket |
| `start`, `eind` | step | the moment the step starts and ends, in words |
| `meetpunt` | step | `systeem` and `veld` that already record the moment, optional `telt_als` and `bron` |

Keys that start with an underscore are notes for people and are ignored everywhere.

## Dependencies per step

A step can name the dependencies it leans on. The detail page shows them as chips under the step. The flow-level list is what the overview counts; the step-level list tells you where in the flow each dependency is used. The field is optional, so a model without it works.

## Versions

A flow can hold several versions, for example the manual way (retired), the current way and a design. The page shows a button per version and recomputes bar, timeline and FTE for the one you pick. Choose the version with the link `#stroom=H1&versie=1.0`.

## How the bottleneck is computed

1. Take every dependency that at least one flow uses.
2. Count how many people or agents are listed under its `kennis`.
3. Exactly one: a single point of knowledge, shown red as "only X". External parties count too.
4. None: shown as "nobody", because someone has to jump into that gap.
5. The heading figure is "single points of all dependencies in use"; per person it is the number of single points where they are the only one.

The FTE estimate per flow is: frequency per year times the hours of human steps by the `fte_rollen`, plus the version's maintenance hours, plus a share of the maintenance hours of its dependencies, divided by `uren_per_fte`.

## Files

| Path | What |
|---|---|
| `index.html` | the page; all interface text is in one `TEKST` object at the top of the script |
| `tools/generate_bord.py` | checks the model and writes `data/bord.js`; holds the version constant `BORD_VERSIE` |
| `model/` | your data; the example here is two generalised flows |
| `data/bord.js` | generated, never edit |
