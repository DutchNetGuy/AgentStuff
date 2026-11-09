# Publicatiebeleid

**Regel: alles wat hier gepubliceerd wordt is gegeneraliseerd.** De privé-omgeving waar deze packages
ontstaan zijn is de bron van waarheid; deze repository krijgt een kopie waaruit de omgeving is gehaald.

## Wat er nooit in komt

| Categorie | Voorbeelden | Vervang door |
|---|---|---|
| Netwerk-identiteit | hostnamen, IP-adressen, VLAN-nummers, domeinnamen | `<your-host>`, `<server>` |
| Werkadministratie | ticketnummers, bordnamen, sessienummers | het besluit of de les zelf, met datum |
| Interne paden | absolute paden van de privé-omgeving | `<project-root>/...` of een relatief pad |
| Geheimen | tokens, sleutels, accountnamen, kluisnamen | niets; beschrijf het mechanisme, niet de waarde |
| Personen | namen anders dan de auteur | een rol ("de eigenaar", "de reviewer") |
| Privé-tooling | containernamen, interne scripts, interne databases | een algemene beschrijving van wat de tool doet |

## Wat er wel in komt

- Het **waarom**: het probleem dat het package oplost en het bewijs dat het werkt. Datums mogen; het
  verhaal maakt een package bruikbaar.
- De **flow**: een tekening van wat er gebeurt als het package gebruikt wordt.
- Het **installeerbare deel**, zo geschreven dat het in een verse omgeving werkt.
- **Voorbeelden** van het eigen gebruik van de auteur onder `examples/`, met de tabel hierboven toegepast.

## Procedure vóór een push

1. Doorzoek het package op de categorieën hierboven (een IPv4-adres, een ticketpatroon `-[0-9]+`,
   het privé-rootpad, interne toolnamen).
2. Lees de README één keer als vreemde: staat elke zin overeind zonder de privé-omgeving?
3. Genereer de index opnieuw (`scripts/`) zodat `index/catalog.json` klopt met de manifests.
4. Push.

## Waarom dit beleid bestaat

Gedeelde skill-mappen lekken meestal per ongeluk de omgeving van de auteur: hier een pad, daar een
ticketnummer. Lezers kunnen dan niet zien wat essentieel is en wat lokaal. Generaliseren dwingt de
auteur het idee te scheiden van de installatie, en dat is precies de scheiding die een lezer nodig heeft.

English version: [PUBLISHING.md](PUBLISHING.md).
