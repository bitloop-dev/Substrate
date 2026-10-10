# Substrate migration and MindGraph readiness

## Capability handoff update — 2026-10-03

The original assessment below predates the subsequent MindGraph implementation.
MindGraph now discovers this project's five optional hints under
[`.mindgraph/project_capabilities`](../.mindgraph/project_capabilities/), refreshes
them before requests and supplies compact actions/evidence/prerequisite summaries
to the planner, implementation worker and reviewer. Full manuals stay local;
workers follow the [Bitloop skill](../.agents/skills/bitloop-development/SKILL.md)
and its routed references. This closes the capability-awareness part of finding 1.

Read-only inspection of the actual Substrate folder found five hints, **5,740
summary bytes** and **22 fingerprinted local source files**. MindGraph's five
offline CTest suites passed, including the new discovery, bounded context,
planner/task/reviewer input capture, protocol/persistence and stale-input tests.
The diagnostic UI was checked using an isolated fake project with copies of these
hints. No live model request or Substrate implementation/simulation task was run.

For the later live pilot, select Substrate as the target **before** generating a
plan. **Planner → Inspect project capabilities** shows discovery. Check
**Generation request details**, **Codex → Captured task requests**, and
**Reviews → Captured request / evidence** for the exact prepared inputs, capability
snapshot IDs, dispatch status and results. Capturing a request does not prove the
agent used a capability correctly; that remains the purpose of the first live
plan/task review. Source changes make pending proposals/reviews stale rather than
silently applying assumptions from an earlier catalogue.

The original evidence-format, dependency-context and scheduling limitations below
still apply. Hints explicitly distinguish framework facilities from Substrate's
initially empty telemetry and unimplemented checkpoint hooks. No Bitloop source,
managed skill, predecessor project, dependency or Substrate production code was
changed by this capability integration. See MindGraph's
[capability guide](../../../../mindgraph/docs/project-capabilities.md) for the
format, limits, request fields and refresh behavior.

## Original readiness assessment

Assessment date: 2026-10-03. Scope: the local source checkouts, Substrate's generated shell and managed Bitloop skill, and MindGraph's offline host tests. No live planning request or implementation task was dispatched, no task graph was approved, and no predecessor, MindGraph, or Bitloop production source was changed.

## Verdict

**MindGraph is suitable for a supervised Substrate pilot, with an explicit context and evidence handoff. Its default behavior does not yet guarantee sufficient scientific evidence or complete dependency context. The live Bitloop execution-to-review loop remains untested.**

There is no fundamental need for a special MindGraph runtime integration inside Substrate. The implementation agent can use Bitloop's existing diagnostics and return compact observations through MindGraph's existing task-result contract. MindGraph manages the work and its review history; Bitloop produces the simulation evidence.

The new [VISION.md](../VISION.md) supplies the product direction, predecessor lessons, project ownership, diagnostic requirements, and current result-format constraints together, so it can be supplied as complete planning input. Creating this document does not configure MindGraph or make its saved vision automatically track the file.

## What Was Verified

Built the current MindGraph host and four existing test executables in a new Codex-owned `mindgraph/build/codex-substrate-readiness` directory. Used the existing installed dependencies with `VCPKG_MANIFEST_INSTALL=OFF`, initialized the installed Visual Studio developer environment, and built only the four relevant targets. No package install or dependency update was needed.

| Gate | Result | What it establishes |
| --- | --- | --- |
| `project_architecture` | Passed | Existing project/session, protocol, plan and persistence tests |
| `codex_runner` | Passed | Existing injected execution, result parsing, correlation and recovery tests |
| `plan_review` | Passed | Existing evidence, review holds, edits, stale-input protection, persistence and recovery tests |
| `planning_provider` | Passed | Existing isolated planner/reviewer configuration, provider contract and provenance tests |
| Additional offline audit fixture | Four limitations reproduced | Out-of-order submission is allowed; prerequisite details/results are omitted from the worker prompt; outside-block narrative is absent from saved evidence; an added top-level `artifacts` field invalidates the worker report |
| Substrate Bitloop agent pack | 23/23 manifest hashes match; zero differences from the checked-out canonical pack | Substrate has the canonical `2026.09.10.2` guidance, including tracing, snapshots, health diagnostics and subordinate temporary plans |

