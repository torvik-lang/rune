# Rune

**Rune** is the package manager and toolchain manager for the [Torvik](https://github.com/torvik-lang/torvik) programming language. It creates projects, builds them, and keeps your Torvik installation up to date. Rune is itself written in Torvik.

As of v1.4.0, Rune lives in its own repository and is versioned and released independently of Torvik, so it can ship fixes and features on its own cadence. It still installs into the same place (`~/.torvik`) and manages Torvik exactly as before.

## Install

You normally get Rune automatically when you install Torvik:

```sh
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/torvik-lang/torvik/main/linux/install.sh | sh
```
```powershell
# Windows (PowerShell)
iwr -useb https://raw.githubusercontent.com/torvik-lang/torvik/main/windows/install.ps1 | iex
```

The Torvik installer pulls the latest Rune from this repo for you. To install or reinstall **only** Rune:

```sh
curl -fsSL https://raw.githubusercontent.com/torvik-lang/rune/main/linux/install.sh | sh
```
```powershell
iwr -useb https://raw.githubusercontent.com/torvik-lang/rune/main/windows/install.ps1 | iex
```

## Commands

```
rune new <name>     Create a new project
rune build [--clean] [--final]   Build the current project into build/
rune run            Build and run
rune list           Show project info (alias: ls)
rune clean          Remove the build/ directory
rune update [vX]    Update Torvik (torvc + std) and rune to the latest, or pin torvc to vX
rune self-update    Update just rune, from this repo
rune uninstall      Remove the Torvik toolchain and rune (~/.torvik)
rune version        Show versions
rune help           Show help
```

### Updating

`rune update` checks Torvik and Rune **independently**: if only Torvik moved it updates the toolchain (which also refreshes Rune), if only Rune moved it updates just Rune, and if both moved it updates both. `rune self-update` targets Rune alone.


## License

AGPL-3.0 with a runtime-library exception — see [LICENSE](LICENSE). Programs you build with Torvik and rune are entirely yours. "Torvik" and "Rune" naming/branding are covered by a separate trademark notice.
