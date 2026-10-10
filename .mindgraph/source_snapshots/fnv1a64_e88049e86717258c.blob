# F-boundary-law: sided moving geometry and cut-cell exchanges

Draft 1, 2026-10-10. MindGraph task **T-design-boundary**.

This specifies one candidate: explicit sided polygon cuts, space-time swept-area
accounting, and conservative same-side control-volume agglomeration. It is a
design for the existing owners, not another simulation or a qualified solver.
**All added thresholds, caps and example parameters are PROPOSED / UNAPPROVED.**
Inherited numerical proposals remain unapproved. No fixture, material law or
acceptance budget in the inputs is changed.

## 1. Inputs, ownership and compatibility

Inspected inputs are [F-contract draft 1.1](PHYSICAL_CONTRACT.md),
[F-mechanics-law](MECHANICS_LAW.md), [F-contents-law](COMPARTMENT_LAW.md), and
[F-flow-law](STATIONARY_FLOW_LAW.md). Their SHA-256 identities are retained in
section 9. The [current scene](../Substrate/Substrate.cpp) has diagnostic tick/time
counters only and checkpoint hooks returning false. There is no cut-cell runtime
to test. `bitloop_new_project(Substrate ...)` is the application entry in
[CMakeLists.txt](../CMakeLists.txt); this task requires no build or dependency change.

| Owner | Inputs/outputs at the coupling boundary |
| --- | --- |
| C-mechanics | Owns oriented structural topology, positions, shape functions, structural momentum and the proposed continuous wall trajectory; receives integrated loads at the same physical points |
| C-contents | Owns compartment amounts, circulation/kinetic closure and compression energy; evaluates pressure from the actual polygon area and returns mean plus inertial traction |
| C-fluid | Owns resolved primal inventories and component momenta, performs transport/viscosity/pressure solves and conservative remaps; no resolved inventory occupies a well-mixed chamber |
| C-boundary | Derives fragments, aperture intervals, side connectivity, area/moment integrals, sweeps, aggregation maps and force/work maps; owns no material, momentum or energy reservoir |
| C-world | Stages one candidate, settles paired exchanges, validates, commits accepted prefixes and preserves actual committed time after failure |

Lengths are m, area is m², density kg/m², pressure N/m, force N, impulse kg m/s
and work J. There is no hidden thickness. A thin membrane excludes zero area but
has two distinct sides. Tissue and solid supports exclude their actual area.
Stable structural/material/domain/support IDs and generations identify physical
objects. Cut fragments, aggregate rows and dual-volume indices are derived,
revision-tagged objects, not permanent material IDs.

This design retains the mechanics law's midpoint trajectory and dry contact
limits, the contents law's real inertia and pressure law, and the flow law's
staggered momentum, donor transport, symmetric backward-Euler viscosity and
PCG/IC(0) projection. Sections 3–5 specify the additional geometric operations
needed for moving cuts; stationary full cells reduce to the flow specification.

Two existing negative predictions remain decision-bearing:

* The supplemental no-slip channel of width 0.25 m at h=1/16 m has predicted
  flow/work error 12.5% and pointwise velocity error 6.25%, exceeding the flow
  law's proposed 2% and 0.5% gates. This is not a measured error for free-slip Q5.
* Q4's rotating ellipse requires 2.583629415 m/s in the contents law's irrotational
  reference, giving speed/c=0.817015358 versus its proposed 0.1 validity screen.
  Geometry conservation cannot make that reduction valid.

The stationary incompressible law also does not provide an absolute pressure or
compressibility closure for a sealed, volume-changing resolved interior. Such an
interior is **unsupported by this combination of laws**. Do not use a pressure
gauge as a wall load or convert the chamber to a resolved region automatically.
Fixed-wall internal flow remains supported as specified by F-flow-law. A suitable
physical interior closure or a reviewed fixture change precedes qualification of
the incompatible rotating/volume-changing cases; neither is supplied here.

## 2. Sided geometry and the swept-area identity

### 2.1 Cuts and connectivity

Intersect the actual structural segments and analytic support boundaries with
each Cartesian primal cell and each shifted x/y momentum dual cell. A fragment
is one connected fluid portion, including its material/domain and barrier-side
incidences. A cell can contain several fragments. Store oriented boundary loops,
area, centroid and second moments, wall facet provenance, and ordered open
intervals on Cartesian faces. Use polygon moment integrals; integrate analytic
capsule arcs consistently for both collision and fluid geometry. An independently
bounded arc approximation is acceptable only if collision uses that identical
approximation and its error fits the contract's geometric budgets.

