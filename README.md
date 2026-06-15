# uni-launcher

**English** | [Français](README.fr.md)

`uni` is a generic Bash launcher for native games, scripts, AppImage files, Wine games, and emulated games. It follows the `emu-launcher` architecture while keeping a separate library under `~/.config/uni`.

Installation and updates use the shared `install-update-launcher` package. During development, keep it in a sibling repository. The installed `uni` command receives a copy of the shared library and remains autonomous.

## Installation

```bash
./uni --install
# or: ./uni --install --system
```

The library can also be selected with `INSTALL_UPDATE_LAUNCHER_LIB=/path/to/install-update-launcher.bash` or installed separately.

The user installation places the command in `~/.local/bin/uni`, modules in `~/.local/lib/uni`, and Bash completion in `~/.local/share/bash-completion/completions/uni`. It configures `~/.profile` and `~/.bashrc` without duplicating managed blocks.

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
uni doctor
uni --dry-run <game>
uni --foreground <game>
uni --update
```

## Tests

```bash
bash tests/run.sh
```
