# Behavioural horizons and temporary probes

Actions: combine focused numerical gates, cheap per-tick invariant monitors and adaptive complete-state inspections to investigate delayed, cumulative or rare failures. Route trajectory-changing work through [simulation health](../../.agents/skills/bitloop-development/references/simulation-health-diagnostics.md); use [temporary diagnostics](../../.agents/skills/bitloop-development/references/temporary-diagnostics.md) for short-lived probes.

Prerequisites: project-defined physical invariants, meaningful scales, controlled configuration/seeds and a justified simulated horizon. Monitor logic and physical oracles must be implemented for Substrate; these workflows do not imply they already exist. Put disposable probes behind `BITLOOP_DEV_MODE`, outside production hot paths, and remove them when their purpose ends.

Evidence: record dt/ticks/simulated time, timescales/event opportunities, monitor coverage, inspection schedule, worst-case observations, stopping rationale and remaining uncertainty. A short smoke run or clean final screenshot is insufficient for long-horizon claims. Preserve compact findings under `.codex/runs`; keep high-volume scratch in a manifest-owned session under the Codex build directory.

## Details

The health reference covers adaptive horizons, monitor cost, complete inspection, health-session tooling, finding reduction and cleanup. Persistent trajectory changes include initialization, solver laws, topology, RNG, precision, threading/order and checkpoint restoration. Ordinary build/UI/drawing work only needs this gate if it changes simulation state, ordering or timing.

For high-volume probes, forecast runtime/output from a representative interval; do not emit full state at every step by default. Reduce an observed failure to a rerunnable regression or clear decision with concise evidence. Keep numerical quality tests distinct from performance benchmarks.
