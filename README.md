# uni-launcher

`uni` est un lanceur Bash generique pour jeux natifs, scripts, AppImage, jeux lances par Wine et jeux emules. Il reprend l'organisation de `emu-launcher`, mais conserve sa propre bibliotheque dans `~/.config/uni`.

## Installation

```bash
./uni --install
# ou: ./uni --install --system
```

L'installation utilisateur place la commande dans `~/.local/bin/uni`, les modules dans `~/.local/lib/uni` et la completion Bash dans `~/.local/share/bash-completion/completions/uni`. Elle configure aussi `~/.profile` et `~/.bashrc` sans dupliquer les blocs geres.

## Utiliser emu depuis uni

`emu` est un runner cree par defaut. Si la commande est installee dans le `PATH`:

```bash
uni emu mario
uni emu /chemin/jeu.nes -- --fullscreen
uni --add-emu-game mario /chemin/jeu.nes
uni mario
```

Pour utiliser directement le depot voisin ou une autre installation:

```bash
uni --set-emu ../emu-launcher/emu
```

## Jeux natifs et autres executables

Une cible executable peut etre lancee directement ou enregistree:

```bash
uni /chemin/jeu.AppImage -- --fullscreen
uni --add-game mon-jeu /chemin/jeu.AppImage
uni mon-jeu
```

Pour les fichiers qui ont besoin d'un programme intermediaire, ajoutez un runner puis liez-le au jeu:

```bash
uni --add-runner wine /usr/bin/wine
uni --add-game jeu-windows ~/Games/jeu/game.exe
uni --link wine jeu-windows
uni jeu-windows -- --option-du-jeu
```

Le premier argument transmis a un runner est toujours le chemin du jeu. Tout ce qui suit `--` est transmis tel quel.

## Commandes principales

```bash
uni --list
uni --add-runner <nom> <commande>
uni --remove-runner <nom>
uni --add-game <nom> <chemin>
uni --add-emu-game <nom> <rom>
uni --link <runner> <jeu>
uni --unlink <jeu>
uni --remove-game <jeu>
uni --set-emu <commande>
uni doctor
uni --dry-run <jeu>
uni --foreground <jeu>
uni --update
```

## Tests

```bash
bash tests/run.sh
```
