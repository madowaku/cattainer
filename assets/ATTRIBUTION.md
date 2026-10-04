# CATTAINER asset provenance

License checks: 2026-10-04 (Asia/Tokyo).

## Music

**昼下がり気分 — KK**, track 1 (loop, 235.259 seconds).

- Download page: https://opentracks.com/bgm/detail/4695/download
- Author and terms: https://opentracks.com/creator/detail/19
- Site audio license: https://opentracks.com/help/articles/license/
- Site terms: https://opentracks.com/help/articles/terms/
- Author follows the site license; commercial game background use and conversion are permitted. Attribution and usage reports are not required; credit is included in the game.
- The selected track was downloaded through its normal download control and converted to a compressed Godot AudioStreamMP3 binary resource (`audio/afternoon.res`). The original MP3 is not distributed in the repository. Windows builds embed the converted game resource in their data pack.
- The music remains KK's work. It is not CC0 or part of a general source-code license. Do not distribute it as standalone music or a reusable music asset pack. Content ID registration and AI training are prohibited by the source license.

## Sound effects

Kenney **UI Audio** and **Interface Sounds**, CC0.

- https://kenney.nl/assets/ui-audio
- https://kenney.nl/assets/interface-sounds
- Copied from the user's `C:/Dev/AssetsShared/Audio/SE` library.
- UI Audio: `click3.ogg` → `cut.ogg`; `switch3.ogg` → `restore.ogg`.
- Interface Sounds: `bong_001.ogg` → `bump.ogg`; `confirmation_001.ogg` → `fit.ogg`; `confirmation_002.ogg` → `perfect.ogg`.
- Original license texts are in `audio/licenses/`.

## Font

Nunito variable font, Google Fonts, SIL Open Font License 1.1.

- https://github.com/google/fonts/tree/main/ofl/nunito
- Font license: `fonts/OFL.txt`.
- Japanese help uses installed Windows Yu Gothic / Meiryo fallback fonts, not redistributed font files.

## Art

`cats/cat_atlas.png` and `ui/cozy_room.png` generated with the built-in **Imagegen** tool for this project, guided by the user's supplied CATTAINER concept. Transparent atlas alpha is preserved; individual cats use AtlasTexture source regions. The reference image itself is not included in the game.

Cardboard fibers, recesses, diagrams, focus outlines and paper particles are native Godot drawing. No third-party visual asset pack is used.
