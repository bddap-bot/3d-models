#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
addon_dir="$PWD/.blender/scripts/addons/VRM_Addon_for_Blender-release"
tool_shell="$PWD/avatar/low-poly/shell.nix"
addon_zip="$PWD/.tooling/VRM_Addon_for_Blender-4_7_1.zip"
mkdir -p "$PWD/.tooling" "$PWD/.blender/scripts/addons"
if [[ ! -f "$addon_zip" ]]; then
  nix-shell "$tool_shell" --run "curl -fsSL https://github.com/saturday06/VRM-Addon-for-Blender/releases/download/v4.7.1/VRM_Addon_for_Blender-4_7_1.zip -o '$addon_zip'"
fi
printf '%s  %s\n' 1fba87c3c6b2f995120f76c023bb11ab108b0a4a276872b4c10b20fae73e65ca "$addon_zip" | sha256sum -c -
rm -rf "$addon_dir"
nix-shell "$tool_shell" --run "unzip -q '$addon_zip' -d '$PWD/.blender/scripts/addons'"
rm -f "$PWD/avatar/low-poly/lumen-relay.blend" "$PWD/avatar/low-poly/lumen-relay.blend1" "$PWD/avatar/low-poly/lumen-relay.glb" "$PWD/avatar/low-poly/lumen-relay.vrm"
BLENDER_USER_SCRIPTS="$PWD/.blender/scripts" nix-shell "$tool_shell" --run "blender -b -P '$PWD/avatar/low-poly/generate.py'"
test -s "$PWD/avatar/low-poly/lumen-relay.blend"
test -s "$PWD/avatar/low-poly/lumen-relay.glb"
test -s "$PWD/avatar/low-poly/lumen-relay.vrm"
nix-shell "$tool_shell" --run "magick -delay 9 -loop 0 '$PWD/avatar/low-poly/proof/turntable-*.png' -layers Optimize '$PWD/avatar/low-poly/proof/turntable.gif'"
nix-shell "$tool_shell" --run "magick \( '$PWD/avatar/low-poly/proof/expression-neutral.png' '$PWD/avatar/low-poly/proof/expression-aa.png' '$PWD/avatar/low-poly/proof/expression-ih.png' +append \) \( '$PWD/avatar/low-poly/proof/expression-ou.png' '$PWD/avatar/low-poly/proof/expression-ee.png' '$PWD/avatar/low-poly/proof/expression-oh.png' +append \) \( '$PWD/avatar/low-poly/proof/expression-blink.png' '$PWD/avatar/low-poly/proof/expression-amused.png' '$PWD/avatar/low-poly/proof/expression-puzzled.png' +append \) -append '$PWD/avatar/low-poly/proof/expressions.png'"
rm -f "$PWD/avatar/low-poly/lumen-relay.blend1" "$PWD"/avatar/low-poly/proof/turntable-*.png "$PWD"/avatar/low-poly/proof/expression-*.png
cd avatar/low-poly
nix-shell "$tool_shell" --run 'npm install --ignore-scripts --no-audit --no-fund && node repair-vrm-animations.mjs && node verify.mjs'