The four CTest suites completed in 47.80 seconds with zero failures. These are real tests of current code using fake external transports, not a live model or Substrate simulation run. The supplementary probe reused MindGraph's fixtures without changing its test sources or production targets. Its first attempt held its own `.mgr` input stream open on Windows and prevented the next save; closing that probe-owned stream corrected the harness, after which all four observations were confirmed.

The exact logs, probe source, observations and pack check are retained locally in [run0000_20261003_155207](../.codex/runs/run0000_20261003_155207/). That ignored folder is disposable; the important findings are retained in this document. Source hashes and reproduction commands are recorded in its `summary.json`.

Substrate's standalone build was not configured. The managed pack explicitly says matching package compatibility awaits publication; this audit does not establish installed-package compatibility. Nor does it claim that the generated shell already supplies useful physics traces: `traceFrame` is empty and checkpoint save/load return false.

## What MindGraph Already Does Well

The implementation host submits a selected task to a durable Codex coordinator whose working directory is the target project. It correlates a run with its submitted message and observed turn, keeps a local recovery journal, and distinguishes queue acceptance from completion. It does not replace the implementation worker with the isolated planning agent.

The saved `.mgr` contains accepted and proposed plans, revisions, current task results, immutable captured evidence, reviews, human dispositions, and archived plan snapshots. Autosave writes atomically, reports conflicts and write failures, and blocks further submission when persistence is unhealthy. Completion receipts survive until the owning document has saved them. These are useful foundations for learning from failed attempts.

Evidence includes task and target identity, plan and target revisions, execution attempt, observed turn, the submitted task snapshot, and the parsed worker result. A later run does not overwrite the earlier evidence. Checks are explicitly identified as worker reports, not independent verification by MindGraph.

A task's `plan_review` question or a concrete worker `plan_concern` can trigger a bounded review. Unresolved reviews hold the affected dependency branch. The reviewer can keep the plan, request repair, request investigation, or propose explicit changes. Proposed plan edits require human approval; negative experimental evidence is allowed. Acceptance of a plan edit does not certify the resulting implementation.

These observations come from the current [review loop documentation](../../../../mindgraph/docs/review-loop.md), [host architecture](../../../../mindgraph/docs/architecture.md), and the tested source paths below. Existing Snake queue experiments support the execution route, but are not proof of a Bitloop task, scientific evidence transfer, or the current full Substrate workflow.

## Gaps That Matter For This Project

### 1. Planning does not discover project constraints

`ProjectSession::apply(GeneratePlan)` sends the saved vision string. The Codex planning adapter uses an empty temporary directory, disables project-document loading, skills and tools, and deliberately excludes coding workflows. The reviewer likewise receives only its assembled input. They cannot open Substrate's `AGENTS.md`, Bitloop skill, linked acceptance files, or traces.

This separation is reasonable for a bounded planning service, but a short biological vision or a list of file paths would omit critical requirements. It could propose another application shell, an incompatible solver policy, insufficient validation, or a duplicate logging system. Updating `VISION.md` on disk alone also does not update the saved planning input.

**Pilot measure:** supply the complete new vision, including engineering and evidence constraints. Before applying a generated plan, check that its architecture and executable tasks preserve those constraints and reference the relevant local files for workers. Reconcile material changes between the saved vision and repository explicitly.

**Recommended MindGraph improvement:** capture a small, explicit project-context packet alongside the vision for generation, execution and review. Preserve its revision/hash and distinguish binding requirements from untrusted log text. Include relevant contents or summaries, not an indiscriminate copy of every skill. Do not give the planner a new unrestricted file-execution role merely to solve this handoff.

