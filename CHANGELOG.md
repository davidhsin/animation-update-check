# 0.2.1 Beta — 2026-10-29

Fix target-track matching for equivalent node paths: scene-unique names (`%Sprite`), explicit relative paths (`./Sprite`), absolute paths and property-only paths on the animation root. Equivalent paths now also count toward duplicate-track detection. Properties on another node or nested resource are not treated as the sprite's frame track.

Added installation troubleshooting, issue reporting and report interpretation in SUPPORT.md. The checker still reads resources without applying changes. No new engine or OS compatibility claims.

Regression evidence: 29 previous checks and 8 additional path cases passed. Five path cases exposed the previous matching problem; three are controls.

# 0.2.0 Beta — 2026-10-29

First public beta. Added input and track validation, disabled-track filtering, optional version-specific AS2P checks, loop-change summaries, readable report windows and JSON copying. Includes two editable timing examples. Checks read resources without applying updates.