Pair an open face interval only with the geometrically coincident interval in
the neighbouring cell and the same physical fluid domain. Positive length and
an unobstructed path are required. A point or corner touching is not connectivity.
Matching component names alone are insufficient: opposite sides of a membrane
must not acquire an edge even if fluid can reach the other side around a distant
tip. Closed chamber loops are watertight. No pressure, transport, viscous,
reconstruction or preconditioner stencil may tunnel through a barrier.

Use filtered orientation/intersection predicates with a bounded exact-predicate
fallback, deterministic tie ownership at grid lines, and explicit degenerate
event handling. Never snap two distinct walls together to simplify clipping.
If classification cannot establish sided connectivity, reject with the affected
stable IDs and grid coordinates. Zero-area bookkeeping records may represent an
event, but cannot own inventory or become a solver denominator.

### 2.2 One trajectory, one sweep

Use the same candidate trajectory as mechanics. Free vertices use its linear
path q(s)=q0+s(q1-q0); prescribed supports use their declared continuous motion.
Split integration at facet/grid incidence events. Bounds are 64 event roots per
affected cell per attempt and 64 root refinements per root. Ambiguous/coincident
events are processed as a batch; exhausted bounds reject, never omit a sweep.

For a fixed Cartesian cell, n is outward from its fluid fragment. Define:

```text
S_i = integral_t integral_moving_wall w dot n dl dt = A_i1 - A_i0
F_ij = integral_t integral_open_face u dot n_i dl dt = -F_ji
sum_j F_ij + S_i = 0                            (constant-density GCL)
M_i1 = M_i0 - sum_j mass_flux_ij                 (sealed wall flux is zero)
```

F and S are areas, not masses. Internal cut-support boundaries are also included
when a fragment changes identity. Follow their incidence through the event or
use the aggregate space-time union from section 3. A fragment birth/death is not
creation/destruction of physical material.

With uniform density, mass_flux=rho F gives M_i1=rho A_i1. **Do not also post
rho S as a wall mass transfer.** That double-counts displacement. A sealed wall
has exactly zero relative constituent flux by topology. Open Cartesian faces
carry displaced fluid; physical opening transfers, if present, use one explicit
finite packet with the contents law's amount, momentum and enthalpy accounting.
An opening is never inferred from a small cut fraction or solver difficulty.

Compute S by integrating the moving facets and independently compare endpoint
areas. For a linearly moving polygon, whole-loop area is quadratic in s, so its
midpoint area gradient integrates exactly. Within a grid cell, incidence changes
require event splitting; an old normal times an old length is not sufficient.
Geometric changes are shared by inventories, pressure, reconstruction and images.

## 3. One small-cell treatment: conservative same-side agglomeration

### 3.1 Selection and bounded size

Agglomerate primal fragments whose minimum area along the attempted trajectory
is below theta h², with theta=0.25. Apply the same rule independently to each
component's momentum dual fragments. Include fragments that appear/disappear in
the attempted interval. Select neighbours through positive-length open apertures
only, in descending minimum aperture measure, with grid/side IDs breaking ties.
No edge across a sealed wall, solid, point contact or different inventory domain
is eligible. An aggregate must remain connected throughout every open event
interval and have area at least theta h² throughout. Endpoint connectivity at
zero-measure events is interpreted by its one-sided limits.

Limit an aggregate to 8 Cartesian cells and diameter 3h. If a valid group cannot
be made within those limits, return `unsupported_small_region`. An isolated fluid
pocket is not deleted, merged across a wall or declared well-mixed. A region
whose total volume vanishes cannot be advanced as incompressible sealed fluid.

Freeze the selected union for the whole candidate interval. Preserve it between
accepted steps while valid; permit dissolution only when each remaining fragment
stays above 0.5h² over the next trial. This hysteresis reduces gratuitous regrouping;
it does not waive continuity tests or authorize stale adjacency. Rebuild if any
side, aperture or support revision changes. Topology invariants are checked before
and after aggregation and on every geometry event.

