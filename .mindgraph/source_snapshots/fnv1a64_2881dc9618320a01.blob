# Substrate

## Purpose

Substrate is the third attempt to build a high-performance, two-dimensional physical world for rich and dynamic biology simulations. Many soft, active organisms should be able to move, feed, grow, compete, cooperate, suffer damage, reproduce, and change their surroundings over long recorded experiments.

The central achievement is a useful living world. Its richness should come from interactions between a manageable set of physical and biological processes: a membrane contains nutrients; muscle consumes fuel and deforms tissue; a pump moves fluid; a wound changes transport; a chemical gradient changes behavior; available food changes growth. These interactions should produce consequences that were not individually scripted.

Performance is part of the product's meaning. An impressive isolated material demonstration is insufficient if hundreds of active organisms cannot share the same world for useful simulated durations.

This vision carries forward OrganicEngine's `VISION_V2.md`, informed by the recorded results of PhysicsEngine (V1) and OrganicEngine (V2). Substrate is a new project, not a rename of their implementations or an acceptance of their unfinished work. The physical requirements below define its direction. Numerical methods and the proposed workload thresholds still need explicit, evidence-backed decisions in its own plan.

## What The Previous Attempts Taught Us

Both predecessors produced useful foundations and failure cases. Neither demonstrated the intended active biological world at its required scale. Substrate should preserve those lessons without inheriting the cost or assumptions of their implementations.

| Recorded lesson | Consequence for Substrate |
| --- | --- |
| V1 established useful fixed-time, collision, containment, rollback, and replay behavior, but dense rigid contact and recovery work dominated difficult contained-particle scenes. Its provisional 8x full-step speedup remained unmet despite local multicore and SIMD gains. | Choose representations for tissue and fluid early. Benchmark whole simulated intervals, including contact and recovery tails, before optimizing individual kernels. A fluid need not be a pile of rigid discs. |
| V1's large sparse or sleeping populations are different workloads from internally active organisms. Its sleep rules themselves distinguish rest from circulating or rearranging contents. | Count sensing, metabolism, contraction, transport, and internal motion as activity even when the organism's center is stationary. Sleeping cannot supply the principal performance claim. |
| V2 separated material meaning, topology, identity, and numerical storage, but its coupled surface model still allowed private samples to collapse and the usable timestep to deteriorate. Passing ordinary regression suites did not satisfy the separate physical adoption gates. | Test complete coupled trajectories and feature degeneracy. A green regression suite, attractive picture, or bounded total energy cannot override a failing physical gate. |
| V2's million-sample bulk screen took about 4.597 seconds per tick on one CPU worker, before surface, thermal, adaptation, and boundary work. A no-op complete transaction alone cost about 48.58 ms. | Representation, neighborhood construction, staging, safety scans, and memory traffic are first-class costs. A fast force kernel cannot rescue an unaffordable complete step. These historical short screens are rejection evidence, not endurance benchmarks. |
| V2's later experiment closed global volume and numerical work accounts while transporting local volume incorrectly. Its bounded correction still cost about 103.808 ms per million-sample bulk tick on 16 workers against a 10.42 ms budget. | Geometry, transported amounts, pressure, and work must describe the same material. Check local physical fields independently of global balances, and reject methods that fail either behavior or complete cost. |
| Features accumulated before the essential organism workload was proven. Later fixes risked preserving an unsuitable foundation through increasingly elaborate corrections. | Prove an inexpensive coupled organism early. Give uncertain numerical choices bounded experiments and rejection conditions. A well-recorded negative result is useful progress; it is not adoption of the candidate. |

