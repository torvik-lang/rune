# Security Policy

## Supported versions

Security fixes target the latest released rune. Update with `rune self-update` (or `rune update`).

## Advisories

### RUNE-2026-001 — command injection via torvik.rune (fixed in 1.5.1)

**Severity: critical. Update promptly.**

`rune` builds the `torvc` command line by interpolating values read from a
project's `torvik.rune` manifest. Those values were not validated, so a manifest
containing shell syntax executed arbitrary commands during an ordinary
`rune build`. Cloning a repository and building it was sufficient — the resulting
binary never had to be run, and nothing indicated that anything unusual occurred.

Affected fields: `name`, and under `[build]`, `entry`, `arch`, `link-script` and
`link-with`.

All manifest values are now validated before use. Names, entry symbols and target
triples are restricted to an allowlist of safe characters; paths are screened for
shell metacharacters. A rejected value produces a clear message naming the field.

**Affected:** rune 1.5.0 and earlier.
**Fixed in:** 1.5.1.
**Companion fix:** Torvik 1.5.2 validates the same values inside `torvc`, so both
tools must be updated — each built its own command line, and each was
independently vulnerable.

**What to do:** update both `rune` and `torvc`. If you have built an untrusted or
unfamiliar project with an affected version, treat that build as having run
arbitrary code with your user's privileges.

Note that a manifest may also define a custom `runner` command, which `rune run`
executes by design. That is not a vulnerability — it is the feature's purpose, and
`rune` prints the command before running it — but it is a good reason to read an
unfamiliar `torvik.rune` before running anything from it.

## Reporting a vulnerability

Please report security issues **privately** rather than opening a public issue. Use GitHub's private vulnerability reporting on this repository (Security → Report a vulnerability), or contact the maintainer through the address listed on the Torvik organization profile.

Include: what you found, steps to reproduce, affected version (`rune version`), and impact. You'll get an acknowledgement as soon as possible, and coordinated disclosure once a fix is available.

## Scope notes

rune runs installers that download binaries over HTTPS from GitHub Releases and fetch `VERSION` from `main`. Reports about the integrity of that flow (e.g. spoofing, tampering, unsafe shell handling) are in scope and appreciated.
