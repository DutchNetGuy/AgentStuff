"""Genereert data/bord.js uit de JSON-bestanden in model/.

De JSON is de waarheid. Dit script leest, controleert en schrijft; de pagina rekent en toont.
Sleutels die met _ beginnen (zoals "_uitleg") zijn toelichting voor mensen en worden genegeerd.
Gebruik (vanuit elke map):
    python3 -I tools/generate_bord.py                 # controleren en data/bord.js schrijven
    python3 -I tools/generate_bord.py --controleer    # alleen controleren, niets schrijven
    python3 -I tools/generate_bord.py --lijst         # toont welke ids en rollen je in een flow mag gebruiken
    python3 -I tools/generate_bord.py --formatteer    # alle model-bestanden in vaste nette vorm terugschrijven
Exit 0 = gelukt, exit 1 = er staan fouten in de JSON (in gewone taal, met bestand en plek).
"""
import json
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODEL = ROOT / "model"
UITVOER = ROOT / "data" / "bord.js"
BORD_VERSIE = "1.0.0"
TALEN = ["nl", "en"]
KOPREGEL = "// GEGENEREERD door tools/generate_bord.py uit model/ — niet bewerken, wijzig de JSON"

STAP_SOORTEN = ["werk", "mens", "wacht"]
VERSIE_STATUSSEN = ["huidig", "ontwerp", "vervallen"]
FREQUENTIE_PER = ["werkdag", "week", "maand"]
FLOW_SOORTEN = ["flow", "taak"]
DEP_TYPEN = ["systeem", "data", "recht", "proces", "mens", "tool"]
STAP_VELDEN = ["naam", "wie", "soort", "uren", "start", "eind", "meetpunt", "afhankelijkheden"]
MEETPUNT_VELDEN = ["systeem", "veld", "telt_als", "bron"]
FLOW_VELDEN = ["id", "naam", "soort", "doel", "groep", "prio", "tekening", "frequentie",
               "heeft_nodig", "afhankelijkheden", "versies"]
VERSIE_VELDEN = ["versie", "naam", "status", "bron", "onderhoud", "stappen"]
ONDERHOUD_VELDEN = ["uren_per_maand", "stappen", "afhankelijkheden", "kennis"]
DEP_VELDEN = ["id", "naam", "type", "kennis", "extern", "onderhoud", "tijdlijn"]
CONFIG_VELDEN = ["werkdagen_per_jaar", "werkweken_per_jaar", "maanden_per_jaar", "uren_per_fte",
                 "fte_rollen", "rollen"]
CONFIG_OPTIONEEL = ["taal", "titel"]       # taal: nl of en (standaard nl); titel: kop van de pagina


class Fouten:
    """Verzamelt foutmeldingen in gewone taal."""

    def __init__(self) -> None:
        self.lijst: list[str] = []

    def melden(self, bestand: str, plek: str, tekst: str) -> None:
        self.lijst.append(f"{bestand}, {plek}: {tekst}")


def explain_json_error(fout: json.JSONDecodeError, tekst: str) -> str:
    """Zet een JSON-leesfout om in gewone taal, met regel en kolom."""
    regel, kolom = fout.lineno, fout.colno
    hint = ""
    if "delimiter" in fout.msg or "Expecting property name" in fout.msg:
        regels = tekst.splitlines()
        vorige = next((i for i in range(min(regel, len(regels)) - 1, 0, -1) if regels[i - 1].strip()), regel)
        hint = f" Komma vergeten of te veel na regel {vorige}?"
    elif "Expecting value" in fout.msg:
        hint = " Staat er een komma te veel voor een sluitteken, of ontbreekt een waarde?"
    elif "double quotes" in fout.msg:
        hint = " Gebruik dubbele aanhalingstekens, geen enkele."
    return f"regel {regel}, kolom {kolom}: {fout.msg}.{hint}"


def strip_notes(obj):
    """Verwijdert alle sleutels die met _ beginnen (toelichting voor mensen), overal in de structuur."""
    if isinstance(obj, dict):
        return {k: strip_notes(v) for k, v in obj.items() if not str(k).startswith("_")}
    if isinstance(obj, list):
        return [strip_notes(v) for v in obj]
    return obj


