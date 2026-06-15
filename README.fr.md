# uni-launcher

[English](README.md) | **Français**

`uni` est un lanceur Bash générique pour les jeux natifs, scripts, fichiers AppImage, jeux Wine et jeux émulés. Il reprend l'architecture de `emu-launcher` tout en conservant une bibliothèque séparée dans `~/.config/uni`.

L'installation et les mises à jour utilisent le paquet partagé `install-update-launcher`. Pendant le développement, conservez-le dans un dépôt voisin. La commande `uni` installée reçoit une copie de la bibliothèque partagée et reste autonome.

`uni` est le seul projet qui orchestre les autres paquets launcher. `emu-launcher` et `install-update-launcher` n'installent jamais `uni`.

## Launchers disponibles

Inspectez tous les paquets launcher gérés par `uni` sur le canal de déploiement sélectionné :

```bash
uni launchers
uni launchers --channel prerelease
```

La commande affiche `not-installed`, `up-to-date`, `update-available` ou `unavailable`. Filtrez le registre selon le statut :

```bash
uni launchers --installed
uni launchers --missing
uni launchers --current
uni launchers --updates
```

`--installed` inclut les paquets à jour et ceux pour lesquels une mise à jour est disponible. Utilisez `--system` pour inspecter `/usr/local` au lieu de l'installation utilisateur. Installez les paquets manquants avec `uni --install --all` ou sélectionnez-les avec `--with-emu` et `--with-installer`; mettez à jour les paquets installés avec les options correspondantes de `uni --update`.

## Installation

```bash
./uni --install
# ou : ./uni --install --system
./uni --install --with-emu
./uni --install --with-installer
./uni --install --all
```

La bibliothèque peut aussi être sélectionnée avec `INSTALL_UPDATE_LAUNCHER_LIB=/path/to/install-update-launcher.bash` ou installée séparément.

L'installation utilisateur place la commande dans `~/.local/bin/uni`, les modules dans `~/.local/lib/uni` et la complétion Bash dans `~/.local/share/bash-completion/completions/uni`. Elle configure `~/.profile` et `~/.bashrc` sans dupliquer les blocs gérés.

`--with-emu` télécharge et installe `https://github.com/dasbap/emu-launcher.git`. `--with-installer` installe la commande autonome `install-update-launcher`. `--all` active les deux options. Ajoutez `--system` pour utiliser les destinations sous `/usr/local`.

Les mises à jour téléchargent les projets sélectionnés depuis le canal de déploiement choisi au lieu d'utiliser les fichiers du checkout courant :

```bash
uni --update
uni --update --with-emu
uni --update --all
```

Sélectionnez le même canal de déploiement pour `uni` et tous les paquets choisis :

```bash
uni --update --channel stable --all
uni --update --channel prerelease --all
uni --update --channel development --all
uni --update --ref v1.2.0 --all
```

Les canaux correspondent aux branches `release`, `pre-release` et `main`. Le canal par défaut est `stable`; `--ref` remplace le canal. Pendant l'installation, `uni` est copié depuis le checkout courant, tandis que `--channel` sélectionne la branche des paquets téléchargés avec `--with-emu`, `--with-installer` ou `--all`.

Les dépôts et branches peuvent être remplacés avec `UNI_REPOSITORY`, `UNI_REF`, `EMU_REPOSITORY`, `EMU_REF`, `INSTALL_UPDATE_REPOSITORY` et `INSTALL_UPDATE_REF`.

## Utiliser emu depuis uni

`emu` est un runner créé par défaut. Lorsque la commande est disponible dans `PATH` :

```bash
uni emu mario
uni emu /path/to/game.nes -- --fullscreen
uni --add-emu-game mario /path/to/game.nes
uni mario
```

Pour utiliser directement le dépôt voisin ou une autre installation :

```bash
uni --set-emu ../emu-launcher/emu
```

## Jeux natifs et autres exécutables

Une cible exécutable peut être lancée directement ou enregistrée :

```bash
uni /path/to/game.AppImage -- --fullscreen
uni --add-game my-game /path/to/game.AppImage
uni my-game
```

Pour les fichiers nécessitant un programme intermédiaire, ajoutez un runner puis liez-le au jeu :

```bash
uni --add-runner wine /usr/bin/wine
uni --add-game windows-game ~/Games/game/game.exe
uni --link wine windows-game
uni windows-game -- --game-option
```

Le premier argument transmis à un runner est toujours le chemin du jeu. Tout ce qui suit `--` est transmis sans modification.

## Commandes principales

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
