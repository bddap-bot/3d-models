# Working on models

Edit by subtraction: resolve a problem by deleting code; a tactical patch over a symptom is not accepted. One implementation per thing, never two alive.

Delete code comments; keep only a why the code cannot show.

Each `model.json` names a `.scad` in its directory and lists exported parts with
preview rotations. Use an existing manifest as the format reference.

Run `./build`, commit the generated STL and PNG for each part under `out/`, and add
new models to the [README catalog](README.md). The build validates manifests and
rejects duplicate geometry; CI reruns it and rejects a dirty tree.

The build preserves geometrically equivalent committed STLs and renders previews
from those STLs. Let it decide whether an output needs replacing.

## Boundaries

Keep this project independent. Reference other projects only as declared, versioned
dependencies, exposing names and versions rather than internals. Give shared services
neutral project-owned names. Exclude deployment-specific paths, addresses, service
or scheduler names, credentials, camera frames and private renders. Before landing,
inspect the diff for undeclared project references and deployment details.