Source: [project_session.cpp](../../../../mindgraph/include/project/project_session.cpp), `GeneratePlan` at line 497; [codex_planner.cpp](../../../../mindgraph/include/backend/host/codex_planner.cpp), planning boundary at line 16 and configuration at line 103.

### 2. Evidence is durable text, not an artifact archive or numerical oracle

`TaskCheck` stores only `name` and `passed`; `TaskResult` adds summary, issues and an optional plan concern. `PlanEvidence` preserves that result and provenance. There is no enforced measurement, threshold, unit, artifact hash, horizon, command, or lesson field. The host does not open paths, verify that a trace exists, or copy screenshots into the `.mgr`.

The offline probe confirmed that a lesson placed only in ordinary prose before the result block is absent from the saved `.mgr` evidence. Adding a top-level `artifacts` property is rejected by the current parser. The complete final worker message also has a 64 KiB parsing limit. A link in `checks[].name` survives as text, but the text-only reviewer cannot follow it.

**Pilot measure:** place the claim, decisive measured values, units, thresholds, outcome, evidence paths and lesson inside supported result fields. Use `checks[].name` for concise command/result detail. Use `plan_concern` for an evidence-backed design objection. Preserve compact detailed findings outside disposable raw runs when they remain necessary to reproduce a decision. Back up the `.mgr` and any indispensable referenced artifacts together; neither Git-ignored raw folders nor a bare file link is a durable archive by itself.

**Recommended MindGraph improvement:** add a bounded evidence record for observations and artifacts, persist its contents/provenance, and explicitly forward the decision-bearing observations to review. At minimum validate local artifact existence and record fingerprints when a claim relies on them. Keep acceptance-criterion references and skipped/failed states explicit. Schema migration, validators, prompt, persistence, review input, and tests must change together; workers cannot invent new JSON keys first.

Source: [task_result.h](../../../../mindgraph/include/model/task_result.h), lines 47 and 56; [review_state.h](../../../../mindgraph/include/project/review_state.h), line 8; [codex_runner.cpp](../../../../mindgraph/include/backend/host/codex_runner.cpp), `completedResult` at line 127; [project_review.cpp](../../../../mindgraph/include/project/project_review.cpp), review input at line 135 and evidence capture at line 139.

### 3. Normal dependency readiness is not enforced, and its evidence is not handed over

The run handler checks saved state, connection/execution ownership and unresolved review holds. It does not require ordinary prerequisites to have successful current results. The audit fixture successfully submitted `consumer` while its `experiment` prerequisite was still `not_started`.

`buildTaskPrompt` includes the selected task, vision and shared architecture/assumptions/constraints/questions. It does not include the prerequisite task definitions, results, evidence, parent acceptance context, or applicable earlier review decisions, except an explicit repair/recheck's appended obligation. The fixture confirmed missing prerequisite context and result sentinels in the generated prompt.

The planner instructions assume self-contained fresh workers, while execution currently reuses a durable coordinator. Old chat history may help accidentally, but it is neither a reliable dependency handoff nor a guarantee of the latest accepted decision.

**Pilot measure:** run only a dependency-ready leaf, check prerequisite evidence and review disposition manually, and include concrete outputs/interfaces/paths in the selected task's context. Do not assume a prerequisite ID or an earlier conversation is sufficient. Keep tasks small enough to finish with their own validation and inspect each result before starting dependent work.

**Recommended MindGraph improvement:** enforce readiness at submission using current prerequisite results, recheck state and unresolved reviews; attach a bounded prerequisite/ancestor/decision packet with evidence references and useful summaries. Preserve an explicit, recorded route for investigative or repair work when it legitimately needs to run despite an unresolved foundation.

Source: [project_session.cpp](../../../../mindgraph/include/project/project_session.cpp), `RunNode` at line 438; [task_prompt.cpp](../../../../mindgraph/include/project/task_prompt.cpp), line 5; [project_review.cpp](../../../../mindgraph/include/project/project_review.cpp), `runHold` at line 198.

