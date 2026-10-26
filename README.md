# francoisgeorgy-skills

Skills pour [Claude Code](https://claude.com/claude-code), distribués sous forme de plugins.

## Installation

Dans Claude Code :

```
/plugin marketplace add francoisgeorgy/skills
/plugin install fgy-embedded@francoisgeorgy-skills
```

Les skills sont ensuite disponibles sous le préfixe du plugin, par exemple `fgy-embedded:clion-pico-setup`.

## Plugins

### fgy-embedded

| Skill | Rôle |
| --- | --- |
| [`clion-pico-setup`](plugins/fgy-embedded/skills/clion-pico-setup/SKILL.md) | Crée un projet C pour Raspberry Pi Pico / Pico W (RP2040), prêt pour CLion et le débogage SWD avec une Raspberry Pi Debug Probe |
| [`clion-pico2-setup`](plugins/fgy-embedded/skills/clion-pico2-setup/SKILL.md) | Idem pour Raspberry Pi Pico 2 / Pico 2 W (RP2350, cœurs Arm Cortex-M33) |
| [`pico-env-check`](plugins/fgy-embedded/skills/pico-env-check/SKILL.md) | Vérifie l'environnement de développement Pico et Pico 2 (SDK, toolchain Arm, OpenOCD, CMake, picotool, Homebrew) et donne les commandes de correction |

#### Exemple : `clion-pico-setup`

Le skill se déclenche à partir d'une demande en langage naturel :

```
Créer un projet Pico W nommé test_blink dans ~/dev/sandbox, avec printf sur USB.
```

Ou explicitement :

```
/fgy-embedded:clion-pico-setup Pico nommé sensor_logger dans ~/dev/projects, stdio sur UART
```

Paramètres reconnus : nom du projet (identifiant C), dossier parent (doit exister), carte (`pico` ou `pico_w`, défaut `pico_w`), stdio (`usb`, `uart` ou `none`, défaut `usb`). Les paramètres manquants sont demandés. Le skill vérifie les prérequis, génère le projet (dont `README.md` et `README.fr.md`), le compile, puis donne les étapes CLion restantes.

#### Exemple : `clion-pico2-setup`

```
Créer un projet Pico 2 nommé test_blink2 dans ~/dev/sandbox, stdio sur UART.
```

Ou explicitement :

```
/fgy-embedded:clion-pico2-setup Pico 2 W nommé weather_station dans ~/dev/projects, printf sur USB
```

Mêmes paramètres, avec la carte `pico2` ou `pico2_w` (défaut `pico2_w`). Le projet cible les cœurs Arm (`PICO_PLATFORM=rp2350-arm-s`). Prérequis spécifiques : Pico SDK >= 2.0.0, et un OpenOCD qui fournit `target/rp2350.cfg`, absent de la version 0.12.0 installée par défaut par Homebrew (voir ci-dessous).

#### Exemple : `pico-env-check`

```
Vérifie mon environnement de développement Pico.
```

Le skill vérifie toujours les deux familles (Pico / RP2040 et Pico 2 / RP2350) sans rien modifier. Le rapport contient :
- un verdict par famille : compilation possible, flash et débogage possibles ;
- un tableau de ce qui est en place, manquant, à mettre à jour, à supprimer ou cassé ;
- les commandes à exécuter, avec Homebrew quand c'est possible, et l'installation de Homebrew lui-même s'il est absent.

Ajouter « hors ligne » pour ne pas chercher la dernière version du SDK sur GitHub.

#### Support du Pico 2 par OpenOCD

**Pourquoi une autre version.** La dernière release d'OpenOCD, la 0.12.0 (celle que `brew install openocd` installe), date d'avant le RP2350 et ne contient pas `target/rp2350.cfg`. Avec elle, flasher ou déboguer un Pico 2 échoue avec :

```
Error: Can't find target/rp2350.cfg
```

Le fichier existe dans la branche `master` d'OpenOCD, que Homebrew sait compiler avec l'option `--HEAD`, et dans le fork Raspberry Pi (branche `sdk-2.0.0`). La procédure ci-dessous utilise `master`.

**Compatibilité avec le Pico (RP2040).** `master` contient toujours `target/rp2040.cfg`. Les projets `clion-pico-setup` fonctionnent sans modification. Deux différences par rapport à la 0.12.0 :
- les deux cœurs sont débogués ensemble par défaut (mode SMP) : dans CLion, le cœur 1 apparaît comme un second thread ;
- le pilote flash `rp2040_flash` s'appelle désormais `rp2xxx`. Le changement est interne à `rp2040.cfg` et ne concerne que les scripts qui le nommeraient explicitement.

**Installation.** La version HEAD est compilée localement : il faut les outils en ligne de commande Xcode (`xcode-select --install`). Homebrew installe lui-même les dépendances de compilation (autoconf, automake, libtool, texinfo, jimtcl).

```sh
brew uninstall --force open-ocd    # retire toutes les versions déjà installées
brew install --HEAD open-ocd
```

Sans `--force`, `brew install --HEAD` ajoute la version HEAD à côté de la 0.12.0, qui reste celle qui est active (`openocd --version` affiche alors `0.12.0` et `rp2350.cfg` reste introuvable).

Vérifier que les deux cibles sont présentes :

```sh
openocd --version
ls "$(brew --prefix)/share/openocd/scripts/target/" | grep rp2
```

`rp2040.cfg` et `rp2350.cfg` doivent apparaître. Le script `check_prereqs.sh` du skill fait la même vérification. Le chemin de l'exécutable ne change pas : la configuration OpenOCD de CLion reste valable.

**Mise à jour.** `brew upgrade` ne met pas à jour une installation HEAD. Pour reprendre le dernier état de `master` :

```sh
brew upgrade --fetch-HEAD open-ocd
```

`master` est une version de développement : une régression reste possible. Après une mise à jour, flasher un projet connu avant de reprendre le travail :

```sh
openocd -f openocd-rp2350-cmsis-dap.cfg -c "program build/<carte>/<nom>.elf verify reset exit"
```

**Binaire cassé après un `brew upgrade`.** La version HEAD est liée aux bibliothèques Homebrew présentes au moment de la compilation (jimtcl, capstone, hidapi, libftdi, libusb). Si l'une d'elles passe à une nouvelle version de bibliothèque (cas de jimtcl 0.83 vers 0.84), OpenOCD ne démarre plus :

```
dyld: Library not loaded: /opt/homebrew/opt/jimtcl/lib/libjim.0.83.dylib
```

Il faut alors le recompiler avec la même commande qu'à l'installation (`brew uninstall --force open-ocd && brew install --HEAD open-ocd`). Le skill `pico-env-check` détecte ce cas.

**Retour à la 0.12.0.** En cas de problème : `brew uninstall --force open-ocd && brew install open-ocd`. Le Pico 2 ne sera alors plus pris en charge.

## Développement

Structure :

```
.claude-plugin/marketplace.json     catalogue des plugins
plugins/<plugin>/
  .claude-plugin/plugin.json        manifeste (version)
  skills/<skill>/SKILL.md           un dossier par skill
```

Tester en local, sans passer par GitHub :

```
/plugin marketplace add /Users/francois/dev/skills
/plugin install fgy-embedded@francoisgeorgy-skills
```

Après une modification : `/plugin marketplace update francoisgeorgy-skills`, puis redémarrer Claude Code.

Valider avant de pousser :

```sh
claude plugin validate .
claude plugin validate plugins/fgy-embedded
```

Incrémenter `version` dans `plugin.json` à chaque changement de comportement et le noter dans [CHANGELOG.md](CHANGELOG.md).

## Licence

[MIT](LICENSE)
