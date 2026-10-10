# F-passive-spec: reconciliation audit — blocked draft

Draft 0, 2026-10-10. MindGraph task **T-reconcile**.

**Incomplete: this is a retained prerequisite audit, not a frozen or implementable
passive work package.** All five required specifications exist. Their numerical
proposals are not mutually compatible with the proposed positive fixture suite.
No reviewed resolution of those conflicts accompanies this task. The task says
to stop when a required decision is missing; dependent reconciliation and the
configuration freeze stop here. This is not a request for routine numerical
approval merely because values are labelled unapproved: there are specific
contradictions below which require selecting different fixtures, validity policy
or a physical interior law.

No input law, threshold, source, dependency or build configuration was changed.
No task outside T-reconcile was started. The working tree already contains the
earlier diagnostic pilot and design documents; those changes are preserved.

## 1. Verified inputs and project boundary

| Artifact | Actual input | SHA-256 |
| --- | --- | --- |
| F-contract | [PHYSICAL_CONTRACT.md](PHYSICAL_CONTRACT.md), draft 1.1 | 48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07 |
| F-mechanics-law | [MECHANICS_LAW.md](MECHANICS_LAW.md), draft 1 | EE2C5000A81D357CDE5F706D98F43A45C52429E543EE80333DF7964A6DF8145A |
| F-contents-law | [COMPARTMENT_LAW.md](COMPARTMENT_LAW.md), draft 1 | C05278878AE4A3DA7FFB1035662F2A4002BF0C8D098BC19CF80E41014AAF96B3 |
| F-flow-law | [STATIONARY_FLOW_LAW.md](STATIONARY_FLOW_LAW.md), draft 1 | BC2BE2E0568DFAECBE167FD5AF4C79E57A3B3957E07E65DA1BD55CB56F5DE53A |
| F-boundary-law | [BOUNDARY_LAW.md](BOUNDARY_LAW.md), draft 1 | 55AF302183C77850586133D704BD0A6139B72CFD966C7853D13229A507E13EFF |

Inspected [AGENTS.md](../AGENTS.md), the local bitloop-development skill and its
advanced-project-workflow/simulation-health guidance. Used capability IDs
**bitloop** and **simulation-health**. This is a single audit stage; the plan is
to verify prerequisites, test compatibility, and proceed to reconciliation only
if that gate passes. No delegation, runtime changes or trajectory experiment.

[CMakeLists.txt](../CMakeLists.txt) declares `bitloop_new_project(Substrate ...)`.
The [header](../Substrate/Substrate.h) and [scene](../Substrate/Substrate.cpp)
still contain only pilot tick/time observations, with checkpoint hooks returning
false. No physical kernel or coupled build compatibility is inferred from that
pilot. A build or headless run would not resolve the analytic conflicts here.

## 2. Compatibility observations

All following measurements are binary64 evaluations of the specified reference
equations, not observed runtime trajectories. Source thresholds are the current,
**PROPOSED / UNAPPROVED** input revisions; this audit does not replace them.
No random seed is used, and no simulated horizon is executed.

### 2.1 Q3 translation violates the contents screen at startup

F-contract section 5.2 prescribes the regular N=128, R=1 m polygon with
`c_x(t)=0.5 sin²(pi t/2)` m and a 2 s period. Differentiating gives
`c_x''(0)=pi²/4=2.4674011002723395 m/s²`.

For the contents law's pure translation, `v=c_dot` and
`pi_inertial(x)=-rho a_c dot (x-c)` (sections 3.2 and 6.1). The actual base
polygon contains vertices at x-c_x=+1 and -1 m. Its density is 1 kg/m² and
`c_sound²=B/rho0=10 m²/s²`. Therefore, exactly for this polygon:

```text
max |pi_inertial| = 2.4674011002723395 N/m
max |pi_inertial|/(rho c_sound²) = 0.24674011002723395
required by F-contents-law section 5: <= 0.01
```