def read_json(pad: Path, fouten: Fouten, houd_uitleg: bool = False):
    """Leest een JSON-bestand; een leesfout wordt een melding in gewone taal, geen crash."""
    naam = str(pad.relative_to(ROOT))
    try:
        tekst = pad.read_text(encoding="utf-8")
        data = json.loads(tekst)
    except json.JSONDecodeError as fout:
        fouten.melden(naam, "ongeldige JSON", explain_json_error(fout, tekst))
        return None
    except OSError as fout:
        fouten.melden(naam, "bestand", f"kan het bestand niet lezen ({fout.strerror}).")
        return None
    return data if houd_uitleg else strip_notes(data)


def check_fields(obj, toegestaan: list[str], verplicht: list[str], bestand: str, plek: str, fouten: Fouten) -> bool:
    """Controleert dat obj een mapping is, verplichte velden heeft en geen onbekende velden."""
    if not isinstance(obj, dict):
        fouten.melden(bestand, plek, "hier hoort een blok met velden te staan, maar dit is iets anders.")
        return False
    for veld in verplicht:
        if obj.get(veld) is None:
            fouten.melden(bestand, f"{plek}, veld '{veld}'", "ontbreekt of is leeg, maar is verplicht.")
    for veld in obj:
        if veld not in toegestaan:
            fouten.melden(bestand, f"{plek}, veld '{veld}'", f"onbekend veld; toegestaan: {', '.join(toegestaan)}. Typfout in de veldnaam?")
    return True


def check_choice(waarde, opties: list[str], bestand: str, plek: str, fouten: Fouten) -> None:
    if waarde is not None and waarde not in opties:
        fouten.melden(bestand, plek, f"waarde '{waarde}' is niet toegestaan; kies uit: {', '.join(opties)}.")


def check_number(waarde, bestand: str, plek: str, fouten: Fouten, geheel: bool = False) -> None:
    ok = isinstance(waarde, (int, float)) and not isinstance(waarde, bool) and waarde >= 0
    if ok and geheel:
        ok = isinstance(waarde, int)
    if not ok:
        soort = "een geheel getal" if geheel else "een getal (decimalen met een punt, bijvoorbeeld 0.5)"
        fouten.melden(bestand, plek, f"moet {soort} zijn, nu: '{waarde}'.")


def check_ids(ids, bestaande: set, bestand: str, plek: str, fouten: Fouten) -> None:
    if not isinstance(ids, list):
        fouten.melden(bestand, plek, "moet een lijst zijn, bijvoorbeeld [a, b].")
        return
    for i in ids:
        if i not in bestaande:
            fouten.melden(bestand, plek, f"'{i}' bestaat niet. Voeg het eerst toe of corrigeer de schrijfwijze.")


def get_need_id(item) -> str | None:
    """heeft_nodig kent twee vormen: kale id of { id, waarom }."""
    return item.get("id") if isinstance(item, dict) else item


def check_config(config, fouten: Fouten) -> None:
    b = "model/config.json"
    if not check_fields(config, CONFIG_VELDEN + CONFIG_OPTIONEEL, CONFIG_VELDEN, b, "bovenaan", fouten):
        return
    check_choice(config.get("taal"), TALEN, b, "veld 'taal'", fouten)
    if config.get("titel") is not None and not isinstance(config["titel"], str):
        fouten.melden(b, "veld 'titel'", "moet tekst zijn, bijvoorbeeld \"Flow-overzicht\".")
    for veld in ["werkdagen_per_jaar", "werkweken_per_jaar", "maanden_per_jaar", "uren_per_fte"]:
        if veld in config:
            check_number(config[veld], b, f"veld '{veld}'", fouten)
    for veld in ["fte_rollen", "rollen"]:
        if not isinstance(config.get(veld), list):
            fouten.melden(b, f"veld '{veld}'", "moet een lijst zijn, bijvoorbeeld [engineer].")
    if isinstance(config.get("rollen"), list) and isinstance(config.get("fte_rollen"), list):
        for r in config["fte_rollen"]:
            if r not in config["rollen"]:
                fouten.melden(b, "veld 'fte_rollen'", f"'{r}' staat niet in de lijst 'rollen'.")


