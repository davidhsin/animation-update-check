# Reproducing the developer checks

These checks use synthetic, procedurally generated examples. Passing them does not prove compatibility with a customer project or correct gameplay timing.

Verified environment: Godot 4.7.2 stable, macOS 27.0.1, Apple Silicon. Use the Godot editor binary, not an export template. Replace `godot` below with the path to that binary. Commands shown use a POSIX shell.

From this repository's root:

```sh
godot --headless --editor --path . --import
mkdir -p .qa_results
RELEASE_QA_OUTPUT="$PWD/.qa_results/regression.json" godot --headless --path . --script res://qa/checks.gd
PATH_QA_OUTPUT="$PWD/.qa_results/paths.json" godot --headless --path . --script res://qa/path_checks.gd
```

The first runner checks 29 resource, input and timing cases. The second checks 8 node-path cases. Each writes JSON and returns a nonzero exit code if an assertion fails. Both compare resource fingerprints around the check to detect changes in the tested inputs.

The runners instantiate the included demo; they do not run a customer's game or execute its animation method/audio tracks. These are development regression runners, not a general command-line interface for auditing arbitrary projects.

The 0.2.1 path fix was reproduced against 0.2.0 before implementation. It addresses equivalent node paths (`%Sprite`, `./Sprite`, absolute paths and properties on the animation root) and duplicate-track detection through those aliases. The code still checks only the documented global-library, AnimatedSprite2D workflow.