This is the sole stabilization. There is no volume clipping, artificial wall
permeability, density reset, pressure diagonal shift or fallback redistribution
through arbitrary neighbours. C-world's existing bounded timestep retries remain
available but are not a second representation.

### 3.2 Inventories and support transitions

Store each aggregate's constituent amounts once in C-fluid. The aggregate area is
the sum of its actual fragments; local reconstructed amount is q_i=q_G A_i/A_G.
This reconstruction is piecewise constant and explicitly introduces subgrid
mixing **within that connected same-side aggregate**. The aggregate length scale
and this loss of concentration resolution must be reported. A narrow biological
gradient cannot be qualified merely because its total amount is conserved.

External aggregate faces use one antisymmetric donor flux. Internal faces cancel
from the aggregate update. Enforce the flow law's outgoing mass fraction <=0.5
on each primal aggregate and reject negative constituent amounts without clipping.
Retain a conservative fine-fragment flux reconstruction
for local geometric/oracle checks: prescribe the fragment endpoint amounts above,
compute each fragment's deficit after its external fluxes, and route the deficits
on a deterministic spanning tree of actual internal open apertures. A leaf posts
its deficit on its unique parent edge and is removed; the final root deficit must
be zero to roundoff. Route separately on event intervals where connectivity differs.
This is a diagnostic/resolution of the aggregate balance, not a second material
update. Record internal mixing amounts and distinguish them from physical channel
transport. Do not claim a resolved fine velocity from this prolongation alone.

Before changing aggregation at a fixed physical instant, remap by actual same-side
intersection areas. For old group a and new group b, transfer
`q_(a->b)=q_a area(a intersect b)/area(a)`, once per constituent. Intersection
columns partition every old group; rows partition the new support. Check these
partitions before posting. A disappearing fine fragment's amounts remain in its
connected aggregate or leave through accounted open faces; no final deletion is
allowed. Newly uncovered support is supplied by that same update, never filled
from a default rho or a remote nearest cell. A group that reaches zero area with
any nonzero amount rejects. No transfer to a geometrically disconnected newborn
group is manufactured.

The local fine-fragment divergence test uses both actual external fluxes and the
explicit internal prolongation; also check the independent reconstructed velocity
normal trace on each physical wall. A good aggregate residual alone is insufficient.

### 3.3 Momentum and interpolation compatibility

Keep the x and y staggered momentum partitions distinct. For component dual group
d derive its inertial mass from primary inventories with overlap weights:

```text
w_di = area(dual_d intersect primal_i) / area(primal_i)
m_d = sum_i w_di M_i;      sum_d w_di = 1 for each component separately.
P_d = m_d u_d;             K = sum_d P_d²/(2m_d).
```

The two component mass partitions are not two physical masses. Nonpositive m_d
rejects before division. Same-side geometric intersections are required even where
both sides occur in one original Cartesian dual cell. At a regrouping instant,
remap component momenta with the same positive overlap map as their derived mass.
Verify that remapped dual masses agree with masses derived from the remapped
primal inventory to the contract's local mass tolerance. A mismatch rejects;
neither partition may overwrite the other to conceal an inconsistent remap.
Linear momentum then closes; the kinetic loss of averaging is numerical remap
dissipation and is never heat or fuel. Check angular momentum using actual first
moments: a remap that exceeds the contract's angular budget rejects rather than
inventing an untracked couple.

For transport, lift the primal mass fluxes to each dual graph. Start with the
flow law's half-sum construction on uncut faces; on cuts use the corresponding
geometric overlap integrals. Enforce the exact required dual mass change
`m_d1-m_d0` from the updated primal state by a same-side graph flux correction:
minimize the aperture-weighted squared correction subject to those dual balances,
with one oriented unknown per open dual edge. Zero-aperture edges are absent.
This is a constrained mass-flux construction, not a density correction. Its
graph Laplacian has the same per-component compatibility/gauge checks and a
200-iteration cap. Use the original balance residual, including the pinned row.
No feasible solution, incompatible total, invalid factor or cap exhaustion rejects.
Apply the resulting single mass flux to donor component velocity; enforce the
flow law's outgoing mass fraction <=0.5 on the stabilized dual groups. Count
flux-lift work, correction norm, numerical mixing and momentum/work residuals.
In uncut stationary cells the correction is identically zero.

