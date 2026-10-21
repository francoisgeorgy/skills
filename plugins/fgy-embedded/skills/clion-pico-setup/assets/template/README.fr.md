# @PROJECT@

Firmware @BOARD_NAME@ (`@BOARD@`, RP2040) en C avec le Pico SDK. Développé avec CLion, flashé et débogué par SWD via une Raspberry Pi Debug Probe et OpenOCD.

- Carte : `@BOARD@`
- stdio (`printf`) : @STDIO_LABEL_FR@
- SDK à la création : @SDK_VERSION@ (`PICO_SDK_PATH`)

English version: [README.md](README.md).

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `src/main.c` | Programme : clignotement de la LED + `printf` |
| `CMakeLists.txt` | Résout `PICO_SDK_PATH`, fixe la carte (défaut `@BOARD@`), importe le SDK, définit la cible `@PROJECT@` et le stdio |
| `pico_compilers.cmake` | Sélectionne `arm-none-eabi-*` pour les builds en ligne de commande ; ignoré quand CLion fournit le compilateur |
| `CMakePresets.json` | Presets `debug-pico` / `debug-pico-w` : Ninja, Debug, dossier `build/<carte>`, toolchain CLion `Pico ARM` |
| `openocd-rp2040-cmsis-dap.cfg` | OpenOCD : sonde CMSIS-DAP + cible RP2040, SWD à 5000 kHz |
| `.run/@PROJECT@ SWD.run.xml` | Configuration CLion *OpenOCD Download & Run* (flash + debug) |
| `.gitignore`, `.aiignore` | Exclusions git et outils IA (build, `.idea/`, `CMakeUserPresets.json`...) |
| `CMakeUserPresets.json` | Optionnel, local, non versionné : surcharges machine (ex. `PICO_SDK_PATH`) |

Générés, non versionnés : `build/<carte>/` (CLI et presets CLion, contient `@PROJECT@.elf` / `.uf2`), `cmake-build-*/` (profils CLion hors presets), `.idea/` (réglages locaux CLion).

## Presets CMake

- **Configure preset** : génération (`cmake --preset`) : générateur, dossier de build, carte, type de build.
- **Build preset** : compilation (`cmake --build --preset`) d'un configure preset existant. Ici simple raccourci.

Sans presets le projet compile quand même, mais il faut passer `-DCMAKE_BUILD_TYPE=Debug` (sinon le SDK force `Release`).

## Build en ligne de commande

```sh
cmake --preset @PRESET@
cmake --build --preset @PRESET@
```

Sans Ninja : `cmake -S . -B build/@BOARD@ -DCMAKE_BUILD_TYPE=Debug && cmake --build build/@BOARD@`.

Flasher sans CLion (session CLion arrêtée) :

```sh
openocd -f openocd-rp2040-cmsis-dap.cfg -c "program build/@BOARD@/@PROJECT@.elf verify reset exit"
```

## CLion

Une fois par machine :
1. Toolchain nommée exactement `Pico ARM` (Settings > Build, Execution, Deployment > Toolchains), C/C++ = chemins absolus de `arm-none-eabi-gcc` / `arm-none-eabi-g++`.
2. Exécutable OpenOCD (Settings > ... > Embedded Development).
3. Optionnel : Settings > Advanced Settings > *Automatically import CMake Presets* : n'importer que les configure presets (évite les profils en double `X - X preset`).

Par projet :
1. Ouvrir le dossier **avec CLion** (File > Open, ou `open -a CLion .`), pas avec un autre IDE JetBrains.
2. Settings > Build, Execution, Deployment > CMake : activer **`@PRESET@ preset`** seulement ; désactiver le profil `Debug` auto-créé.
3. Run > Edit Configurations : supprimer les *CMake Application* auto-créées (`@PROJECT@`, `bs2_default*`, `*_pio_h`...), cibles du SDK inexécutables sur Mac.
4. Lancer **`@PROJECT@ SWD`** : Run flashe et exécute, Debug pour les points d'arrêt.

## Câblage SWD

Port **D** de la sonde : `SC` (orange) -> `SWCLK`, `GND` (noir) -> `GND`, `SD` (jaune) -> `SWDIO`.
Le câble SWD n'alimente pas le Pico : l'alimenter par son propre USB. Signaux 3,3 V uniquement.
