# Scripted input and interaction checks

Actions: Bitloop's development headless runner accepts `--input FILE` with frame-scheduled client-space JSONL events/gestures: mouse movement/buttons/wheel, keyboard transitions, touch and drag gestures. A task can replay dragging an object from A to B and inspect before/after snapshots plus semantic position/ownership checks.

Prerequisites: a compatible development build, the correct project/scene/viewport and client dimensions, implemented interaction handlers, deterministic setup and verified replay syntax in the active framework. Follow [input/events](../../.agents/skills/bitloop-development/references/input-events.md) and [camera/viewport](../../.agents/skills/bitloop-development/references/camera-viewport.md). Coordinates are client space, not world space. Event ownership, camera navigation and UI consumption affect the result.

Evidence: retain the input JSONL, launch configuration, relevant frames, resulting state observations and inspected images. A replay file or an image path alone does not prove the interaction succeeded. Substrate interaction support must be checked per task.

## Details

The local Bitloop checkout's `src/core/headless_runner.cpp` implements `--input`, `mouse_drag`/`drag`, `finger_drag`/`touch_drag`, low-level events and keyboard replay. This was source-checked when these hints were authored; no Substrate replay was executed. The current input reference explains ownership/dispatch but is not a complete replay-format manual. Inspect the parser and public input headers belonging to the active build before writing a script; do not invent fields or assume system-wide input automation.

Use [traces](../../.agents/skills/bitloop-development/references/tracing-diagnostics.md) and [snapshots](../../.agents/skills/bitloop-development/references/checkpoints-snapshots.md) together when interaction has both semantic and visual acceptance conditions. Check that required scene telemetry exists before relying on it.
