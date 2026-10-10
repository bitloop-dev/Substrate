# Visual snapshots and explicit checkpoints

Actions: capture periodic layout images or targeted scene/viewport, pixel/world-region snapshots through Bitloop's capture pipeline. Save explicit simulation checkpoints and restore selected state for reruns when the project implements serialization. Follow [snapshots/checkpoints](../../.agents/skills/bitloop-development/references/checkpoints-snapshots.md).

Prerequisites: a development build, rendering support and stable unambiguous scene/viewport selection for images; implemented save/load hooks and compatible configuration/scene IDs for checkpoints. Substrate's generated checkpoint hooks initially return false. Checkpoints are not automatic memory serialization and do not prove restart equivalence.

Evidence: inspect actual images and correlate them with semantic traces. For restored runs, compare uninterrupted versus save/restore continuation using invariants, state fingerprints or justified tolerances. Record configuration, frame/time, image/checkpoint paths and observed outcomes. Use [visual QA](../../.agents/skills/bitloop-development/references/visual-qa.md) when appearance is part of acceptance; pixels alone cannot establish physics correctness.

## Details

Check the [current shell](../../Substrate/Substrate.cpp) before planning restoration work. Retain enough authoritative state (including RNG, counters and topology where relevant); reconstruct derived caches deliberately. Estimate checkpoint size and restart savings before adding serialization for a short experiment.

Viewport-targeted snapshots follow the normal draw path and carry scene/viewport identity. A scene-only target can be ambiguous when several viewports share it. Hidden viewports need explicit render size. Use existing capture callbacks/metadata rather than a parallel image-writing subsystem.
