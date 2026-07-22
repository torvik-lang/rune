# Security Policy

## Supported versions

Security fixes target the latest released rune. Update with `rune self-update` (or `rune update`).

## Reporting a vulnerability

Please report security issues **privately** rather than opening a public issue. Use GitHub's private vulnerability reporting on this repository (Security → Report a vulnerability), or contact the maintainer through the address listed on the Torvik organization profile.

Include: what you found, steps to reproduce, affected version (`rune version`), and impact. You'll get an acknowledgement as soon as possible, and coordinated disclosure once a fix is available.

## Scope notes

rune runs installers that download binaries over HTTPS from GitHub Releases and fetch `VERSION` from `main`. Reports about the integrity of that flow (e.g. spoofing, tampering, unsafe shell handling) are in scope and appreciated.