## Instruction Compatibility With Bitloop

Substrate already has a clean project-owned `AGENTS.md` and the canonical managed skill. It has no inherited OrganicEngine task tree, `organic-engine-development` skill, or mandatory V2 stage-selection rules. Its temporary-plan guidance is explicitly subordinate to an existing durable work package, which fits MindGraph's role. There is no need to install a second planner inside Bitloop or edit the managed pack for this audit.

Use this division of responsibility:

| Owner | Authority |
| --- | --- |
| Human-approved Substrate requirements and project instructions | Scope, physical meaning, ownership boundaries, approval requirements |
| Applied MindGraph plan and selected task | Current work package, prerequisites, acceptance criteria, review questions and history within that scope |
| Substrate architecture and source | Data ownership, interfaces and actual implementation |
| Bitloop skill and selected framework headers | Framework usage, lifecycle, build, tracing, snapshots, checkpoint and diagnostic procedures |
| `.codex/plans/` | Temporary execution memory for the selected task; never an independently advancing roadmap |

A task that contradicts physical or ownership requirements needs a reported conflict and plan correction. It must not silently change the framework, rewrite another project, relax acceptance thresholds, or broaden its scope to satisfy a graph node.

There is one concrete workflow tension: MindGraph's worker prompt says **“Do not delegate or start parallel work”** and **“Other tasks will be submitted separately.”** Bitloop's advanced workflow sometimes calls for a serial subagent or fresh invocation for substantial work. The submitted no-delegation constraint must not be bypassed. Keep pilot tasks bounded for one worker; if the required isolation or coordinated work cannot fit, report the conflict and revise the task boundary through MindGraph. A future execution-policy field could make the choice explicit, but is not required for the first small trial.

The planner's instruction not to apply coding workflows is limited to its isolated text-only planning session. It does not disable Bitloop skills in the separate implementation coordinator. Still, compliance by an actual worker must be checked in the pilot rather than inferred solely from a matching skill manifest.

## The Evidence Handoff To Use

The intended path is:

```text
Selected MindGraph task + requirements + prerequisite observations
    -> Codex worker in Substrate
    -> local AGENTS.md and routed Bitloop guidance
    -> focused tests / Bitloop headless traces / relevant snapshots
    -> inspected, reduced observations with commands and thresholds
    -> supported mindgraph-result fields
    -> immutable MindGraph evidence -> review -> explicit plan decision
```

Keep these observations proportional to the task:

| Task claim | Minimum useful retained evidence |
| --- | --- |
| Build/API wiring | Actual target/configuration, command, outcome and limitations |
| Numerical behavior | Oracle and threshold; measured values with units; scenario/seed/resolution/dt; committed simulated horizon; relevant adverse controls; observed failures and uncertainty |
| Long-running dynamics | Timescale/event coverage, monitors and selected whole-state inspections, drift/degeneracy findings, extension and stopping rationale |
| Performance | Active workload, hardware/workers/build, simulated time, complete-step/frame cost including retries, tails, memory, work counts and corresponding quality |
| Visual behavior | An actually inspected snapshot, scenario/frame, observed interpretation and paired semantic evidence where the claim is physical |
| Checkpoint restoration | Uninterrupted-versus-restored continuation comparison, not merely successful loading |
| Experiment or correction | What was tested, what was learned, whether the hypothesis passed, and which downstream decision is affected |

Bitloop already supports semantic `traceFrame`, compact traces, `bitloop trace reconstruct`, scheduled headless observation, `traceCanvas` snapshots and explicit checkpoints. Its health workflow covers horizon selection, observer controls, complete committed-state inspections and bounded anomaly reports. Use these through project-owned adapters; do not add another screenshot or trace framework for MindGraph.

`BITLOOP_DEV_MODE` is the relevant Substrate/Bitloop probe boundary. MindGraph's own `BL_DIAGNOSTIC_MODE` controls its UI diagnostic runtime; these are different systems. The MindGraph application does not need to understand simulation-specific fields or run physics itself.

