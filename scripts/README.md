# Scripts

Two equivalent scripts build the package index from the manifests. Run either one; the output is the same.

| Script | Run with | Needs |
|---|---|---|
| `Build-Index.ps1` | `pwsh scripts/Build-Index.ps1` | PowerShell 7 or newer |
| `build_index.py` | `python3 scripts/build_index.py` | Python 3.9 or newer, standard library only |

Both accept an optional repository root as the only argument (`-RepoRoot` in PowerShell). The default is the folder above `scripts/`, so you can run them from any directory.

## What they do

1. Read every `packages/*/manifest.json`.
2. Validate the required fields from `docs/package-format.md`, that `type` is `skill`, `agent` or `addition`, that `name` equals the folder name, and that the folder in `install.source` exists.
3. Write `index/catalog.json` and `index/catalog.md`, sorted by package name.

If any manifest is invalid, the scripts print every problem with the package and field, exit with code 1 and write nothing.

## Identical output

The two scripts must produce byte-identical files. To make that hold, the PowerShell script serialises the JSON itself instead of using `ConvertTo-Json`, so the text equals Python's `json.dumps(obj, indent=2, ensure_ascii=False)`.

To check after a change, run one script, copy `index/` elsewhere, run the other and compare with `diff -r`. The `generated` date is the local date, so run both on the same day.

Never edit the files in `index/` by hand; change a manifest and regenerate.