Map dual velocities to open aperture integrals by a same-side affine-reproducing
least-squares reconstruction: reproduce a constant and the two coordinate fields
at the aperture centroid, starting with the ordinary MAC face value. Use only
visible dual centroids within 3h, at most 12 per component, and the minimum
Euclidean correction to those initial weights satisfying the three moment rows.
Use rank-revealing QR, not normal equations; reject rank deficiency, scaled
condition number >1e6 or weight L1 norm >4. These bounds are proposals. Full
uncut faces use the exact original MAC stencil. Use the transpose of this same
linear map for pressure forces. Uniform translation and rigid-rotation virtual
work tests must pass; independently reweighted gradients are forbidden.

For cut viscosity, reconstruct symmetric strain on the same sided local geometry,
integrate it with nonnegative area weights, and assemble its transpose product.
Use actual wall distance and the declared slip condition; eliminate prescribed
wall velocities and return their reaction through that same operator. Preserve
the flow law's full-grid/no-slip stencil, including its documented error. Failure
to construct a bounded strain stencil is unsupported geometry, not permission to
filter across a membrane. Discrete physical dissipation and backward-Euler loss
remain separate. These constructions must be implemented and qualified; an
area-weighted diagram alone does not prove momentum or energy compatibility.

## 4. Pressure traction, work and coupling passes

### 4.1 Discrete geometric work map

Let C be the path-integrated area derivative with respect to structural generalized
coordinates, with one row per fluid aggregate. Integrate physical facet normals
and structural shape functions on the same event-split path. Then:

```text
S = C Delta q
J_wall = delta C^T p             W_fluid_to_wall = p^T S
J_fluid_pressure = delta (B^T p - b_p)
```

p is the pressure associated with the interval solve, piecewise constant on an
aggregate. B is time-averaged integrated divergence formed from the actual open
apertures and the section 3 reconstruction. b_p is the pressure-reservoir force
vector. Prescribed support coordinates use their actual path integrals; for
nonlinear prescribed motion do not replace work by endpoint velocity times impulse.
Post facet impulses, application points and work once to C-mechanics and with the
opposite sign to C-fluid. Include external reservoir/support ledgers. Test constant
translation/rotation virtual modes for force and torque balance, not only p dA.

For a chamber, use its entire actual polygon area and its own orientation. The
contents law supplies mean pressure and inertial pi. At fixed mass, a finite
mean pressure `p_sec=-(U1-U0)/(A1-A0)` gives exactly `Wmean=-Delta U`; its continuous
limit is pbar. Integrate pi against the same wall trajectory, and compare its
work with `-Delta K_contents` under that law. Applying pbar alone omits inertia.
Exterior traction has the opposite geometric normal and its own pressure field.
Do not double-count content added mass in the structural mass matrix.

### 4.2 Moving extension of the stationary flow stages

Freeze candidate geometry/maps within each outer coupling pass. Set
`q_wall=S/delta`; include known reservoir velocity fluxes in q_N. On these maps,
use the flow law's projection equations with `q_N=q_wall+q_known`:

```text
A_p = B M_d^-1 B^T
b = -(B u* + q_N)/delta + B M_d^-1 b_p
u+ = u* + delta M_d^-1 (B^T p - b_p)
Delta K - Wp = -0.5 ||u+-u*||²_Md + delta p^T(Bu+ + q_N)
Wp = -delta (b_p^T u+ + p^T q_N).
```

This identity applies with M_d fixed **within that pressure stage**. Account mass
changes, transport and remapping in their own stages. The wall term is `-p^T S`,
exactly the opposite of the work posted to mechanics. The remaining pressure
projection loss is numerical, and an incomplete solve leaves the displayed
residual; neither may be converted into material energy.

Moving geometry requires an additional kinematic predictor before the stationary
law's donor transport. Project the old velocity onto the above swept continuity
constraint, using homogeneous pressure-increment data at pressure reservoirs.
Transport with that compatible predictor's open-face fluxes. Then apply body
loads, backward-Euler viscosity and the ordinary full-pressure projection, using
the same geometry and q_wall and the updated derived masses. Both projection
impulses are real changes to fluid momentum and both post their respective wall
impulse/work; do not retain only the second load. Their numerical losses are
reported separately. In stationary full cells with a valid divergence-free old
state, the predictor correction is zero and the original ordering is recovered.

