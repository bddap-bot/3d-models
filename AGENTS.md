# Contract

Every `.scad` with a `model.json` beside it ships the STL and preview PNG of each of its parts under `out/`, written by `./build` and gated by CI.

## Manifest

```json
{
  "source": "hopper.scad",
  "parts": {
    "assembly": [65, 0, 35],
    "lid": [55, 0, 25]
  }
}
```

- `source`: the `.scad`, relative to the manifest, inside its directory.
- `parts`: one entry per exported part, keyed by name (`[A-Za-z0-9_]+`, exported with `-D part="<name>"`), valued by the preview's view rotation `[rotx, roty, rotz]` in degrees; the view is auto-centred and fitted.

Any other key or type, a duplicate or empty part, or two parts with the same geometry fails the build.

## Gate

`./build` runs every manifest through OpenSCAD 2021.01 from the nixpkgs revision pinned in `shell.nix` (the shebang enters that shell), writes `out/<part>.stl` and `out/<part>.png`, and deletes anything else in `out/`. Commit what it writes, and add a new model to the root `README.md` catalog.

OpenSCAD triangulates coplanar faces differently from run to run, so a fresh STL replaces the committed one only when its volume, surface area, or bounding box differs by more than 1e-6 relative. The preview is rendered from the committed STL with software GL and is byte-stable across machines.

CI runs `./build` on every push and pull request and fails if the tree is not clean afterwards. Nothing under `out/` may be gitignored.