The proposed pressure-variation screen fails by a factor of 24.674. The acoustic
crossing-time ratio is `(2 m/c_sound)/(2 s)=0.31622776601683794`, also above its
0.1 screen. Relative translation velocity is zero, so testing only the relative
Mach number would miss the failure. The prescribed motion starts at zero velocity,
but has nonzero acceleration; zero instantaneous power is not a validity proof.
The integrated polygon pressure force is still `-M a_c`, so correct global
impulse accounting does not cure the local model-validity violation.

Halving dt cannot reduce an acceleration fixed by the physical fixture. Under
the present validity policy this is an invalid configuration/startup response,
not a pressure-solver problem that bounded retries can repair. The positive Q3
qualification cannot be frozen with both these inputs unchanged.

### 2.2 Q2 compression also exceeds the same screen at startup

The prescribed scale is `R(t)=1-0.05[1-cos(pi t)]`, so at t=0,
R=1 m, Rdot=0 and Rddot=-0.05pi² m/s². For uniform affine dilation the zero-mean
inertial pressure is
`pi_inertial=-rho Rddot/(2R) [|r|²-<|r|²>]`.
The actual polygon has `<|r|²>=(2+cos(2pi/128))/6` m². Its maximum pressure
magnitude occurs at the outer vertices, giving

```text
max |pi_inertial|/(rho c_sound²)
  = (0.05pi²)[1-(2+cos(2pi/128))/6]/20
  = 0.0123419589891695 > 0.01.
```

The acoustic crossing-time ratio is again 0.3162277660 > 0.1. This is an
actual-polygon reference, not substitution of a circle for authoritative area.
It expands the known conflict beyond Q4. No inference is made here that all
other fixtures pass the contents validity checks; that audit must continue after
the model/configuration decision.

### 2.3 Previously reported Q4 and passage conflicts remain

Recalculation of F-contents-law section 6.2 gives the Q4 continuum ellipse
reference `u_peak=2.5836294154384025 m/s`, hence
`u_peak/c_sound=0.8170153582594749 > 0.1`. This preserves the continuum-reference
qualification limitation stated in that input; it is not a new polygon run.

F-flow-law section 7 R3 gives, for its supplemental no-slip channel with physical
gap 0.25 m and h=1/16 m, four cells across the gap. The selected stencil's errors
are `2/Ny²=12.5%` for flow/work and `1/Ny²=6.25%` for peak-normalized pointwise
velocity, against proposed 2% and 0.5% gates. This does not establish those errors
for the inviscid free-slip Q5 fixture. Sixteen cells across the same gap predicts
0.78125% and 0.390625%, respectively, but the flow input explicitly says that this
is not authorization to refine the whole coupled experiment or weaken its budget.
No grid selection or cost claim for that higher-quality configuration is made here.

F-boundary-law section 1 and F-flow-law section 5.3 also state that the stationary
incompressible law lacks an absolute-pressure/compressibility closure for a
sealed volume-changing resolved interior. Its compatibility equation cannot accept
nonzero total swept area in a sealed constant-density region. Selecting that law
as an automatic replacement for the invalid contents reduction would leave a
physical closure missing; a pinned pressure gauge cannot provide it.

## 3. Required decision before continuing

The missing decision is how to resolve the incompatible positive qualification
fixtures and model validity, not whether to acknowledge their existence. Supply
an explicitly reviewed amendment identifying the authoritative fixture/model
revision and treatment of the known negative cases:

* Resolve the prescribed Q2/Q3/Q4 motion scales against **all** contents validity
  screens, or specify an authorized interior model change. Do not merely weaken
  one limit until an existing case passes. A new resolved compressible interior
  would be another numerical design, outside this reconciliation task.
* Decide the quality-matched passage configuration and its place in the passive
  gate. Preserve the four-cell result as negative evidence. A fast coarse run
  cannot supply the full-cost acceptance result for a finer passing configuration.
* Identify which cases remain mandatory positive tests and which are explicit
  rejection controls. Relabelling Q2/Q3/Q4 as expected failures would change the
  qualification scope and cannot silently count as a reconciled positive suite.

The T-loop continuation approval in the earlier handoff did not approve these
numerical changes. The current T-reconcile request carries no such decision.
Neither source comments nor successful algebra scripts supply it. No applied
MindGraph plan change or human acceptance is claimed by this document.

