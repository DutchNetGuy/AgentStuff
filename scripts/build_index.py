#!/usr/bin/env python3
"""Build index/catalog.json and index/catalog.md from packages/*/manifest.json.

Usage: python3 scripts/build_index.py [REPO_ROOT]

Exits 1 with a clear message (package and field) when a manifest is invalid,
and writes nothing in that case. The output is byte-identical to Build-Index.ps1.
"""
from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any

VALID_TYPES = ("skill", "agent", "addition", "tool")

# Required fields from docs/package-format.md; dotted names are nested.
REQUIRED_STRINGS = (
    "name", "type", "version", "summary", "problem",
    "install.source", "install.target",
    "docs.readme", "docs.readme_nl", "docs.flow",
    "origin.author", "origin.generalised_from", "origin.first_published",
)
REQUIRED_LISTS = ("triggers", "compatible_with")


@dataclass(frozen=True)
class Manifest:
    folder: str
    data: dict[str, Any]


@dataclass(frozen=True)
class CatalogEntry:
    name: str
    type: str
    version: str
    summary: str
    problem: str
    triggers: list[str]
    path: str


def get_repo_root(argv: list[str]) -> Path:
    """Return the repo root: first argument, or the folder above scripts/."""
    if len(argv) > 1:
        return Path(argv[1]).resolve()
    return Path(__file__).resolve().parent.parent


def read_manifests(root: Path, errors: list[str]) -> list[Manifest]:
    """Read every packages/*/manifest.json; unreadable ones add an error."""
    manifests: list[Manifest] = []
    for path in sorted((root / "packages").glob("*/manifest.json")):
        folder = path.parent.name
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            errors.append(f"package '{folder}': manifest.json cannot be read: {exc}")
            continue
        if not isinstance(data, dict):
            errors.append(f"package '{folder}': manifest.json must contain a JSON object")
            continue
        manifests.append(Manifest(folder, data))
    return manifests


def get_field_value(data: dict[str, Any], dotted: str) -> Any:
    """Return the value of a (possibly nested) field, or None when absent."""
    value: Any = data
    for part in dotted.split("."):
        if not isinstance(value, dict) or part not in value:
            return None
        value = value[part]
    return value


def test_manifest(root: Path, manifest: Manifest) -> list[str]:
    """Return the validation errors of one manifest (empty list = valid)."""
    folder, data = manifest.folder, manifest.data
    errors: list[str] = []
    for field in REQUIRED_STRINGS:
        value = get_field_value(data, field)
        if value is None or str(value).strip() == "":
            errors.append(f"package '{folder}': required field '{field}' is missing or empty")
    for field in REQUIRED_LISTS:
        if not isinstance(get_field_value(data, field), list):
            errors.append(f"package '{folder}': required field '{field}' is missing or not a list")
    if data.get("type") not in VALID_TYPES:
        errors.append(f"package '{folder}': field 'type' must be one of {', '.join(VALID_TYPES)}")
    if data.get("name") != folder:
        errors.append(f"package '{folder}': field 'name' must equal the folder name")
    source = get_field_value(data, "install.source")
    if isinstance(source, str) and source.strip() and not (root / "packages" / folder / source).is_dir():
        errors.append(f"package '{folder}': field 'install.source' points to a folder that does not exist: {source}")
    return errors


def test_manifests(root: Path, manifests: list[Manifest]) -> list[str]:
    """Validate all manifests and return every error found."""
    errors: list[str] = []
    for manifest in manifests:
        errors.extend(test_manifest(root, manifest))
    return errors


def build_catalog(manifests: list[Manifest]) -> list[CatalogEntry]:
    """Turn manifests into catalog entries, sorted by name."""
    entries = [
        CatalogEntry(
            name=m.data["name"],
            type=m.data["type"],
            version=m.data["version"],
            summary=m.data["summary"],
            problem=m.data["problem"],
            triggers=list(m.data["triggers"]),
            path=f"packages/{m.data['name']}/",
        )
        for m in manifests
    ]
    return sorted(entries, key=lambda e: e.name)


def get_catalog_json(entries: list[CatalogEntry], generated: str) -> str:
    """Return the catalog as JSON text: 2-space indent, utf8, trailing newline."""
    document = {
        "generated": generated,
        "packages": [
            {
                "name": e.name, "type": e.type, "version": e.version,
                "summary": e.summary, "problem": e.problem,
                "triggers": e.triggers, "path": e.path,
            }
            for e in entries
        ],
    }
    return json.dumps(document, indent=2, ensure_ascii=False) + "\n"


def get_table_cell(text: str) -> str:
    """Escape a value for use inside a Markdown table cell."""
    return text.replace("|", "\\|")


def get_catalog_markdown(entries: list[CatalogEntry], generated: str) -> str:
    """Return the catalog as a Markdown table for people."""
    lines = [
        "# Catalog",
        "",
        f"Generated {generated} from the package manifests. Do not edit by hand; "
        "change a manifest and run `scripts/build_index.py` or `scripts/Build-Index.ps1`.",
        "",
        "| Package | Type | Version | Problem it solves | Triggers |",
        "|---|---|---|---|---|",
    ]
    for e in entries:
        lines.append(
            f"| [{get_table_cell(e.name)}](../packages/{e.name}/README.md) | {get_table_cell(e.type)} "
            f"| {get_table_cell(e.version)} | {get_table_cell(e.problem)} "
            f"| {get_table_cell(', '.join(e.triggers))} |"
        )
    return "\n".join(lines) + "\n"


def write_index_files(root: Path, json_text: str, markdown_text: str) -> None:
    """Write index/catalog.json and index/catalog.md (utf8, LF)."""
    index_dir = root / "index"
    index_dir.mkdir(exist_ok=True)
    (index_dir / "catalog.json").write_bytes(json_text.encode("utf-8"))
    (index_dir / "catalog.md").write_bytes(markdown_text.encode("utf-8"))


def main(argv: list[str]) -> int:
    """Recipe: read manifests, validate, build catalog, write json, write markdown."""
    root = get_repo_root(argv)
    errors: list[str] = []
    manifests = read_manifests(root, errors)
    errors.extend(test_manifests(root, manifests))
    if errors:
        print("Index not built, nothing written:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    generated = date.today().isoformat()
    entries = build_catalog(manifests)
    write_index_files(root, get_catalog_json(entries, generated),
                      get_catalog_markdown(entries, generated))
    print(f"Wrote index/catalog.json and index/catalog.md ({len(entries)} package(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
