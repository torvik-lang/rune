# Changelog

All notable changes to rune are documented here. rune is versioned independently
of Torvik; this file tracks rune only. Format based on Keep a Changelog.

## [1.5.0] - 2026-07

Released alongside Torvik v1.5.0 "The Forge".

### Added

- **`rune run <file.tv> [args...]`** runs a single file directly, forwarding any
  trailing arguments to the program. A bare `rune run` still builds and runs the
  project.
- **The `[build]` manifest section** — declare `target`, `entry`, `arch`,
  `link-script`, `link-with`, `elf32` and a `runner` once, and `rune build` / `rune run` do the
  right thing for a freestanding target. A bare project builds to `.elf` and is handed
  to the runner rather than executed by the host.
- **Major-version gating.** `rune update` now keeps you on your current major and
  reports a new one instead of installing it. Opt in with `rune update v2 --yes`;
  quiet the notice with `--silence-major` (it returns when the next major ships).
- **Standard-library gating.** std has its own repository and version line as of
  Torvik v1.5.0. A `std = "x.y.z"` pin in the manifest is honoured; without one, rune
  keeps std inside its current major. `rune update --std-major` checks for a new
  major, and with `--yes` installs it *and* writes the pin into `torvik.rune`.
  `--silence-std-major` quiets that notice.
- **rune has its own test suite** (`dev/tests/run_tests.sh`), so a rune regression is
  catchable without building the compiler.

### Changed

- The standard library is fetched from `torvik-lang/std` rather than from the Torvik
  repository. Installing an older Torvik still works exactly as before — those
  releases carry std in their own tree, and tags are immutable.
- Silencing a major-version notice when there is no new major now refuses with an
  explanation instead of quietly recording nothing.

## [1.4.0] - 2026-07-19

First release from the standalone `torvik-lang/rune` repository. rune was
previously versioned and shipped as part of Torvik; from here it moves on its own
cadence. No breaking changes to commands or on-disk layout.

### Changed
- rune now lives in its own repository and is versioned independently. Its version
  is read from `~/.torvik/rune.VERSION` (written by the installer / `rune_make`),
  falling back to a built-in constant — no longer from Torvik's `VERSION`.
- `rune update` now checks Torvik and rune **independently**: it updates the
  toolchain when torvc is behind (which also refreshes rune), updates only rune
  when just rune is behind, or both when both are.
- `rune update` / `rune self-update` fetch rune from `torvik-lang/rune`; toolchain
  updates continue to come from `torvik-lang/torvik`.
- `rune version` reports rune's own independent version.

### Added
- `rune self-update` — update only the package manager, from this repo.

### Notes
- Existing users on rune 1.3.0 or earlier update seamlessly: `rune update` re-runs
  the live Torvik installer, which now also pulls the latest rune from this repo.
