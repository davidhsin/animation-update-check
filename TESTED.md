# Verification — 0.2.1 Beta

2026-10-29. Godot 4.7.2 stable, macOS 27.0.1, Apple Silicon.

37 developer checks passed (29 existing cases plus 8 path cases); player and SpriteFrames resource fingerprints stayed unchanged during each check. These are synthetic developer cases, not independent customer tests. Other versions and operating systems are unverified.

- unchanged
- missing_resource
- missing_player
- empty_resource
- empty_frames
- paused_fps
- infinite_fps
- shortened_events
- key_at_exact_end
- lengthened
- changed_duration
- disabled_manual_tracks
- other_sprite_same_name
- duplicate_frame_track
- continuous_frame_track
- disabled_frame_track
- noninteger_frame_key
- different_animation_binding
- binding_changes_over_time
- generic_mode_no_converter_claim
- as2p_reorder_opt_in
- as2p_partial_tracks_opt_in
- names_exact_by_default
- as2p_name_collision_opt_in
- named_library_is_reported
- new_library
- loop_change
- unattached_sprite
- invalid_animation_root

Additional path cases:

- explicit_current_directory
- unique_node_name
- absolute_node_path
- root_is_sprite
- property_only_at_root
- alias_duplicate_tracks
- other_unique_target
- nested_property_is_not_frame
