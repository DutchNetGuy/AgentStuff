#!/usr/bin/env python3
"""Publish content as a self-contained HTML page and add it to the cockpit manifest.

Writes <site-root>/<slug>.html from page-template.html and upserts an entry in
<site-root>/artifacts.json (newest first). Both files are written atomically, so the
shell never reads a half-written file. Prints one line: the file path, or the URL when
--base-url is given. Exit 0 on success, 1 on any error.

Example:
    python3 new_artifact.py --title "Disk report" \
        --body-html '<p>Host <span class="id">web01</span> is at 91%.</p>'
"""
import argparse
import html
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent


@dataclass
class ArtifactResult:
    """Outcome of one publish: what to print, where the file is, which slug was used."""
    location: str
    path: Path
    slug: str


def convert_to_slug(text: str) -> str:
    """Turn free text into a safe file-name stem: lowercase, only [a-z0-9-], may be empty."""
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def build_html(title: str, body_html: str, generated: str) -> str:
    """Fill page-template.html with title, date and body."""
    template = (SCRIPT_DIR / "page-template.html").read_text(encoding="utf-8")
    shown_date = generated.replace("T", " ")[:16]
    # Body goes in last so placeholders inside the body are never expanded.
    return (template.replace("{{TITLE}}", html.escape(title))
            .replace("{{DATE}}", shown_date)
            .replace("{{BODY}}", body_html))


def write_file_atomic(path: Path, content: str) -> Path:
    """Write to a temp file in the same folder, then rename it over the target."""
    path = path.resolve()
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
        os.chmod(temp, 0o644)  # mkstemp creates 0600; a web server needs to read the file
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    return path


def update_manifest(site_root: Path, slug: str, title: str, generated: str) -> Path:
    """Upsert one entry in artifacts.json, newest first, atomically.

    An entry with the same slug is replaced. A manifest that exists but is not a JSON
    array raises an error instead of being overwritten.
    """
    manifest_path = site_root / "artifacts.json"
    existing = []
    if manifest_path.exists():
        raw = manifest_path.read_text(encoding="utf-8")
        if raw.strip():
            existing = json.loads(raw)
            if not isinstance(existing, list):
                raise ValueError(f"artifacts.json is not a JSON array: {manifest_path}")
    kept = [e for e in existing if e.get("slug") != slug]
    entry = {"slug": slug, "title": title, "file": f"{slug}.html", "generated": generated}
    text = json.dumps([entry] + kept, indent=2, ensure_ascii=False) + "\n"
    return write_file_atomic(manifest_path, text)


def new_artifact(title: str, body_html: str, name: str, site_root: Path,
                 base_url: str = "") -> ArtifactResult:
    """Recipe: slug -> HTML -> write page -> update manifest -> report location."""
    slug = convert_to_slug(name)
    if not slug:
        raise ValueError(f"Cannot derive a slug from '{name}'. Pass --name with letters or digits.")
    site_root.mkdir(parents=True, exist_ok=True)

    generated = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    page = build_html(title, body_html, generated)
    path = write_file_atomic(site_root / f"{slug}.html", page)
    update_manifest(site_root, slug, title, generated)
    location = f"{base_url.rstrip('/')}/{slug}.html" if base_url else str(path)
    return ArtifactResult(location=location, path=path, slug=slug)


def parse_args(argv):
    """Define and parse the command line."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--title", required=True, help="page title")
    body = parser.add_mutually_exclusive_group(required=True)
    body.add_argument("--body-html", help="page content as an HTML fragment (not sanitised)")
    body.add_argument("--body-file", help="path to a file holding the HTML fragment")
    parser.add_argument("--name", help="slug for the file name (default: derived from the title)")
    parser.add_argument("--site-root", default=str(SCRIPT_DIR.parent / "site"),
                        help="folder with index.html and artifacts.json (default: ../site)")
    parser.add_argument("--base-url", default="",
                        help="URL under which the site root is served (default: print the file path)")
    return parser.parse_args(argv)


def main(argv=None) -> int:
    """Entrypoint: print the location of the new page; return the exit code."""
    args = parse_args(argv)
    try:
        if args.body_file:
            body_html = Path(args.body_file).read_text(encoding="utf-8")
        else:
            body_html = args.body_html
        result = new_artifact(args.title, body_html, args.name or args.title,
                              Path(args.site_root), args.base_url)
        print(result.location)
        return 0
    except (OSError, ValueError) as error:
        print(f"new_artifact failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
