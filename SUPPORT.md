# Installation, reports and feedback

Support for this free beta is through the [itch.io project comments](https://dh-game-tools.itch.io/animation-update-check#comments). You can ask about installation, an unclear report or a reproducible check problem. There is no guaranteed response time or private project integration service included in this download.

## The addon panel does not appear

1. In the included example, import `project.godot` and open `demo.tscn` in Godot 4.7.2. It is an editor example; you do not need to run a game.
2. In your own project, confirm that `addons/update_review/plugin.cfg` exists. Enable **Animation Update Check** under **Project > Project Settings > Plugins**.
3. Select the **AnimationPlayer** node in the Scene dock. The panel appears at the top of its Inspector, not on the AnimatedSprite2D node.
4. If enabling the plugin produces an error, record the first relevant error and your exact Godot version. Other engine versions are unverified.

## The button is disabled or the report asks for inputs

Open the scene containing both nodes. Select the intended AnimatedSprite2D in the panel and provide a proposed **SpriteFrames** resource. A PNG image or an AnimationLibrary is not a SpriteFrames resource. The addon does not create or import the proposed resource for you.

## What a report means

- **Key past the new end:** a manual key is later than the proposed duration. Check whether that key should move, the animation should stay longer, or another workflow should handle it.
- **Timing needs review:** a manual key's time corresponds to a different frame index in the proposed sequence. Inspect the game to decide whether that matters.
- **No matching tracks:** confirm the selected sprite and the AnimationPlayer's root. Version 0.2.1 resolves equivalent node paths, including scene-unique names. Named AnimationLibraries remain outside this beta's scope.
- **Unsupported or duplicate tracks:** the relevant comparison was skipped; this is not a clean bill of health. Review the track setup before relying on the result.
- **No listed risks:** this does not prove that drawings, hitboxes, audio or gameplay are correct. Frame indices are not artwork identities.

Reports are snapshots. Run the check again after changing scene or resource data. The addon does not apply fixes, move keys or save animation changes.

## Report a problem

Copy this template into an itch.io comment and fill the fields you know:

```text
Addon version:
Godot version (exact):
OS and architecture:
Animation setup (AnimatedSprite2D / AnimationPlayer / global library):
Steps to reproduce:
Expected result:
Actual result and relevant warning or error:
Small shareable example, if available:
```

The panel's **Copy report JSON** button copies only after you click it. Review its contents before posting: node paths and animation names can reveal project details. Share only the relevant section when possible. A minimal example made with placeholder shapes is more useful than a full private project. Keep private art, credentials and personal information out of public comments.
