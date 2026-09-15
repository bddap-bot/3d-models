#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
if [[ "${ASTER_ECHO_NIX_SHELL:-}" != "1" ]]; then
  exec nix-shell "$here/shell.nix" --run "ASTER_ECHO_NIX_SHELL=1 '$here/build.sh'"
fi
tooling="$root/.tooling/reasonable-poly"
scripts="$tooling/blender-scripts"
archive="$tooling/VRM_Addon_for_Blender-4_7_1.zip"
addon="$scripts/addons/VRM_Addon_for_Blender-release"
url="https://github.com/saturday06/VRM-Addon-for-Blender/releases/download/v4.7.1/VRM_Addon_for_Blender-4_7_1.zip"
expected="1fba87c3c6b2f995120f76c023bb11ab108b0a4a276872b4c10b20fae73e65ca"

mkdir -p "$tooling" "$scripts/addons"
if [[ ! -f "$archive" ]]; then
  curl -fsSL "$url" -o "$archive"
fi
printf '%s  %s\n' "$expected" "$archive" | sha256sum -c -
rm -rf "$addon"
unzip -q "$archive" -d "$scripts/addons"

cd "$here"
rm -rf .proof-frames
mkdir -p .proof-frames proof textures
BLENDER_USER_SCRIPTS="$scripts" blender --python-exit-code 1 -b -P generate.py
BLENDER_USER_SCRIPTS="$scripts" blender --python-exit-code 1 -b aster-echo.blend -P verify_blend.py
ffmpeg -hide_banner -loglevel error -y -framerate 12 -i .proof-frames/frame_%02d.png -filter_complex "[0:v]split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer" proof/turntable.gif
ffmpeg -hide_banner -loglevel error -y -i .proof-frames/viseme_0.png -i .proof-frames/viseme_1.png -i .proof-frames/viseme_2.png -i .proof-frames/viseme_3.png -i .proof-frames/viseme_4.png -filter_complex "hstack=inputs=5" proof/visemes.png
rm -rf .proof-frames
npm ci --ignore-scripts --no-audit --no-fund
node verify.mjs
