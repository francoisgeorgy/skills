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

#### Exemple : `clion-pico-setup`

Le skill se déclenche à partir d'une demande en langage naturel :

```
Crée un projet Pico W nommé test_blink dans ~/dev/sandbox, avec printf sur USB.
```

Ou explicitement :

```
/fgy-embedded:clion-pico-setup Pico nommé sensor_logger dans ~/dev/projects, stdio sur UART
```

Paramètres reconnus : nom du projet (identifiant C), dossier parent (doit exister), carte (`pico` ou `pico_w`, défaut `pico_w`), stdio (`usb`, `uart` ou `none`, défaut `usb`). Les paramètres manquants sont demandés. Le skill vérifie les prérequis, génère le projet (dont `README.md` et `README.fr.md`), le compile, puis donne les étapes CLion restantes.

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
