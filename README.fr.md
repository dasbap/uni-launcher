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

`--installed` inclut les paquets à jour et ceux pour lesquels une mise à jour est disponible. Utilisez `--system` pour inspecter `/usr/local` au lieu de l'installation utilisateur. `install-update-launcher` est toujours géré par `uni`; installez les launchers optionnels manquants avec `uni --install --all` ou `--with-emu`, puis mettez-les à jour avec les options correspondantes de `uni --update`.

## Installation

```bash
./uni --install
# ou : ./uni --install --system
./uni --install --with-emu
./uni --install --all
```

La bibliothèque peut aussi être sélectionnée avec `INSTALL_UPDATE_LAUNCHER_LIB=/path/to/install-update-launcher.bash` ou installée séparément.

L'installation utilisateur place la commande dans `~/.local/bin/uni`, les modules dans `~/.local/lib/uni` et la complétion Bash dans `~/.local/share/bash-completion/completions/uni`. Elle configure `~/.profile` et `~/.bashrc` sans dupliquer les blocs gérés.

Chaque `uni --install` installe d'abord automatiquement la commande autonome `install-update-launcher`. Chaque `uni --update` la met d'abord à jour. L'outil de déploiement est ainsi réellement disponible dans le `PATH` au lieu d'exister uniquement comme bibliothèque embarquée.

`--with-emu` télécharge et installe également `https://github.com/dasbap/emu-launcher.git`. `--all` installe tous les launchers optionnels actuellement enregistrés par `uni`. Ajoutez `--system` pour utiliser les destinations sous `/usr/local`. L'ancienne option `--with-installer` reste acceptée pour compatibilité mais n'est plus nécessaire.

`uni --update` et `uni -u` mettent à jour par défaut tous les paquets enregistrés : `install-update-launcher`, `uni` et les launchers optionnels comme `emu`. Le canal par défaut est `stable`; les paquets inchangés ne sont pas recopiés après comparaison SHA-256.

```bash
uni --update
uni -u
```

Sélectionnez le même canal de déploiement pour `uni` et tous les paquets choisis :

```bash
uni --update --channel stable --all
uni --update --channel prerelease --all
uni --update --channel development --all
uni --update --ref v1.2.0 --all
```

Les canaux correspondent aux branches `release`, `pre-release` et `main`. `--ref` remplace le canal et peut sélectionner une ancienne branche ou un ancien tag pour tous les paquets gérés.

## Compatibilité des configurations

Chaque paquet fournit `deploy/manifest` avec sa version applicative, son schéma de configuration et la plage de schémas compatibles. L'état installé est conservé dans `~/.local/state/launcher-tools/packages`.

Lorsqu'une mise à jour ou un retour en arrière change le schéma de configuration, l'updater crée automatiquement une sauvegarde persistante dans `~/.local/state/launcher-tools/backups/<command>/`. Les sauvegardes ne sont pas supprimées lors des changements de version et restent disponibles jusqu'au retour vers une version compatible.

Si la cible ne sait pas lire le schéma actuel, la mise à jour s'arrête après la sauvegarde. Les choix disponibles sont :

```bash
uni -u --ref v1.0.0                 # sélectionner une autre version compatible
uni -u --ref v2.0.0 --merge-config  # utiliser deploy/migrate-config si disponible
uni -u --ref v1.0.0 --force-config  # ignorer la protection après vérification
```

`--merge-config` fonctionne uniquement lorsque le paquet cible fournit un hook exécutable `deploy/migrate-config`. `--force-config` remplace les binaires sans convertir la configuration et doit rester une option de récupération.

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
uni -u
uni --update --all
uni -u --merge-config
uni --update --channel stable --all
uni --update --ref v1.2.0 --all
```

## Tests

```bash
bash tests/run.sh
```