Retain useful runs in Substrate's indexed `.codex/runs/` folders. Keep large immediately disposable data in the Bitloop workflow's marked build sessions, reduce it to conclusions, and clean only the owned temporary material. Keep the original raw evidence while its objective needs it. A permanent decision record or regression should preserve essential findings before raw data is discarded.

## Smallest Useful Live Trial

This is a recommended trial, not an applied roadmap or permission to start unrelated implementation:

1. Register/open Substrate as a Codex project, select that exact target in MindGraph, supply the complete vision, and save the `.mgr` inside the project. Preserve one authoritative `.mgr`; do not copy V2's roadmap. Confirm the coordinator's working directory.
2. Generate and inspect a bounded initial plan. Confirm its early numerical decision points, project/Bitloop boundaries, evidence requirements and ordinary prerequisite ordering before applying it.
3. Run one small diagnostic integration task with a specified deterministic observable. Have the worker use the current framework, produce a real semantic run and an inspected snapshot where useful, and put the measurements in the supported result block. This first run is a workflow smoke gate, not acceptance of the biological engine or a numerical family.
4. Check the stored evidence and exact review input. Confirm the reviewer received measured values and limitations, not just paths. Save/reload and confirm the task, evidence, review and artifact references remain understandable.
5. Exercise a clearly labelled negative or inconclusive experiment and a local instruction conflict. Confirm a visible concern/hold and an evidence-based next step, without silently relaxing a threshold or modifying Bitloop. Prefer offline fixtures for destructive/failure injection; the existing offline suite already covers save failure, interruption and stale proposals.

Successful completion would justify expanding the pilot. The first uncertainty to resolve is the management/evidence loop; it should not wait until a large physics task has already consumed substantial effort.

Before relying on MindGraph for sustained Substrate work, prioritize the three owner-local improvements above: explicit context capture, richer retained observations, and dependency readiness/handoff. They belong to MindGraph and can use its existing project/session/result boundaries. This audit does not authorize their implementation or a new orchestration framework.

## Historical Sources

The following are optional local provenance links, not dependencies of a standalone Substrate checkout. The new vision retains the relevant lessons without requiring these repositories at runtime or build time.

- [PhysicsEngine vision](../../CodexProjects/PhysicsEngine/VISION.md): long-term physical/biological ambition and physical interfaces for growth, sensing and control.
- [PhysicsEngine development index](../../CodexProjects/PhysicsEngine/DEVELOPMENT_PLAN.md) and [Stage 3 record](../../CodexProjects/PhysicsEngine/docs/development_plan/STAGE_3.md): dense-contact recovery, whole-step performance, accepted local improvements, unmet 8x target, and the distinction between supported sleep and internal activity.
- [OrganicEngine revised vision](../../OrganicEngine/VISION_V2.md): primary source for Substrate's active-organism emphasis, hybrid candidate, revised energy policy and proposed workloads. Its title calls it a “next edition”; it was a proposal, not an implemented V3.
- [OrganicEngine original vision](../../OrganicEngine/VISION.md) and [architecture](../../OrganicEngine/ARCHITECTURE.md): useful ownership, identity, material/topology and diagnostic boundaries; their numerical model and task tree were not copied.
- [Performance reassessment](../../OrganicEngine/docs/PERFORMANCE_FIRST_REASSESSMENT.md): measured full-step/transaction costs and limits of partial kernel results.
- [Surface decision](../../OrganicEngine/docs/SURFACE_TENSION_NUMERICAL_DECISION.md): coupled degeneracy despite focused passing tests, refinement and long-horizon failures.
- [Carrier-volume decision](../../OrganicEngine/docs/CARRIER_VOLUME_DECISION.md) and [OE-0053 contract](../../OrganicEngine/docs/development_plan/tasks/OE-0053.md): global closure without local physical correctness, unchanged failures under smaller dt, negative adoption decision and full-cost rejection screen.