def check_people(mensen, fouten: Fouten) -> set:
    b = "model/mensen.json"
    if not isinstance(mensen, list):
        fouten.melden(b, "bovenaan", "moet een lijst zijn van blokken met elk een 'id'.")
        return set()
    ids: set = set()
    for n, m in enumerate(mensen, 1):
        plek = f"mens {n}"
        if check_fields(m, ["id", "naam", "rol"], ["id", "naam", "rol"], b, plek, fouten):
            if m.get("id") in ids:
                fouten.melden(b, plek, f"id '{m.get('id')}' komt twee keer voor.")
            ids.add(m.get("id"))
    return ids


def check_step(stap, wie_ok: set, bestand: str, plek: str, fouten: Fouten) -> None:
    if not check_fields(stap, STAP_VELDEN, ["naam", "wie", "soort", "uren"], bestand, plek, fouten):
        return
    check_choice(stap.get("soort"), STAP_SOORTEN, bestand, f"{plek}, veld 'soort'", fouten)
    if "uren" in stap:
        check_number(stap["uren"], bestand, f"{plek}, veld 'uren'", fouten)
    if stap.get("wie") is not None and stap["wie"] not in wie_ok:
        fouten.melden(bestand, f"{plek}, veld 'wie'", f"'{stap['wie']}' is geen mens, afhankelijkheid of rol uit config.json.")
    if "meetpunt" in stap:
        check_fields(stap["meetpunt"], MEETPUNT_VELDEN, ["systeem", "veld"], bestand, f"{plek}, veld 'meetpunt'", fouten)
    if "afhankelijkheden" in stap:
        if not isinstance(stap["afhankelijkheden"], list):
            fouten.melden(bestand, f"{plek}, veld 'afhankelijkheden'", "moet een lijst van afhankelijkheid-ids zijn.")
        else:
            for dep_id in stap["afhankelijkheden"]:
                if dep_id not in wie_ok:
                    fouten.melden(bestand, f"{plek}, veld 'afhankelijkheden'", f"'{dep_id}' staat niet in afhankelijkheden.json.")


def check_maintenance(onderhoud, ids: dict, bestand: str, plek: str, fouten: Fouten) -> None:
    if not check_fields(onderhoud, ONDERHOUD_VELDEN, ["uren_per_maand"], bestand, plek, fouten):
        return
    if "uren_per_maand" in onderhoud:
        check_number(onderhoud["uren_per_maand"], bestand, f"{plek}, veld 'uren_per_maand'", fouten)
    for n, st in enumerate(onderhoud.get("stappen") or [], 1):
        check_step(st, ids["wie"], bestand, f"{plek}, onderhoudsstap {n}", fouten)
    if "afhankelijkheden" in onderhoud:
        check_ids(onderhoud["afhankelijkheden"], ids["deps"], bestand, f"{plek}, veld 'afhankelijkheden'", fouten)
    if "kennis" in onderhoud:
        check_ids(onderhoud["kennis"], ids["mensen"], bestand, f"{plek}, veld 'kennis'", fouten)


def check_version(versie, n: int, ids: dict, bestand: str, fouten: Fouten) -> None:
    plek = f"versie {n}"
    if not check_fields(versie, VERSIE_VELDEN, ["versie", "naam", "status", "stappen"], bestand, plek, fouten):
        return
    check_choice(versie.get("status"), VERSIE_STATUSSEN, bestand, f"{plek}, veld 'status'", fouten)
    if "onderhoud" in versie:
        check_maintenance(versie["onderhoud"], ids, bestand, f"{plek}, veld 'onderhoud'", fouten)
    stappen = versie.get("stappen")
    if not isinstance(stappen, list) or not stappen:
        fouten.melden(bestand, f"{plek}, veld 'stappen'", "moet minstens één stap bevatten.")
        return
    for i, st in enumerate(stappen, 1):
        check_step(st, ids["wie"], bestand, f"{plek}, stap {i}", fouten)