The staged velocity representation and divergence tests refer to these space-time
apertures. Endpoint wall traces are reconstructed with the actual endpoint wall
velocity; check their relative normal error separately. Do not describe an old
geometry divergence or a final image as evidence for the swept flux condition.
Splitting and time-level errors must converge under the contract's temporal
refinement tests. No extra unaccounted final velocity projection is permitted.

Rerun the whole pass from committed state if the received fluid/content loads
change the mechanical trajectory. Do not accumulate discarded pass impulses or
settle fuel during trial passes. At most four outer passes; require geometry,
loads, local work accounts and committed-state validity simultaneously. A valid
geometric update alone cannot commit while a coupled solver is unconverged.

### 4.3 Nullspaces and limits

Use PCG/IC(0), deterministic ordering and true residuals as in F-flow-law. Each
projection is bounded by the remaining part of a shared 200-iteration allowance
per coupling pass, preserving the contract's cap (at most 800 pressure iterations
per attempted substep). The two projections do not receive separate allowances.
The flux-lift solve has its separate 200-iteration cap per component. No diagonal
shift or fallback solver is implied. Check rank/compatibility before solving.
Each closed connected component has its own constant nullspace; net prescribed
sweep plus exterior flux must be compatible. A sealed incompressible cavity with
nonzero net area change fails, even if deleting its smallest cell would allow a
linear solve. Open environmental reservoirs supply the finite displaced outflow.
Pressure gauges in sealed internal domains do not supply absolute wall pressure.

## 5. Collision agreement, continuity and failure

Use the very same structural segments, capsule surfaces, poses and swept paths
for collision and fluid barriers. Continuous collision checks prevent crossing
between endpoints; endpoint separation alone is insufficient. Wet clearances
must stay at least **0.25 m** at all times, including capsule corners and rotating
features. This physical limit stays fixed on grid refinement. Mechanics' dry
contact treatment does not authorize fluid-gap closure, drainage, lubrication or
wet impact. Reject before crossing the supported gap. No smoothing, aggregation
or tolerance-based surface snap may move the actual collision surface.

Inherit the contract's displacement <=0.25h, fractional chamber area change <=1%,
four halvings, 512 attempts per H=0.02 s and prefix-commit semantics. Geometry
events inside an attempt are integration pieces, not additional committed time.
All failed attempts leave committed inventories, momentum, geometry, allocator,
time and physical accounts unchanged. Retain previously accepted substeps and
report their actual time. Return the first decisive reason and offending IDs:
`ambiguous_cut`, `unsupported_small_region`, `unsupported_wet_gap`,
`incompatible_component_volume`, `nonconverged_pressure`, `invalid_reconstruction`,
`unsettled_exchange`, or an inherited mechanics/contents validity failure.

Retain aggregation hysteresis and accepted pressure/velocity reconstruction state
in explicit checkpoints if they affect continuation, plus source/configuration
identities and the physical states required by the input laws. Derived geometry
may be rebuilt only by an identified deterministic procedure. Checkpoint hooks
are not implemented by this document.

Required continuity tests for implementation:

1. Translate the same membrane and corner across cell faces/vertices with offsets
   epsilon/h=1e-2, 1e-4, 1e-6, and the exact incidence event, in both directions.
   Compare one-sided limits of local amounts, force, torque, pressure and work.
   Repeat with a rotation and with reversed structural/grid enumeration.
2. Sweep cut fractions across theta=0.25 and dissolution=0.5 while holding the
   physical trajectory fixed. Compare forced valid alternative grouping histories.
   Conservation is required for each; differences in observable loads and fields
   remain within the contract's budgets and decrease under refinement. No fixed
   jump can be excused as a bookkeeping change.
3. Keep two differently tagged species on opposite sides of a translating
   membrane. Check every route, every constituent posting and independent wall
   normal traces. Zero signed global leakage does not pass a two-way leak.
4. Test a tiny isolated pocket, a zero-length aperture, a wet gap below 0.25 m,
   ambiguous intersection, nonpositive IC pivot and exhausted solver cap. Verify
   rejection with the last committed state/time unchanged, never a disappearing
   wall, erased amount or frozen motion. These are negative controls.

