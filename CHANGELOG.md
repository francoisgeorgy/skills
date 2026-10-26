# Changelog

## fgy-embedded 0.2.0 (2026-10-22)

- Ajout du skill `clion-pico2-setup` : projet Pico 2 / Pico 2 W (RP2350, plateforme `rp2350-arm-s`) pour CLion, CMakePresets `debug-pico2` / `debug-pico2-w`, OpenOCD `target/rp2350.cfg` + Debug Probe, stdio usb/uart/none, README anglais et français. `check_prereqs.sh` exige un SDK >= 2.0.0 (code 1 sinon) et signale par le code 2 un OpenOCD sans `target/rp2350.cfg` (cas de la 0.12.0) : le projet est alors généré et compilé, avec un avertissement sur le flash et le débogage.
- `clion-pico-setup` renvoie vers `clion-pico2-setup` pour les cartes RP2350.
- Ajout du skill `pico-env-check` : vérifie l'environnement Pico (RP2040) et Pico 2 (RP2350) (Xcode CLT, Homebrew, CMake, Ninja, toolchain Arm et newlib, Pico SDK et sous-modules, dernière release du SDK, picotool, OpenOCD et scripts `rp2040.cfg` / `rp2350.cfg`, build HEAD cassé ou non lié) et produit un rapport avec verdict par famille et commandes `brew` de correction.
- Doc OpenOCD : `brew uninstall --force open-ocd` avant `brew install --HEAD open-ocd` (sinon la 0.12.0 reste active), et recompilation quand une bibliothèque liée (jimtcl...) est mise à jour.
- Doc CLion des deux skills : les compilateurs de la toolchain `Pico ARM` peuvent rester en détection automatique (CLion ne passe alors aucun compilateur à CMake et le projet comme le SDK choisissent `arm-none-eabi-*`) ; chemins explicites optionnels. Commentaire du template et tableau des README corrigés en conséquence.
- README : chapitre « Support du Pico 2 par OpenOCD » (pourquoi la version HEAD, installation, mise à jour, retour à la 0.12.0).

## fgy-embedded 0.1.0 (2026-10-21)

- Ajout du skill `clion-pico-setup` : projet Pico / Pico W (RP2040) pour CLion, CMakePresets, OpenOCD + Debug Probe, stdio usb/uart/none, README anglais (`README.md`) et français (`README.fr.md`).