def check_flow(flow, bestandspad: Path, ids: dict, fouten: Fouten) -> None:
    b = str(bestandspad.relative_to(ROOT))
    verplicht = ["id", "naam", "soort", "doel", "versies"]
    if not check_fields(flow, FLOW_VELDEN, verplicht, b, "bovenaan", fouten):
        return
    if flow.get("id") != bestandspad.stem:
        fouten.melden(b, "veld 'id'", f"'{flow.get('id')}' moet gelijk zijn aan de bestandsnaam '{bestandspad.stem}'.")
    check_choice(flow.get("soort"), FLOW_SOORTEN, b, "veld 'soort'", fouten)
    if "prio" in flow:
        check_number(flow["prio"], b, "veld 'prio'", fouten, geheel=True)
    if flow.get("soort") == "flow":
        freq = flow.get("frequentie")
        if check_fields(freq, ["aantal", "per"], ["aantal", "per"], b, "veld 'frequentie'", fouten):
            check_number(freq.get("aantal"), b, "veld 'frequentie', aantal", fouten)
            check_choice(freq.get("per"), FREQUENTIE_PER, b, "veld 'frequentie', per", fouten)
    if "afhankelijkheden" in flow:
        check_ids(flow["afhankelijkheden"], ids["deps"], b, "veld 'afhankelijkheden'", fouten)
    if isinstance(flow.get("heeft_nodig"), list):
        for item in flow["heeft_nodig"]:
            if isinstance(item, dict):
                check_fields(item, ["id", "waarom"], ["id"], b, "veld 'heeft_nodig'", fouten)
        check_ids([get_need_id(i) for i in flow["heeft_nodig"]], ids["flows"], b, "veld 'heeft_nodig'", fouten)
    elif "heeft_nodig" in flow:
        fouten.melden(b, "veld 'heeft_nodig'", "moet een lijst zijn, bijvoorbeeld [\"F1\", \"F2\"] of [].")
    versies = flow.get("versies")
    if not isinstance(versies, list) or not versies:
        fouten.melden(b, "veld 'versies'", "moet minstens één versie bevatten.")
        return
    for n, v in enumerate(versies, 1):
        check_version(v, n, ids, b, fouten)
    nummers = [v.get("versie") for v in versies if isinstance(v, dict)]
    if len(nummers) != len(set(nummers)):
        fouten.melden(b, "veld 'versies'", "twee versies hebben hetzelfde versienummer.")


def check_dependencies(deps, ids_mensen: set, wie_ok_rollen: set, fouten: Fouten) -> dict:
    b = "model/afhankelijkheden.json"
    if not isinstance(deps, list):
        fouten.melden(b, "bovenaan", "moet een lijst zijn van blokken met elk een 'id'.")
        return {}
    gezien: set = set()
    for n, d in enumerate(deps, 1):
        plek = f"afhankelijkheid {n}"
        if not check_fields(d, DEP_VELDEN, ["id", "naam", "type", "kennis"], b, plek, fouten):
            continue
        if d.get("id") in gezien:
            fouten.melden(b, plek, f"id '{d.get('id')}' komt twee keer voor.")
        gezien.add(d.get("id"))
        check_choice(d.get("type"), DEP_TYPEN, b, f"{plek} ({d.get('id')}), veld 'type'", fouten)
        check_ids(d.get("kennis"), ids_mensen, b, f"{plek} ({d.get('id')}), veld 'kennis'", fouten)
        if "extern" in d and not isinstance(d["extern"], bool):
            fouten.melden(b, f"{plek} ({d.get('id')}), veld 'extern'", "moet true zijn of weggelaten worden.")
        if "onderhoud" in d and check_fields(d["onderhoud"], ["uren_per_maand"], ["uren_per_maand"], b, f"{plek}, veld 'onderhoud'", fouten):
            check_number(d["onderhoud"].get("uren_per_maand"), b, f"{plek}, veld 'onderhoud'", fouten)
    return {d["id"]: d for d in deps if isinstance(d, dict) and "id" in d}