Use all F-contract section 6 budgets without relaxation: local area error
<=1e-7 h² and each nonzero fragment relative error <=1e-5, global area error
<=1e-8 A*, accumulated absolute sweep mismatch <=1e-6 A*; actual forbidden
transfer exactly absent; facet normal-flux error <=1e-8 U* times length.
Local volume defect is <=1e-8 actual fragment area per substep and divergence
defect <=1e-6 s^-1. Mass/impulse, local and cumulative energy, deformation and
force/torque/work budgets also apply. Agglomeration never changes their denominators.

## 6. Worked geometry and account references

These are binary64 arithmetic oracles, not executions of a flow solver. Use
h=1/16 m, delta=0.00125 s and rho=1 kg/m² unless stated. Local cells below are
geometry primitives; their width is not a physical passage below g_min.

### B1. Moving corner: keep the cross term

In one h by h cell a solid occupies [0,a] by [0,b]. Initially a=b=0.5h;
then a1=0.51h, b1=0.505h. The remaining L-shaped fluid is one connected fragment.
The solid area increases by 0.00755h²=2.94921875e-5 m². Fluid area decreases
from 0.75h² to 0.74245h². Integrating the moving vertical and horizontal faces:

```text
S_fluid = -[(b0+b1)/2 Delta a + (a0+a1)/2 Delta b]
        = -2.94921875e-5 m².
```

Uniform u=(0.5,0.25) m/s has the required free-slip wall normal motion. Integrate
its flux through the actual outer apertures: top/right outflow less left/bottom
inflow is +2.94921875e-5 m². Thus Delta M=-2.94921875e-5 kg,
Delta P=u Delta M, and Delta K=0.5|u|² Delta M=-4.608154296875e-6 J, all carried
by open-face advection. At uniform p=2 N/m, wall work pS=-5.8984375e-5 J; the
work delivered to the reservoir is its opposite. In the fluid ledger, wall work
input and reservoir pressure work output cancel. They do not replace advected energy.

Using old facet lengths gives 0.0075h² and misses Delta a Delta b=
1.953125e-7 m², far above the proposed 1e-7h² local geometric budget. This
deliberately wrong sweep is a negative control, even though endpoint drawings
would show the correct final corner.

### B2. Thin membrane: support birth and death on separate sides

Take adjacent cells [0,h] and [h,2h], each of height h, with a vertical membrane
extending past the patch. Move it from x0=0.995h to x1=1.005h at 0.5 m/s.
Tag left-side fluid with Y=1 and right-side fluid with Y=0. Supply matching
uniform velocity at the left/right reservoirs. There is no membrane opening.

| Fragment | A0/h² | A1/h² | Net open F/h² | Delta M/rho/h² |
| --- | ---: | ---: | ---: | ---: |
| left in cell 0 | 0.995 | 1 | -0.005 | +0.005 |
| left in cell 1, born | 0 | 0.005 | -0.005 | +0.005 |
| right in cell 0, disappears | 0.005 | 0 | +0.005 | -0.005 |
| right in cell 1 | 1 | 0.995 | +0.005 | -0.005 |

The grid face x=h carries right-side flux during the first half-interval and
left-side flux during the second: each is 0.005h²=1.953125e-5 m². They are
different sided records. Outer inflow and outflow are each 0.01h²=
3.90625e-5 m². Every row satisfies F+Delta A=0; total mass is unchanged, left
mass increases only from its reservoir and right mass decreases only to its
reservoir. Newly uncovered fragments do not receive the opposite-side tracer.
Merge the 0.005-fraction support only with its same-side neighbour.

For p_left=2 and p_right=0.5 N/m, force on this membrane segment is 0.09375 N
to the right, impulse 0.0001171875 kg m/s and work 5.859375e-5 J. Left/right
wall pressure work is respectively +7.8125e-5 and -1.953125e-5 J. Support and
reservoir ledgers close the prescribed-motion case; an unforced wall must instead
respond dynamically. A shared Cartesian cell index cannot justify pooling its
two fluids. The checker demonstrates that such pooling contaminates the tagged
sides even while conserving total mass.

### B3. Narrow supported passage: conservation is not accuracy

Retain the supplemental stationary no-slip channel from F-flow-law: length 2 m,
gap H=0.25 m, mu=0.1 kg/s, pressure-gradient equivalent G=0.1 N/m², periodic
axial flow with a metered body force. The selected stencil gives

```text
Q = G H³/(12 mu) = 0.00130208333333333 m²/s
Q_h = Q + G H h²/(6 mu) = 0.00146484375 m²/s
power_h = G length Q_h = 0.00029296875 W.
```

