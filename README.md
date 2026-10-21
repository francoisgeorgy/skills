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
