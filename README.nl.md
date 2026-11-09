# AgentStuff

Een catalogus van **packages voor AI-coding-agents**: skills, agent-profielen en toevoegingen aan
agents. Elk package heeft twee gezichten:

- een **README voor mensen** die uitlegt *waarom* het package bestaat, welk probleem het oplost, met
  een tekening van de flow (wat er echt gebeurt als je het gebruikt);
- een **manifest voor agents** (`manifest.json`), zodat een agent de catalogus kan lezen, een package
  kan kiezen en weet waar het terechtkomt.

De meeste repositories die agent-skills delen, delen de map en verder niets. Deze probeert ook het
begrip te delen. Een skill die je niet begrijpt is een regel die je onder druk laat vallen.

Engelse versie van deze pagina: [README.md](README.md). Elk package heeft ook een Engelse en een
Nederlandse README.

## Een package gebruiken (mensen)

1. Open `packages/<naam>/README.nl.md` en lees het *Waarom* en de flow-tekening.
2. Kopieer de map uit `install.source` in het manifest naar het pad in `install.target`
   (voor een Claude Code-skill: `packages/<naam>/skill/` naar `.claude/skills/<naam>/`).
3. Lees `examples/` om te zien hoe de auteur het gebruikt, en pas het aan op je eigen omgeving.

## Deze repository gebruiken (agents)

1. Lees `index/catalog.json`. Eén regel per package: naam, type, probleem in één zin, triggers, pad.
2. Open het `manifest.json` van het package voor installatie en compatibiliteit.
3. Lees nooit meer dan nodig: de catalogus is de kaart, het package is het terrein.

## Structuur

```
AgentStuff/
  README.md / README.nl.md     deze pagina
  PUBLISHING.md                wat hier gepubliceerd mag worden, en hoe het gegeneraliseerd wordt
  LICENSE                      MIT
  docs/package-format.md       de package-indeling en het manifest-schema
  index/
    catalog.json               voor agents (gegenereerd, niet met de hand bewerken)
    catalog.md                 dezelfde lijst voor mensen (gegenereerd)
  packages/
    <naam>/
      README.md                waarom, probleem, flow, bewijs
      README.nl.md             Nederlandse versie
      flow.svg                 wat er gebeurt als je het gebruikt
      manifest.json            type, versie, installatiepad, compatibiliteit
      skill/ | agent/ | ...    het installeerbare deel
      examples/                hoe de auteur het gebruikt (gegeneraliseerd)
  scripts/                     index-generator (PowerShell en Python)
```

## Packages

Zie [index/catalog.md](index/catalog.md).

## Publicatiebeleid

Alles hier is **gegeneraliseerd**: geen hostnamen, IP-adressen, ticketnummers, interne paden,
geheimen of andere personen dan de auteur. De eigen omgeving van de auteur komt alleen voor onder
`examples/`, met placeholders. Details: [PUBLISHING.md](PUBLISHING.md).

## Licentie

MIT, zie [LICENSE](LICENSE).