Mass through two cross-sections is equal and opposite. Discrete drive power and
the stencil's viscous dissipation agree, yet Q_h is 12.5% too large. At 8 and
16 cells across the same physical gap the errors are 3.125% and 0.78125%; the
corresponding peak-normalized velocity errors are 1.5625% and 0.390625%.
The base case therefore fails the proposed quality gates without any leakage.

Translate both walls together by the offsets in section 5, preserving H. Cut
slivers join only fluid inside the passage; never join through either wall.
Compare flux, pressure drop and work to the same reference, including grouping
transitions. Then narrow below 0.25 m: the supported outcome is a bounded failure,
not a silently sealed passage or a pressure connection through solid. This task
does not authorize adopting finer resolution or changing the gates.

### B4. Freely expanding chamber: actual polygon and paired work

Use the actual Q1 N=128 polygon, R0=1 m, A0=(N/2)sin(2pi/N)=
3.140331156954753 m², M=1.1A0 kg, rho0=1, B_bulk=10 N/m. For a short geometric
slice R=1 to R1=1.000125 m, actual Delta A=A0(R1²-1), about
7.851318569e-4 m². All 128 facets have the same integrated sweep Delta A/128.
The contents mass remains M. The exterior's total cut area decreases by Delta A
and its reservoir carries rho_f Delta A outwards. No mass crosses the membrane.
An initial exterior tracer remains exterior.

Use U(A,M) from F-contents-law. Its secant pressure gives p_sec Delta A=-Delta U
exactly to arithmetic tolerance. Differentiating the polygon shoelace area at
the midpoint vertices gives the same work and paired vertex forces. Using pi R²
in the pressure law while clipping the polygon produces a relative area mismatch
of about 4.0174e-4; it is not harmless quadrature at the contract's area budget.

This finite slice verifies geometry and mean compression work only. It is not
a constant-speed physical expansion solution. For the independent circular
continuum Q1 reference, at R=1.02 m and Rdot=0.1 m/s, use its acceleration equation
to obtain Rddot=0.308980074751185 m/s². Include K_contents=M Rdot²/4,
K_exterior=pi rho (R Rdot)² ln(4/R), membrane energy pi S(R-1)² and compression
energy. Their total derivative plus outer kinetic-energy flux
`pi rho (R Rdot)³/4²` is zero. This separately checks the inertial and exterior
work terms required by the inputs. Polygon-vs-circle error must converge with N;
it must not be hidden by replacing the actual chamber area.

## 7. Qualification and complete-work boundaries

This document's executed checks are specification/arithmetic checks only. Future
qualification uses the contract's 2 s Q0–Q5 rejection screen plus Q6 failures,
then 20/40 s and, if required, 80 s behavioral windows and at least 20 measured
Q1 periods. Include grid phases, rotations, small-fraction events and every B1–B4
primitive above. Q4/reduced-interior and the base no-slip passage remain pending
review of their known incompatible limits; a correct negative result is not adoption.

Run temporal dt/2 and dt/4 comparisons and spatial (h/2,2N,dt/2),
(h/4,4N,dt/4), preserving all physical gaps and coefficients. Inherit the 0.7
successive-difference criterion above the contract's 0.01-budget refinement floor.
Inspect local fields and grouping-transition peaks as well as global sums. The
small-cell strategy has not earned acceptance until those continuity/refinement
and full coupled work budgets pass; arithmetic conservation is necessary only.

Complete calculated-interval cost includes collision/swept-event detection,
clipping and independent geometry checks, primal/dual agglomeration, overlap
remaps, reconstruction and flux lifting, both pressure projections and IC rebuilds,
viscosity, mechanics and content inertia, outer passes, safety scans, failed
attempts and commit. Report each count and sum, maximum group diameter/size,
minimum raw cut fraction and physical gap, component/gauge counts, true local
residual maxima, and accepted/requested time. Memory includes committed and staged
owner state, event histories, maps, factors, overlap tables and peak scratch.
No scratch or rejected work is excluded. Rendering/recording/checkpoint costs
remain separately reported. Inherit the proposed single-chamber mean 20 ms/H,
p95 40 ms, max 100 ms and 256 MiB screen; do not extrapolate laboratory throughput.

