# uni-launcher

**English** | [Français](README.fr.md)

`uni` is a generic Bash launcher for native games, scripts, AppImage files, Wine games, and emulated games. It follows the `emu-launcher` architecture while keeping a separate library under `~/.config/uni`.

Installation and updates use the shared `install-update-launcher` package. During development, keep it in a sibling repository. The installed `uni` command receives a copy of the shared library and remains autonomous.

`uni` is the only project that orchestrates other launcher packages. `emu-launcher` and `install-update-launcher` never install `uni`.

## Available launchers

Inspect every launcher package managed by `uni` on the selected deployment channel:

```bash
uni launchers
uni launchers --channel prerelease
```

The command reports `not-installed`, `up-to-date`, `update-available`, or `unavailable`. Filter the registry by status:

```bash
uni launchers --installed
uni launchers --missing
uni launchers --current
uni launchers --updates
```

`--installed` includes both current packages and packages with an available update. Use `--system` to inspect `/usr/local` instead of the user installation. Install missing packages with `uni --install --all` or selected packages with `--with-emu` and `--with-installer`; update installed packages with the matching `uni --update` options.

## Installation

```bash
./uni --install
# or: ./uni --install --system
./uni --install --with-emu
./uni --install --with-installer
./uni --install --all
```

The library can also be selected with `INSTALL_UPDATE_LAUNCHER_LIB=/path/to/install-update-launcher.bash` or installed separately.

The user installation places the command in `~/.local/bin/uni`, modules in `~/.local/lib/uni`, and Bash completion in `~/.local/share/bash-completion/completions/uni`. It configures `~/.profile` and `~/.bashrc` without duplicating managed blocks.

`--with-emu` downloads and installs `https://github.com/dasbap/emu-launcher.git`. `--with-installer` installs the standalone `install-update-launcher` command. `--all` enables both options. Add `--system` to use `/usr/local` destinations.

Updates download the selected projects from the chosen deployment channel instead of using files from the current checkout:

```bash
uni --update
uni --update --with-emu
uni --update --all
```

Choose the same deployment channel for `uni` and every selected package:

```bash
uni --update --channel stable --all
uni --update --channel prerelease --all
uni --update --channel development --all
uni --update --ref v1.2.0 --all
```

Channels map to `release`, `pre-release`, and `main`. The default is `stable`; `--ref` overrides the channel. During installation, `uni` itself is copied from the current checkout, while `--channel` selects the branch used for packages downloaded through `--with-emu`, `--with-installer`, or `--all`.

Override repositories or branches with `UNI_REPOSITORY`, `UNI_REF`, `EMU_REPOSITORY`, `EMU_REF`, `INSTALL_UPDATE_REPOSITORY`, and `INSTALL_UPDATE_REF`.

## Using emu from uni

`emu` is a default runner. When the command is available in `PATH`:

```bash
uni emu mario
uni emu /path/to/game.nes -- --fullscreen
uni --add-emu-game mario /path/to/game.nes
uni mario
```

To use the sibling repository or another installation directly:

```bash
uni --set-emu ../emu-launcher/emu
```

## Native games and other executables

An executable target can be launched directly or registered:

```bash
uni /path/to/game.AppImage -- --fullscreen
uni --add-game my-game /path/to/game.AppImage
uni my-game
```

For files requiring an intermediate program, add a runner and link it to the game:

```bash
uni --add-runner wine /usr/bin/wine
uni --add-game windows-game ~/Games/game/game.exe
uni --link wine windows-game
uni windows-game -- --game-option
```

The first argument passed to a runner is always the game path. Everything after `--` is forwarded unchanged.

## Main commands

```bash
uni --list
uni --add-runner <name> <command>
uni --remove-runner <name>
uni --add-game <name> <path>
uni --add-emu-game <name> <rom>
uni --link <runner> <game>
uni --unlink <game>
uni --remove-game <game>
uni --set-emu <command>
uni launchers
uni launchers --missing
uni launchers --updates
uni doctor
uni --dry-run <game>
uni --foreground <game>
uni --update
uni --update --with-emu
uni --update --with-installer
uni --update --all
uni --update --channel stable --all
uni --update --ref v1.2.0 --all
```

## Tests

```bash
bash tests/run.sh
```
