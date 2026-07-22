# Contributing to rune

Thanks for your interest in improving rune, the Torvik package manager.

## Ground rules

- rune is written in Torvik. Changes go in `src/rune.tv`. `src/diag.tv` is a **vendored copy** of Torvik's diagnostics module — do not diverge it casually; if it must change, sync the change with the Torvik repo.
- Keep rune self-contained: it depends only on `torvc`, the standard library, and the vendored `diag`. Don't add dependencies on Torvik-internal compiler modules.
- Match the existing style in `rune.tv` (small helper functions, `check`/`fallback`, clear user-facing messages).

## Building and testing

Building rune from source uses maintainer tooling that isn't part of the public
source tree. If you'd like to build rune directly to test a change, email
**torviklang@gmail.com** and we'll send you the build script and any binary you need.
For many changes you can iterate against an installed toolchain without building rune
from scratch.

Test the commands you touched against a scratch project (`rune new demo && cd demo && rune build && rune run`). For update-path changes, be careful: `rune update` and `rune self-update` run real installers — test the decision/messaging logic with the network unavailable first. If you can only test on one platform, say so in the PR — the other gets verified before merge.

## Versioning

Bump `VERSION` (the `rune` line) for any user-visible change. Keep the fallback constant in `rune_self_version()` in sync. Add a `CHANGELOG.md` entry.

## Submitting

Open a pull request with a clear description of the change and why. Keep PRs focused. By contributing you agree your work is licensed under the project's AGPL-3.0 license.
