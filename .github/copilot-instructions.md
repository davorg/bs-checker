# Copilot Instructions for bs-checker

## Project Overview

**bs-checker** is a Perl-based command-line tool that scans a list of URLs to detect which version of the Bootstrap CSS framework each website is using. Results are serialised as JSON and published via GitHub Pages as a simple HTML dashboard.

## Tech Stack

- **Language:** Perl 5.36+ (uses the experimental `class`, `try/catch`, and `say` features)
- **Key CPAN modules:** `JSON`, `Web::Query` (HTML parsing), `LWP::Protocol::https`, `IO::Socket::SSL`, `Net::SSLeay`, `Module::Build::Tiny`
- **Package manager:** `cpanminus` (`cpanm`)
- **Dependency declaration:** `cpanfile`
- **Frontend:** Vanilla HTML + JavaScript, Bootstrap 5.3.2 CSS (static site hosted on GitHub Pages)
- **CI/CD:** GitHub Actions

## Directory Structure

```
.github/
  dependabot.yml          # Weekly checks for GitHub Actions updates
  workflows/
    build.yml             # CI/CD: install deps, run checker, deploy to Pages
bin/
  bs-checker              # CLI entry point – reads URLs from stdin/file
lib/
  BS_Checker.pm           # Core OOP module (class BS_Checker)
docs/
  index.html              # Web dashboard (fetches bs.json at runtime)
  bs.json                 # Generated output – committed after each run
cpanfile                  # CPAN dependency list
urls                      # Newline-separated list of sites to scan
README.md
```

## How to Build and Run

### Prerequisites

- Perl 5.36 or newer (required for `use feature 'class'` and `use experimental 'try'`)
- `cpanminus` installed (`sudo apt-get install cpanminus` on Debian/Ubuntu)

### Install dependencies

```bash
cpanm --sudo --installdeps -n .
```

> **Note:** `Module::Build::Tiny` version `0.049` is explicitly excluded in `cpanfile` due to a known bug — `cpanm` will install the nearest compatible version automatically.

### Run the checker

```bash
PERL5LIB=lib bin/bs-checker urls > docs/bs.json
```

- `bin/bs-checker` reads URLs from a file (or stdin).
- Lines that do **not** start with `http` (e.g. blank lines or `#` comments) are silently ignored.
- Output is pretty-printed JSON written to stdout; redirect it to `docs/bs.json`.

### Output format

```json
{
   "5.3.2" : [ "https://example.com", "https://example.org" ],
   "4.6.0" : [ "https://another.example" ],
   "errors" : [
      { "url" : "https://broken.example", "error" : "500 Internal Server Error" }
   ]
}
```

URLs are sorted alphabetically within each version bucket.  
Sites where Bootstrap was detected but no version string could be extracted appear under version `0.0.0`.  
Sites that could not be fetched or parsed at all appear in the `errors` array.

## How to Test

There is **no automated test suite** in this repository. Validation is done manually:

1. Run the checker against the `urls` file and inspect the resulting `docs/bs.json`.
2. Open `docs/index.html` in a browser (serve locally if needed) to verify the dashboard renders correctly.

If you add tests, use standard Perl TAP (`*.t` files under a `t/` directory) and run them with:

```bash
prove -l t/
```

## CI/CD Pipeline

The workflow in `.github/workflows/build.yml` does the following:

1. Installs `cpanminus` from the system package manager.
2. Installs CPAN dependencies via `cpanm --sudo --installdeps -n .`.
3. Runs the checker: `bin/bs-checker urls > docs/bs.json`.
4. Uploads `docs/` as a GitHub Pages artifact.
5. Deploys to GitHub Pages.

**Triggers:**
- `workflow_dispatch` (manual)
- Daily cron at **03:00 UTC** (`0 3 * * *`)
- Push to `main` when `urls`, `cpanfile`, or `.github/workflows/build.yml` change

## Code Conventions

- Every Perl file begins with `use strict;` and `use warnings;`.
- The OOP module (`BS_Checker.pm`) uses Perl 5.36+ `class` / `field` / `method` syntax (suppress warnings with `no warnings 'experimental::class'`).
- Exception handling uses `use experimental qw[try];` with `try { ... } catch ($e) { ... }` blocks.
- `say` is used instead of `print` (enabled via `use feature qw[say]`).
- JSON output is always pretty-printed: `JSON->new->pretty->encode(...)`.
- Naming: class `BS_Checker`, script `bs-checker`, field names lowercase with underscores.
- No linter or formatter is enforced; match the style of the existing files.

## Adding or Removing URLs

Edit the `urls` file:
- One URL per line.
- Lines that do not start with `http` are ignored (use `#` for comments).
- The file is passed directly to `bin/bs-checker` as a filename argument.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PERL5LIB` | Yes | Must be set to `lib` when running outside GitHub Actions so Perl can find `BS_Checker.pm` |

## GitHub Pages

The live dashboard is deployed from the `docs/` directory. `docs/index.html` fetches `bs.json` at runtime from the same origin; no build step is needed for the frontend.
