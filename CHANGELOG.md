# Changelog

All notable changes to rune are documented here. rune is versioned independently
of Torvik; this file tracks rune only. Format based on Keep a Changelog.

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