The old sources are historical evidence and possible sources of independently validated ideas. They are not runtime dependencies, architecture templates, or prerequisite roadmaps. The source record is identified in [the migration and readiness assessment](docs/MINDGRAPH_READINESS.md#historical-sources); the lessons above stand on their own when Substrate is cloned separately.

## The World We Want

An organism is a physical construction with locally meaningful parts. Flexible skin encloses material; tissue transmits forces; contractile fibers change shape; stiff structures support loads; channels and permeable surfaces move substances. Local energy and resources constrain activity, growth, and repair.

A useful early world should demonstrate materially different constructions using the same rules: a crawling contractile body, a swimming membrane organism, and a chambered body that pumps and transports nutrients. These demonstrate composition. The physics core must not contain special swimming, feeding, predator, or organism-type physics.

The environment should contain terrain, obstacles, fluid motion, nutrient patches, waste, and chemical signals. Organisms disturb the medium, consume local resources, leave material behind, and encounter each other. Shared flow, contact, and competition for resources matter; isolated noninteracting demonstrations cannot establish world-scale success.

Later, local construction and control rules should support heredity, mutation, growth, repair, reproduction, and ecological change. Evolution should operate on physical capabilities and resource costs. It must not reward access to solver settings, free numerical energy, privileged knowledge, or leakage through intact walls.

Authored and evolved organisms use the same physical interfaces. Sensors receive constrained local information; controllers request local actuation and transfers. A controller cannot teleport material, set arbitrary physical state, or obtain unlimited information about the world.

## One World With Affordable Representations

The world has one authoritative state and one advancement schedule, with specialized representations joined by explicit exchanges. Sharing a material vocabulary does not require storing everything as a moving particle or forcing every interaction through one universal constraint abstraction.

The preferred starting hypothesis is explicit deformable structures coupled to spatial fluid and transport fields, with inexpensive compartments where internal flow need not be resolved. This is a candidate direction to test, not an approved solver or a claim that the difficult coupling already works.

| Physical role | Starting representation to investigate | Required physical meaning |
| --- | --- | --- |
| Skin, tissue, fibers, flexible solids | Connected vertices, edges, and area-bearing elements | Shape, compliance, shear, contraction, damage, and contact at the declared scale |
| Coherent stiff structures | Rigid or reduced mechanical regions | Boundary motion, mass, inertia, load transmission, and reactions |
| Well-mixed enclosed contents | Compartment inventories coupled to actual chamber geometry | Contents, concentration, pressure, energy, and finite flux through real openings or declared permeability |
| Resolved environmental or internal flow | Grid control volumes and face fluxes | Material transport, pressure response, motion around structures, and resolved mixing |
| Heat, nutrients, waste, and signals | Amounts carried by the appropriate tissue, compartment, or fluid representation | Local storage, transport, reaction, and source accounting |
| Independently moving inclusions or debris | Discrete bodies where their motion matters | Contact, inertia, containment, and material exchange |

A conservative grid formulation with compatible pressure and moving-boundary treatment is the initial flow candidate. Compliant element or constraint mechanics with measured deformation error and bounded work is the initial tissue candidate. Familiar method names do not establish that their coupling satisfies this vision. The plan must expose their uncertainty before substantial downstream reliance.

Representations must permit varied shapes and arrangements within the supported resolution. They must not become a fixed catalogue of organs with prescribed functions. Material state, constitutive response, and numerical representation remain distinct concepts.

Use consistent two-dimensional units. Material volume means represented area unless a declared thickness is used consistently to convert it to physical volume.

### Cheap contents need an honest meaning

A well-mixed chamber can make a pressure-bearing organism inexpensive without thousands of internal samples. It is appropriate only where unresolved circulation, sloshing, stratification, and local concentration gradients do not determine the behavior being studied. Its contents still have mass and inertia; pressure and moving walls must exchange work consistently.

Use resolved internal flow where those spatial effects matter. Initial scenarios may choose their supported representation explicitly. Automatic switching is a later capability with separate conservation, field-preservation, transition-cost, and hysteresis tests.

Connected chambers do not mix instantaneously merely because a channel exists. Transport has finite rates and paired inventory changes. Rupture releases inventory through the physical transfer interface to the surrounding medium, without duplicated mass or an arbitrary invented ejection velocity.

### Geometry, volume, and transport must agree

Occupied geometry, material volume, boundary motion, flux, and pressure work must have a compatible discrete meaning. A pressure law cannot evolve a volume unrelated to the space its material occupies.

Before adoption, a candidate must preserve uniform-pressure equilibrium, transport a freely expanding reference correctly, and respond continuously when geometric support changes. Moving boundaries must displace fluid consistently. Local volume errors cannot be excused because they cancel globally.

Thin membranes remain explicit barriers to flow and transported species. A cell intersected by a membrane cannot mix its two sides through ordinary interpolation. Collision handling and field no-flux conditions must describe the same boundary, including moving corners and narrow supported passages.

Small cut cells, thin barriers, narrow channels, global pressure solves, and moving interfaces are major feasibility risks. The first coupled experiment must expose their timestep, convergence, memory, and work costs. A fast stationary bulk field does not settle the choice.

### Identity belongs to meaningful structure and material

Organisms, structural elements, material regions, and transported inventories need stable references. Dense array indices and quadrature samples do not need permanent public identity. Mixing material can be tracked through conserved species amounts and optional tracers; tracking every original parcel forever is not a default requirement.

A genome should describe deposition, bonding, contraction, transport, and repair. It should not issue commands to create solver particles or choose backends. Future growth must remain possible without building a genome language, registry, or universal extension framework now.

## Richness Through Coupled Processes

The first useful material vocabulary includes compliant tissue, contractile fibers, stiff support, sealed and permeable membranes, and a liquid habitat. It must already demonstrate two-way mechanical interaction and resource-limited activity.

Nutrients, fuel, waste, and signals can initially be a small declared set of transported quantities with simple local reaction laws. Each reaction has explicit inputs, outputs, rates, and energy meaning. This supports useful biological behavior without requiring a molecular simulator.

Growth adds material by consuming available inventory. Repair takes resources and time. Damage changes load transmission or permeability through local rules. These operations use ordinary material and topology interfaces, with the same costs for authored and evolved organisms.

Controllers, genomes, and selection live above the physics core. A minimal deterministic controller belongs in the early demonstration workload so sensing, actuation, and metabolism are exercised together. A scripted cyclic input can isolate the physics first. A general brain or evolutionary framework is not a prerequisite for accepting the foundation.

Heat and phase change remain part of the longer-term world. Local thermal storage and transport can be introduced independently of melting or boiling. Electrical transport and signaling may follow when a concrete organism requires them. Supported phase models may use continuous fractions, but a small vapor fraction must not automatically multiply mechanical degrees of freedom. Spatial phase separation needs an explicit resolution and representation decision.

Resolved free surfaces, surface tension, boiling, freezing, general fracture, and remeshing enter when a concrete organism or habitat needs them and a bounded coupled method is demonstrated. Universal material behavior must not delay the first useful organism world.

## Accuracy That Protects The Experiment

Substrate aims for physical coherence suitable for artificial-life experiments and recordings. Its default quality is a declared approximation with meaningful units, scales, and error limits. Empirical calibration to a named tissue or substance is a separate claim.

Hard requirements are:

- Advance the requested simulated interval independently of rendering and wall-clock speed. Never skip a failed interval.
- Commit only finite, valid state. Failure preserves the last valid state and its actual simulated time.
- Close material and species balances to declared floating-point tolerances, with explicit sources, sinks, reactions, and transfers. Apply the same discipline to charge when it is introduced.
- Prevent forbidden passage through intact impermeable boundaries. Permeability, channels, and rupture have explicit, measured flux.
- Pair internal mechanical exchanges with reactions. Account for external forces, supports, and actuators in the appropriate momentum and work balances.
- Expose resolution limits and unsupported conditions. Never silently erase a narrow wall, merge incompatible contents, delete difficult material, or freeze active dynamics to continue.

### Energy and approximation policy

Substrate adopts the revised direction in `VISION_V2.md`: exact mechanical energy closure is not a universal adoption requirement for every approximate solver. Measured numerical dissipation and integration error may be accepted only within a predeclared local and cumulative budget, with behavior preserved under refinement and long runs. This differs from V2's earlier strict mechanical-energy policy; it does not retroactively accept V2's failed models.

Keep physical work, stored energy, physical dissipation, and numerical residual distinguishable. Numerical loss is not automatically heat or available metabolic energy. A residual account measures error; it cannot be an energy reservoir or a global velocity correction.

Error budgets must be relative to the motions and resource flows that drive the experiment, not a large background energy that conceals them. Detect passive propulsion, cyclic energy gain, and the loss of weak but meaningful motion. Closed, unforced cases must not develop sustained unexplained energy growth.

Stiffness, density error, numerical diffusion, and damping may be traded against cost inside a published validity range. An approximation that changes whether a body swims, a pump transports material, a gradient can be sensed, or an organism can afford to move is too coarse for that experiment.

Set tolerances and rejection conditions before comparing candidates. A changed requirement or budget is an explicit human tradeoff, never a hidden response to a failing test.

## Performance Is An Acceptance Condition

Measure progress in active organisms and useful simulated time. Sample count is a work metric, not the product goal. Report full cost at equal physical duration and supported quality, including rejected attempts and retries.

The proposed reference hardware is the previously measured Ryzen 9 9950X3D workstation using up to 16 CPU workers. Record actual hardware, compiler, build mode, precision, worker configuration, and competing load. A later GPU decision needs measured end-to-end evidence; projected acceleration cannot justify adopting a failing CPU prototype.

These starting workloads come from the revised V2 vision. They are proposed acceptance targets, not measured Substrate capabilities. Freeze their geometry, coefficients, activity, minimum feature size, and quality thresholds before the candidate acceptance campaign. Do not silently promote the later workloads into immediate implementation scope.

| Workload | Active content | Throughput target |
| --- | --- | --- |
| Interactive laboratory | 16 organisms, up to 128 mechanical vertices each, two pressure chambers and 16 actuators per organism; 128 by 128 active environmental cells | At least one simulated second per wall-clock second |
| First rich world | 256 organisms at that per-organism complexity; 512 by 512 active environmental cells; four transported species plus thermal state | At least three complete calculated output frames per wall-clock second |
| Scaling ambition | 1,024 organisms at the same resolved complexity; approximately one million active environmental cells | The same recorded-simulation floor, after the first rich world is accepted |

All organisms sense, consume fuel, and actuate. The rich-world fixture includes shared flow, contact, pumping, feeding, permeable exchange, and a fixed schedule of damage and repair. Sleeping populations or isolated noninteracting boxes invalidate the workload. Also report structural bonds and elements, field work, controller work, and event rates.

One calculated output frame represents **0.02 simulated seconds**. The three-frame floor means **0.06 simulated seconds per wall-clock second**, or at most **333 ms mean per complete calculated frame**. Choose substeps from measured quality and cost, rather than inheriting V1's cadence. Include every required substep and retry.

For the first rich world, the proposed limits are **500 ms p95**, **1 second p99**, and **4 GiB of simulation memory**. Report maximum latency and reject ordinary supported events that repeatedly create multi-second stalls. These thresholds must be frozen before acceptance, including what counts toward memory.

Complete calculated-frame timing includes state preparation, spatial work, mechanics, flow, transport, controls, scheduled topology events, safety checks, and commit. Separately report rendering, recording, checkpoints, and total user-facing recording throughput. I/O cannot disappear from the delivered experience simply because it is excluded from a physics timer.

Demonstrate the full rich-world workload over at least **ten simulated minutes and 100 representative activity cycles**, extending the horizon while drift remains unresolved. Measure tails across repeated windows that include event bursts. A short large-count run is a rejection screen, not positive endurance evidence.

### Spend work where it changes behavior

Use bounded connectivity, compact hot storage, reusable scratch, and shared derived plans. Sparse storage should save empty-domain work without turning every step into an allocation or sorting campaign. Measure global pressure work explicitly; local storage does not imply a constant-cost pressure solve.

Start with a small number of fixed, supported resolutions determined by meaningful tissue thickness, passage width, concentration gradients, and deformation. Automatic refinement, coarsening, and mechanical reduction follow only when their recurring and transition costs improve the complete workload without erasing necessary state.

Slow processes may use a declared lower update rate while integrating the correct elapsed time and exchanging conserved amounts. A local contact or stiff feature must not force unlimited global refinement. Bound additional work and report unsupported conditions when the allowed representation cannot handle them.

Transactional validity requires measured staging, buffering, and reductions appropriate to the state. It does not require a full deep copy of every field at every tiny mechanical substep. Challenge the representation and algorithm before microoptimizing an unaffordable model.

## How A Candidate Earns Trust

The first physical proof joins deformable tissue, a pressure chamber, moving-boundary fluid interaction, nutrient exchange, and fuel-limited actuation. It must show useful motion and transport at representative cost. Its exact scope and numerical choices belong in an approved MindGraph work package.

Combine three kinds of evidence:

- **Physical references:** translation, rotation, uniform pressure at rest, free expansion, compression and recovery, advection, diffusion, and sealed moving boundaries.
- **Composed behavior:** swimming or crawling, a pump doing measured work, resource-limited contraction, and eventually a wound releasing contents followed by repair restoring the barrier.
- **World endurance and scale:** interacting populations, event bursts, repeated activity cycles, resolution comparisons, and long runs without drifting inventories, collapsing features, disappearing gradients, or increasing work per organism.

Visual inspection helps explain behavior, but numerical checks must inspect the authoritative physical state. A pleasing shape, conserved total, or correct dominant wave can hide local errors and unresolved modes.

Choose behavioral horizons from transport, relaxation, forcing, contact, and accumulation timescales. Run cheap hard-condition monitors throughout, with selected complete committed-state inspections and local captures around anomalies. Extend beyond the first healthy window; record why the final horizon supports the claim and what remains unknown. Startup smoke, physical validation, and endurance are different evidence.

Each uncertain method gets a bounded experiment and a clear rejection condition. If complete coupled cost or physical behavior fails, reconsider the representation before adding material features or layers of correction. Preserve useful counterexamples and test oracles when a candidate is discarded. A test that reproduces a known failure must never be presented as proof that the physical requirement passes.

Use seeded inputs, explicit restart state, and deterministic replay on a declared execution configuration to support diagnosis and recordings. Validate continuation equivalence before relying on checkpoints. Cross-hardware bitwise equality is not a default requirement; physical quality must satisfy the same published tolerances.

## Engineering And Bitloop Boundaries

Substrate owns its simulation, application shell, assets, dependencies, documentation, tests, benchmarks, and diagnostics, and must remain independently cloneable, configurable, buildable, and runnable.

Reuse public Bitloop foundational math and framework facilities where suitable. The core owns physical state, material laws, coupling, topology, and advancement; it must not depend on Scene lifecycle, ImGui, rendering, input, scenario names, trace formatting, or diagnostic file output. Organism construction, controllers, experiments, rendering, and recording consume the core.

Keep the generated `Substrate/Substrate.h` and `.cpp` as a thin Bitloop-facing shell for configuration, engine ownership, fixed-step calls, UI, input, camera, and drawing. Place new production responsibilities by authoritative data owner and pipeline phase when they first appear. Do not build speculative subsystem trees or a monolithic world/scene implementation.

Each conserved amount has one authoritative owner at a time. Exchanges transfer amounts, impulses, and work through explicit interfaces; particle, compartment, and field copies cannot simultaneously claim the same physical inventory. Specialized kernels belong to one production world. Remove superseded candidate algorithms after validation instead of keeping a backend menu.

Use Bitloop's existing headless runner, semantic traces, trace reconstruction, snapshots, and checkpoints through project-owned adapters. Keep durable safety checks in the core, and observational probes outside it. Temporary probes are guarded by `BITLOOP_DEV_MODE` and removed after their useful findings are retained. A separate MindGraph logging SDK must not become a simulation dependency.

Follow the local `AGENTS.md` and `.agents/skills/bitloop-development/SKILL.md`, loading only relevant references. Preserve user build state and use Codex-owned build contexts. Do not change framework, parent, or sibling source as an incidental task repair. Any proposed Bitloop change needs an explanation and explicit user confirmation immediately before writing it; broader ownership or dependency changes also need approval.

## Planning With MindGraph

MindGraph is the intended durable project planner for V3. Once a plan is explicitly applied there, it owns task identity, dependencies, plan revisions, review questions, outcomes, and their history. Do not copy OrganicEngine's task tree or create a competing permanent roadmap. Temporary `.codex/plans/` notes are subordinate working memory for a selected task.

This vision is input to planning; it does not create or approve a task graph, choose a numerical implementation, or authorize the whole long-term ambition at once. Keep early implementation focused on a coherent coupled proof and its decisive uncertainties. Mark genuine numerical and performance decision points for review before downstream work relies on them.

MindGraph's planner/reviewer and implementation worker have different contexts. Planning must receive the substantive physical, ownership, performance, and validation constraints, rather than only links it cannot read. Workers inspect the actual repository and use Bitloop's existing diagnostic workflow. MindGraph records and reviews the resulting observations; it is not a replacement simulator or numerical oracle.

Every executed task must retain enough evidence to explain its outcome later:

- The tested claim, acceptance conditions, affected files, and relevant source/build/configuration identity. A commit for every task is not required; distinguish dirty source state when it affects reproducibility.
- Actual commands and observations, units, thresholds, and explicitly failed, skipped, or unverified checks. For dynamics, include fixed timestep, simulated horizon, seeds, resolution, event coverage, and the horizon/stopping rationale. For performance, include whole-workload timing and active work counts.
- Paths to compact numerical summaries, traces, inspected snapshots, or restart artifacts when relevant. Preserve conclusions and decisive configurations durably; a pointer to a disposable file is not sufficient evidence.
- A concise lesson, remaining uncertainty, and whether the result challenges implementation, the numerical hypothesis, or the plan. Distinguish experiment execution from design adoption and human approval.

With MindGraph's current result contract, put decision-bearing observations in the supported `summary`, `checks[].name`, `issues`, and `plan_concern` fields of its final `mindgraph-result` block. Prose outside that block and bare artifact paths do not supply the review agent with those observations. Do not invent extra result fields. Retained raw runs stay under `.codex/runs/runNNNN_YYYYMMDD_HHMMSS/`; reduce large disposable health data before cleanup. Preserve important conclusions in the saved MindGraph evidence and, when needed for code maintenance, a focused project document or regression.

The first MindGraph use is an experiment too. Start with a supervised bounded task, check that project instructions are respected, then verify task execution, real Bitloop evidence, saved result, review, and reload as one loop. Record planner failures, missing context, misleading acceptance, evidence loss, and instruction conflicts with a minimal reproducer. Fix management problems in their owning project; do not burden the physics core with workarounds.

## Definition Of Success

Substrate succeeds when a user can construct materially different organisms from a small common vocabulary, place hundreds in a shared active habitat, and record long experiments at declared throughput. Motion has a resource cost; substances take meaningful routes; structures contain, deform, break, and heal; organisms change their surroundings; and the consequences remain stable enough to study across resolution and time.

Broader chemistry, thermal transformations, richer organisms, evolution, and larger populations then extend a useful foundation. Judge each addition by the behaviors it enables within an honest physical and computational budget, with enough recorded evidence to understand both its successes and its failures.
