# cockpit tool

A static web page (the shell) plus a script that publishes pages into it. No backend, no build step, no external requests.

## Layout

```
tool/
  site/
    index.html        the shell: focus panel (iframe) and page list
    artifacts.json    the manifest the shell reads; starts as []
    config.json       optional: title and subtitle of the shell
  scripts/
    New-Artifact.ps1  generator, PowerShell 7
    new_artifact.py   generator, Python 3 (standard library only)
    page-template.html  the page template both generators share
```

Published pages land next to `index.html`, in `site/`. Serve `site/` and you are done.

## Serve it

Any static web server works. For a quick look:

```bash
cd site && python3 -m http.server 8900 --bind 127.0.0.1
```

Then open `http://127.0.0.1:8900/`. For something permanent, an nginx `location`:

```nginx
location /cockpit/ {
    alias /srv/cockpit/site/;
    index index.html;
    add_header Cache-Control "no-store";
}
```

The shell fetches `artifacts.json` with `cache: no-store`, so a new page shows up on the next load without clearing a cache.

## Publish a page

PowerShell:

```powershell
./scripts/New-Artifact.ps1 -Title 'Disk report' -BodyHtml '<p>Host <span class="id">web01</span> is at 91%.</p>'
./scripts/New-Artifact.ps1 -Title 'Long report' -BodyFile ./report-fragment.html -BaseUrl 'http://myserver/cockpit'
```

Python:

```bash
python3 scripts/new_artifact.py --title "Disk report" --body-html '<p>Host <span class="id">web01</span> is at 91%.</p>'
python3 scripts/new_artifact.py --title "Long report" --body-file report-fragment.html --base-url http://myserver/cockpit
```

| PowerShell | Python | Meaning |
|---|---|---|
| `-Title` | `--title` | Required. Heading, browser tab, list entry. |
| `-BodyHtml` | `--body-html` | HTML fragment for the page body. |
| `-BodyFile` | `--body-file` | Path to a file with that fragment. Use it for long content. Give either this or the one above. |
| `-Name` | `--name` | Slug for the file name. Default: derived from the title. |
| `-SiteRoot` | `--site-root` | Folder with `index.html` and `artifacts.json`. Default: `../site` next to the scripts. |
| `-BaseUrl` | `--base-url` | Empty: print the file path. Set: print `<BaseUrl>/<slug>.html`. |

The script prints one line (path or URL) and exits 0. On an error it prints a message to stderr and exits 1. Publishing the same slug again replaces the page and its list entry. Pages and manifest are written to a temp file first and renamed, so the shell never reads a half-written file.

## Manifest schema

`artifacts.json` is a JSON array, newest first:

```json
[
  {"slug": "disk-report", "title": "Disk report", "file": "disk-report.html", "generated": "2026-11-09T16:00:48"}
]
```

| Field | Meaning |
|---|---|
| `slug` | Unique key. Publishing the same slug again replaces the entry. |
| `title` | Shown in the list. The shell writes it as plain text. |
| `file` | Path of the page relative to `index.html`. |
| `generated` | Local time, always `yyyy-MM-ddTHH:mm:ss`. |

The shell selects the first entry on load and marks it `new`.

## Shell config

`site/config.json` is optional:

```json
{"title": "Cockpit", "subtitle": ""}
```

Without the file the shell shows "Cockpit".

## Readability classes

Pages get a dark theme, a 62-character reading column and these classes. Use them in the body you pass in.

| Class | Use | Example |
|---|---|---|
| `.id` | Identifiers: hostnames, hashes, keys. Monospace, slashed zero, digits and letters coloured differently so `O` and `0` never blur. | `<span class="id">web01-a7f3</span>` |
| `.kw` | The one key word of a paragraph. Use sparingly; if everything is highlighted, nothing is. | `<p>The backup <span class="kw">failed</span> twice.</p>` |
| `.question` | A block that asks the reader something. Gets the label QUESTION. | `<div class="question">Restart the service now?</div>` |
| `.meta` | Small grey line, for dates or sources. | `<div class="meta">Source: nightly run</div>` |
| `table` | Styled automatically. | `<table><tr><th>Host</th><th>Disk</th></tr><tr><td>web01</td><td>91%</td></tr></table>` |
| `pre` / `code` | Code blocks and inline code. | `<pre><code>df -h</code></pre>` |
| `img` | Click an image to open the bare file in a new tab and zoom freely. | `<img src="chart.png" alt="Disk use">` |

Images and other assets are your own files: put them in `site/` and reference them relatively.

## Limits

- **No sanitising.** The body you pass is written into the page as it is. Only put in content you wrote. Never paste raw external text (web pages, emails, tool output from untrusted sources) into `BodyHtml` without escaping it first.
- **No backend, no auth.** The cockpit is static files. Anyone who can reach the server can read every page. Put it behind your own access rules, and do not publish secrets.
- **No delete command.** To remove a page, delete the file and its entry in `artifacts.json`.
