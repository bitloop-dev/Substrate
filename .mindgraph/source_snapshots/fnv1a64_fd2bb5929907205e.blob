# Headless semantic traces

Actions: run Bitloop development builds headlessly, list/select stable scene IDs, supply configuration overrides, advance a fixed timestep and record bounded semantic JSONL traces. Choose sparse or focused frame capture; reconstruct compact delta traces before analysing them. Reuse [tracing diagnostics](../../.agents/skills/bitloop-development/references/tracing-diagnostics.md).

Prerequisites: `BITLOOP_DEV_MODE` tooling, a runnable target, supported scene configuration and implemented scene telemetry. Substrate's generated `traceFrame` hook initially has no semantic metrics; verify/implement the metrics required by the task. The framework does not supply this engine's physical oracle automatically.

Evidence: retain command/configuration, seed, scene IDs, fixed dt, simulated horizon, trace paths and observed invariants/metrics under `.codex/runs/runNNNN_YYYYMMDD_HHMMSS/`. Report numerical conclusions and their tolerances, not just successful exit or trace-file existence. Use focused tests for kernels and traces for temporal behaviour.

## Details

The [generated shell](../../Substrate/Substrate.cpp) owns Bitloop-facing hooks. Keep stable telemetry small and diagnostic serialization outside the simulation core. Inspect current hook implementation before each dependent task; this initial scaffold observation is not a permanent readiness status.

The tracing reference documents scene listing, explicit selection, launch overrides, cadence, metadata and reconstruction. Exact supported flags come from the active runner's help/source. Preserve existing run folders. If an emitted series is compact/delta-encoded, use the skill's reconstruction workflow rather than treating each row as complete state.