Raw implemented diagnostic runs will use the next project `.codex/runs/runNNNN_...`
folder. This task executes no simulation, so its durable evidence is the focused
checker and the compact observations below, not a fabricated run directory.

## 8. Sources and interpretation

The candidate and its equations above are project design choices. Literature
supports the need to check geometric conservation and pressure transients, not
the claim that this particular coupling works: [Seo and Mittal, 2011](https://pmc.ncbi.nlm.nih.gov/articles/PMC3156558/)
analyse moving-boundary geometric conservation and virtual merging; their method
does not establish this design's momentum/work closure. [An accurate moving boundary formulation in cut-cell methods](https://www.sciencedirect.com/science/article/abs/pii/S0021999112005839)
report that conservative cell merging alone need not eliminate pressure
oscillations. Thus continuity and local work tests remain explicit adoption gates.

## 9. Executed specification checks and reproducibility

Used capability guidance: **bitloop**, **simulation-health**; read the local
bitloop-development entry and simulation-health reference. No Bitloop API changes,
package installation, physical runtime, visual claim or checkpoint claim is made.

Run from the Substrate root:

```powershell
./tooling/check_boundary_law.ps1 -Document
git diff --check
```

The checker validates B1 corner flux/mass/momentum/pressure work, B2 sided
birth/death and membrane work, positive same-side remap conservation and kinetic
loss, the pressure projection work identity, B3 channel arithmetic, B4 polygon
sweeps/area-gradient work and the continuous radial energy identity. It includes
negative controls for frozen corner sweeps, opposite-side pooling, an isolated
small region and incompatible closed-volume change. Its tolerances check algebra
in binary64, not the unapproved physical qualification budgets.

Input SHA-256 identities (also checked by `-Document`):

| Input | SHA-256 |
| --- | --- |
| PHYSICAL_CONTRACT.md | 48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07 |
| MECHANICS_LAW.md | EE2C5000A81D357CDE5F706D98F43A45C52429E543EE80333DF7964A6DF8145A |
| COMPARTMENT_LAW.md | C05278878AE4A3DA7FFB1035662F2A4002BF0C8D098BC19CF80E41014AAF96B3 |
| STATIONARY_FLOW_LAW.md | BC2BE2E0568DFAECBE167FD5AF4C79E57A3B3957E07E65DA1BD55CB56F5DE53A |

The current pilot source hashes remain FC24DB1F60D89A1955C5DFC24EB95A15DBA86A736C03134A17B43FEA34E4F6E5
(header) and F6CF93EB3AD740399016BD2AA4B4C0FB84E9C576F38338308CF69C6AA87A7FB6
(source). Existing user changes and all four input specifications are preserved.
Executed `./tooling/check_boundary_law.ps1 -Document` in PowerShell on 2026-10-10:
**43 algebra checks and five negative-control groups passed**, as did document
coverage, local links, whitespace and the six input/source hash comparisons.
All algebra checks used absolute tolerance 1e-12 in the stated output units;
negative controls compare with their named topology or geometric conditions.

| Decisive observation | Actual result |
| --- | --- |
| B1 independent swept area versus endpoint difference | error 2.03e-20 m² |
| Wrong old-facet corner sweep | error 1.953125e-7 m²; rejected against 3.90625e-10 m² local budget |
| B2 membrane work from both-sided tractions | 5.859375e-5 J; sided rows close individually |
| Deliberately pooling opposite-side tracer | 1.943359375e-5 kg forbidden contamination despite global mass closure |
| Positive overlap remap | mass 4 kg and momentum 0 conserved; 1.33333333333333 J numerical kinetic loss explicitly identified |
| One-cell moving-wall pressure projection | velocity 0.4 m/s; work/energy identity residual 0 J, numerical loss 0.02 J |
| B3 base passage | relative flow error 0.125; negative quality prediction preserved |
| B4 actual polygon expansion | Delta A=0.000785131856905874 m², secant pressure 0.998625143212258 N/m |
| Polygon area-gradient work check | area error 6.76e-15 m²; compression-work residual 6.75e-15 J |
| Independent radial energy identity | residual -9.44e-17 W; acceleration 0.308980074751185 m/s² |

These results verify the specification's arithmetic and expose intended bad
constructions. They do not verify an implemented clipping kernel, agglomeration
solver, coupled trajectory, continuity under repeated support events or performance.
All such behavioral claims require the implementation and horizons in section 7.