## 4. Existing agreements retained for resumption

These are inspected input agreements, not a newly frozen execution schedule:

* Use area-based units: rho in kg/m², p in N/m, and p dA in J. Species partition
  mass. Structural mass, contents mass and resolved fluid mass have separate
  authoritative owners; component-dual inertial masses are derived partitions.
  Content inertial traction must not become a second structural mass copy.
* C-world owns candidate/commit boundaries and actual time. C-boundary supplies
  sided geometry and exchanges without inventory. One mechanics trajectory supplies
  chamber area, grid cuts, swept area, collision and pressure-work quadrature.
* The environmental disk is a p=0 reservoir with declared incoming state, not a
  sealed outer wall. Opposite membrane sides do not communicate through clipping,
  interpolation, preconditioners or small-cell agglomeration.
* Contents-to-wall work is +p dA for expansion, plus inertial traction work;
  exterior traction uses the opposite normal. Fluxes, impulses, application
  points and work are posted once to both owners. Numerical residual is not fuel.
* The boundary law orders a kinematic pressure predictor before transport, then
  body loads, viscosity and full pressure projection. Both pressure impulses/work
  enter the wall ledger. They share 200 pressure iterations per coupling pass;
  discarded passes restart from committed state and do not accumulate exchanges.
* Prefix commit is mandatory: accepted substeps remain; a rejected candidate
  changes no committed physical state/time. The application reports actual
  advancement and stops the incomplete experiment. Repeated invalid fixture
  attempts cannot be treated as a successful or frozen simulation.
* Finite transfer, fuel-limited stress and constrained sensing remain reserved
  semantic operations, inactive in passive tests. Reservations settle only on
  commit; no active algorithm or general request framework is introduced.

Still unfinished: selection/verification of the coupled nonlinear convergence
policy and staging layout; a compatible proposed configuration freeze with local,
global and low-frequency-motion gates; quality-matched cost/horizon definitions;
the full failure-injection matrix; and expected implementation/test paths. No
subsystem directories or test targets were created ahead of those decisions.

## 5. Reproducible evidence and result limits

From the Substrate root:

```powershell
./tooling/check_passive_reconciliation.ps1 -Document
./tooling/check_passive_reconciliation.ps1 -Document -RequireCompatible
git diff --check
```

The first command checks reference arithmetic, local pressure-force closure,
threshold comparisons, input/source identities and this document. The second
uses the same observed comparisons as a prerequisite gate and intentionally exits
2 when the current input set is incompatible. This is a failed readiness gate,
not a failed evaluation of its expected negative examples. The five model/quality
conditions are evaluated at startup or from analytic reference maxima; no
simulation was run, so no fabricated `.codex/runs` evidence path is supplied.
The durable evidence is this document and
[check_passive_reconciliation.ps1](../tooling/check_passive_reconciliation.ps1).

Executed on 2026-10-10 in PowerShell:

| Check | Observed outcome |
| --- | --- |
| `./tooling/check_passive_reconciliation.ps1 -Document` | Exit 0; 12 arithmetic checks pass; Q3 acceleration finite-difference error 2.02936e-8 m/s² against 1e-7, polygon-force error 8.88178e-16 N against 1e-12 |
| Same command with `-RequireCompatible` | Five condition groups incompatible; `freeze_ready=false`, script exit code 2 (confirmed by forwarding `$LASTEXITCODE` to the calling shell) |
| Document coverage, local links and whitespace | Pass |
| SHA-256 preservation checks | All five input specifications and six source/build/dependency files match their retained identities |
| `git diff --check` | Exit 0; pass (new-file whitespace is checked separately by `-Document`) |

The readiness failure is retained as a blocker. It is not relabelled as a passing
qualification because the checker correctly detected it. Other than the
finite-difference acceleration check, arithmetic tolerances are absolute 1e-12
in each stated output unit; they are not replacements for the physical screens.

Only after the missing decision is supplied can this draft become F-passive-spec
with the full usable guarantee requested by the task. No coupled implementation,
physical validation, performance result or approval follows from this audit.