def get_list_from(data, sleutel: str, bestand: str, fouten: Fouten):
    """mensen.json en afhankelijkheden.json zijn een blok met de lijst onder één sleutel."""
    if data is None:
        return None
    if not isinstance(data, dict) or not isinstance(data.get(sleutel), list):
        fouten.melden(bestand, "bovenaan", f"er hoort een blok te staan met daarin het veld '{sleutel}' (een lijst).")
        return None
    return data[sleutel]


def load_flows(fouten: Fouten) -> list[tuple[Path, object]]:
    pads = sorted(p for p in (MODEL / "flows").glob("*.json") if not p.name.startswith("_"))
    if not pads:
        fouten.melden("model/flows", "map", "er staat geen enkel flow-bestand (.json) in.")
    return [(p, read_json(p, fouten)) for p in pads]


def fill_defaults(flow: dict) -> dict:
    """Weggelaten optionele velden krijgen hier hun standaardwaarde, zodat de pagina niets hoeft te raden."""
    flow = {"groep": "", "tekening": "", "prio": None, "heeft_nodig": [], "afhankelijkheden": [], **flow}
    for v in flow["versies"]:
        v.setdefault("bron", "")
        v.setdefault("onderhoud", {"uren_per_maand": 0, "stappen": []})
    return flow


def build_bord(config, mensen, deps, flows) -> dict:
    return {"config": config, "mensen": mensen, "afhankelijkheden": deps, "flows": flows,
            "versie": BORD_VERSIE, "gegenereerd": datetime.now().astimezone().isoformat(timespec="seconds"), "bron": "model/"}


def write_bord(bord: dict) -> None:
    UITVOER.parent.mkdir(parents=True, exist_ok=True)
    tekst = json.dumps(bord, ensure_ascii=False, indent=1)
    UITVOER.write_text(f"{KOPREGEL}\nwindow.FLOW_BORD = {tekst};\n", encoding="utf-8")


COMPACT_LIST_KEYS = {"stappen", "mensen", "afhankelijkheden"}   # elk object in deze lijsten op één regel


def is_scalar(waarde) -> bool:
    return not isinstance(waarde, (dict, list))


def is_flat(obj: dict) -> bool:
    """Een blok zonder toelichting en zonder geneste blokken past op één regel."""
    return not any(str(k).startswith("_") for k in obj) and all(
        is_scalar(v) or (isinstance(v, list) and all(is_scalar(x) for x in v)) for v in obj.values())


def format_json(obj, niveau: int = 0, sleutel: str = "", compact: bool = False) -> str:
    """Vaste nette vorm: 2 spaties inspringing, tijdlijn-stappen en register-regels op één regel."""
    pad, kind = "  " * (niveau + 1), "  " * niveau
    if is_scalar(obj) or (isinstance(obj, dict) and (compact or is_flat(obj))) or (
            isinstance(obj, list) and (compact or all(is_scalar(x) for x in obj)) and not (
            sleutel.startswith("_") and len(obj) > 1)):
        return json.dumps(obj, ensure_ascii=False)
    if isinstance(obj, list):
        if not obj:
            return "[]"
        kinderen = [pad + format_json(x, niveau + 1, sleutel, sleutel in COMPACT_LIST_KEYS) for x in obj]
        return "[\n" + ",\n".join(kinderen) + "\n" + kind + "]"
    if not obj:
        return "{}"
    kinderen = [f"{pad}{json.dumps(k, ensure_ascii=False)}: {format_json(v, niveau + 1, k, False)}" for k, v in obj.items()]
    return "{\n" + ",\n".join(kinderen) + "\n" + kind + "}"


def list_model_files() -> list[Path]:
    return [MODEL / "config.json", MODEL / "mensen.json", MODEL / "afhankelijkheden.json",
            *sorted((MODEL / "flows").glob("*.json"))]


def format_model_files() -> int:
    """--formatteer: schrijft elk model-bestand terug in vaste nette vorm."""
    fouten = Fouten()
    nieuw = {}
    for pad in list_model_files():
        data = read_json(pad, fouten, houd_uitleg=True)
        if data is not None:
            nieuw[pad] = format_json(data) + "\n"
    if fouten.lijst:
        return report(fouten, "niets herschreven")
    for pad, tekst in nieuw.items():
        pad.write_text(tekst, encoding="utf-8")
    print(f"geformatteerd: {len(nieuw)} bestanden in model/")
    return 0


