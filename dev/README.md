# rune — maintainer documentation

This directory is for people working **on** rune, not people using it.

## Tests

    cd dev/tests
    sh run_tests.sh [path-to-rune] [path-to-torvc]

Defaults to `rune` / `torvc` on `PATH`. **19 cases** covering project creation,
incremental builds, exit-code propagation, the version gates, single-file run mode,
the `[build]` manifest section, and the update-policy flags. Work happens in
`dev/tests/rune-test-work`; the log is `results.log`. Exit code 0 = all green.

rune moved to its own repository in v1.4.0 and gained its own suite in v1.5.0.
Before that these cases lived in Torvik's suite, which meant a rune regression could
only be caught by building the compiler. They are separate now: Torvik's suite runs
with only `torvc` installed, and this one exercises rune against whatever toolchain
is present.

## Building

    torvc src/rune.tv -o rune --final

rune is an ordinary Torvik program — there is no bootstrap problem to worry about,
unlike the compiler itself. Build it with the `torvc` you intend to ship alongside.

## Releasing

1. Bump `VERSION` (`rune = X.Y.Z`).
2. Add the entry to `CHANGELOG.md`.
3. Build with `--final` and attach the binaries to a GitHub release tagged `vX.Y.Z`.
   The installers and `rune self-update` look for release assets named
   `rune-<os>-<arch>`.

rune is versioned independently of Torvik. A rune release does not require a Torvik
release, or the reverse.
