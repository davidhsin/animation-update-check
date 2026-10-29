# Animation Update Check — 0.2.1 Beta

A local Godot editor addon for reviewing a proposed **SpriteFrames** update against existing **AnimationPlayer** frame tracks.

Example: an attack becomes 0.200 seconds long, while an audio key is still at 0.250 seconds. The check lists that key before you perform the update.

## Quick start with the included example

1. Import `project.godot` in **Godot 4.7.2** and open `demo.tscn`.
2. Select `AnimationPlayer` in the Scene dock. The addon panel appears at the top of the Inspector.
3. Choose `Sprite`, then drag `proposed_shorter.tres` into **Proposed SpriteFrames**.
4. Click **Check proposed update**, then **Open readable report**. The example reports an event and audio key after the proposed end.
5. Try `proposed_slower_start.tres` to see frame-index changes at existing key times.

The example is an editor scene, not a standalone game. The addon does not require Aseprite, AS2P, an account, an API key, or a runtime service.

## Install in your own project

Copy `addons/update_review` into your project's `addons` directory. Enable **Animation Update Check** in **Project > Project Settings > Plugins**. Open the scene containing your AnimatedSprite2D and AnimationPlayer. Select the AnimationPlayer, select the target sprite in the addon panel, and drag in the proposed SpriteFrames resource.

You prepare that proposed SpriteFrames resource using your normal import or editing workflow. This addon does not import PNG folders or generate SpriteFrames.

## What it checks

- Active manual-track keys beyond the proposed animation end.
- Frame-index changes at existing key times after changing frame durations.
- Changed frame-key sequences and loop settings.
- Duplicate, disabled or unsupported frame tracks, unexpected animation bindings, and same-name animations belonging to another target.
- Equivalent node paths, including scene-unique names such as `%Sprite`, `./Sprite`, absolute paths, and properties on the animation root. Matching uses the actual resolved node rather than path spelling.
- Optional compatibility checks for the tested AS2P converter revision. These are off by default.

**Copy report JSON** copies the most recent report to your clipboard only when you click it. Reports are snapshots: rerun after changing animation data. Changing an addon input clears the old report.

## Scope and interpretation

This beta supports **AnimatedSprite2D**, **the global AnimationLibrary**, and **discrete forward frame tracks**. It does not support named libraries, 3D/skeletal animation, reverse-playback analysis, or blending analysis. Unsupported conditions are reported rather than treated as a clean check.

Frame indices are not artwork identities. The addon cannot recognize a redrawn or reordered drawing, infer your gameplay intent, or guarantee audio/collision alignment. A frame-index hint may be harmless: inspect it in your game. Disabled manual tracks are excluded from timing hints.

The addon reads animation resources. It does not apply imports, change tracks, retime events, recover files, run your method/audio tracks, upload artwork, or connect to a network. Installation and the normal Godot editor can create editor/cache files; that is separate from the check itself.

## Optional AS2P checks

Enable **Tested AS2P compatibility checks** only if relevant to your workflow. They cover the behavior observed in the Godot 4 branch at commit `e9a20caefceb0ff742551da8ccf55f962917e210` of [poohcom1/godot-animated-sprite-2-player](https://github.com/poohcom1/godot-animated-sprite-2-player). Other revisions and converters may differ. No upstream addon is included or required.

## Verified environment

Tested with **Godot 4.7.2 stable**, macOS 27.0.1, Apple Silicon. Other Godot versions and operating systems are unverified. The download is source for a Godot editor plugin, not a native executable.

Release checks cover 37 resource/input/timing/path cases and read-only behavior in those cases. The 0.2.0 editor interaction and report windows were previously checked; this patch changes track matching and documentation. See TESTED.md for the current package checks. These are developer tests, not independent customer reviews or an accessibility certification.

For reproducible commands and the included synthetic test runners, see [VERIFYING.md](VERIFYING.md).

## For people making games with AI

DH Game Tools builds small tools for AI-assisted game makers and explores checks their coding agents could use. This addon currently has an editor UI and a manual **Copy report JSON** button. Direct agent invocation, a general audit CLI and MCP integration are exploratory directions, not released features.

An AI-generated change still needs the same input validation, supported-scope checks and in-game review as any other change. A successful parser or headless regression test does not prove that a game mechanic works as intended.

## Feedback

Use the comments on the [project's itch.io page](https://dh-game-tools.itch.io/animation-update-check). See SUPPORT.md for installation troubleshooting and a short issue template. Include your Godot version, OS, animation setup and steps to reproduce. A small shareable example is most useful. Keep private artwork and personal information out of public comments.

## License and credits

MIT license; see `LICENSE.txt`. You may use the addon in personal and commercial projects under that license.

Example pixels and the cover layout were generated with code. Code, documentation, and layout were created with AI assistance and checked in the verified environment. The addon itself uses no generative AI at runtime.