def list_names() -> int:
    """--lijst: toont in gewone taal welke ids en rollen bestaan; schrijft niets."""
    fouten = Fouten()
    config = read_json(MODEL / "config.json", fouten)
    mensen = get_list_from(read_json(MODEL / "mensen.json", fouten), "mensen", "model/mensen.json", fouten)
    deps = get_list_from(read_json(MODEL / "afhankelijkheden.json", fouten), "afhankelijkheden", "model/afhankelijkheden.json", fouten)
    flows = [(p, read_json(p, fouten)) for p in sorted((MODEL / "flows").glob("*.json")) if not p.name.startswith("_")]
    if fouten.lijst:
        return report(fouten, "geen lijst getoond")
    print("FLOWS EN TAKEN (id, prio, naam; bruikbaar bij 'heeft_nodig'):")
    for p, f in sorted(flows, key=lambda x: (x[1].get("prio", 10**9), x[0].stem)):
        print(f"  {p.stem:<8} prio {f.get('prio', '–')}  {f.get('naam')}")
    print("\nMENSEN (mens-id, naam, rol; bruikbaar bij 'wie' en 'kennis'):")
    for m in mensen:
        print(f"  {m['id']:<10} {m['naam']}, {m['rol']}")
    print("\nAFHANKELIJKHEDEN (id, naam, extern; bruikbaar bij 'afhankelijkheden' en 'wie'):")
    for d in deps:
        print(f"  {d['id']:<18} {d['naam']}  [extern: {'ja' if d.get('extern') else 'nee'}]")
    print("\nROLLEN (bruikbaar bij 'wie'):", ", ".join(config.get("rollen", [])))
    print("ROLLEN DIE MEETELLEN ALS AFDELINGSTIJD (fte_rollen):", ", ".join(config.get("fte_rollen", [])))
    return 0


def main(alleen_controleren: bool = False) -> int:
    fouten = Fouten()
    config = read_json(MODEL / "config.json", fouten)
    mensen = get_list_from(read_json(MODEL / "mensen.json", fouten), "mensen", "model/mensen.json", fouten)
    deps = get_list_from(read_json(MODEL / "afhankelijkheden.json", fouten), "afhankelijkheden", "model/afhankelijkheden.json", fouten)
    flow_data = load_flows(fouten)
    if fouten.lijst:                       # leesfouten: verder controleren heeft geen zin
        return report(fouten)
    check_config(config, fouten)
    mens_ids = check_people(mensen, fouten)
    dep_map = check_dependencies(deps, mens_ids, set(config.get("rollen", [])), fouten)
    ids = {"mensen": mens_ids, "deps": set(dep_map),
           "flows": {p.stem for p, _ in flow_data},
           "wie": mens_ids | set(dep_map) | set(config.get("rollen") or [])}
    for pad, flow in flow_data:
        check_flow(flow, pad, ids, fouten)
    if fouten.lijst:
        return report(fouten)
    if alleen_controleren:
        print(f"gelukt (alleen controle, data/bord.js niet geschreven): {len(flow_data)} flows, {len(deps)} afhankelijkheden, {len(mensen)} mensen")
        return 0
    write_bord(build_bord(config, mensen, deps, [fill_defaults(f) for _, f in flow_data]))
    print(f"gelukt: {len(flow_data)} flows, {len(deps)} afhankelijkheden, {len(mensen)} mensen -> {UITVOER.relative_to(ROOT)}")
    return 0


def report(fouten: Fouten, gevolg: str = "data/bord.js is niet bijgewerkt") -> int:
    print(f"{len(fouten.lijst)} fout(en) in de JSON; {gevolg}:", file=sys.stderr)
    for regel in fouten.lijst:
        print(f" - {regel}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    args = sys.argv[1:]
    sys.exit(format_model_files() if "--formatteer" in args else list_names() if "--lijst" in args else main("--controleer" in args))
