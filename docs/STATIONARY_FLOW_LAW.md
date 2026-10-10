# F-flow-law — Stationary flow algorithm and reference cases

Draft 1. Task `T-design-flow`. Input: [F-contract draft 1.1](PHYSICAL_CONTRACT.md),
SHA-256 `48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07`.

## 1. Decision and scope

Specify one candidate: a uniform Cartesian staggered (MAC) finite-volume layout,
paired donor-cell momentum/mass transport, implicit backward-Euler Newtonian
viscous stress, and a nonincremental pressure projection solved by PCG with
unmodified level-zero incomplete Cholesky, IC(0). No alternative solver menu or
third-party dependency is introduced. This is a design specification, not code
or an adopted physical foundation. **All numerical values and acceptance limits
remain PROPOSED / UNAPPROVED**, including inherited F-contract values.

The stationary geometry here consists of full Cartesian cells, face-aligned
walls/impermeable membranes and rectangular periodic or open boundaries.
Environmental and explicitly resolved internal liquid use the same algorithm,
with separate physical ownership and boundary labels. Constant reference areal
density rho=1 kg/m² is used throughout the reference cases. Variable-density
multiphase flow, moving cuts, curved-wall approximations, swept volumes and their
coupling laws are outside this task. In particular, stair-stepping the circular
chamber in F-contract is not an authorized substitute for its geometry.

F-contract exists; current [Substrate source](../Substrate/Substrate.cpp) still
contains pilot telemetry and false-returning checkpoint hooks, not a fluid solver.
The handoff permits design without pretending the unapproved budgets are approved.
Local capability guidance used: `bitloop` for ownership, and `simulation-health`
for local checks, horizons and evidence. No new Bitloop execution is claimed.

The staggered pressure/projection and sparse incomplete-Cholesky background was
checked against [Bridson and Müller-Fischer's course notes, chapters 2 and 4](https://www.cs.ubc.ca/~rbridson/fluidsimulation/fluids_notes.pdf).
We choose IC(0), rather than their later modified variant, to specify one bounded
factorization without modification parameters. Projection-method background is
also in [Chorin's original paper](https://math.berkeley.edu/~chorin/chorin68.pdf).
Our units, conservation rules, thresholds, worked calculations and rejection
decision below are project proposals/derivations; those sources do not validate
this candidate or its performance.

**Decisive limitation:** section 7 derives a 12.5% flow/power error for the selected
no-slip stencil in a four-cell-wide channel. F-contract's 0.25 m minimum passage
is four cells wide at h=1/16 m. This exceeds the proposed 2% flow/work comparison
gate. The design is specified, but this combination cannot be adopted at that
resolution without an explicitly reviewed change. No baseline or budget is changed
by this document.

## 2. State, units and topology

All physical state is C-fluid-owned within C-world's committed revision. C-boundary
supplies fixed geometric/connectivity data and owns no inventory. Use F-contract's
area units: A in m², rho in kg/m², p in N/m, velocity in m/s, force in N, energy
in J. Kinematic viscosity nu has units m²/s; dynamic viscosity mu=rho nu has
units kg/s. Viscous traction is force per length, not three-dimensional pressure.

| Location | Stored or derived quantity |
| --- | --- |
| Cell centre c | Owned constituent amounts q[c,k] in kg. Total mass M[c]=sum_k q[c,k]. Pressure p[c] is the accepted constraint multiplier/warm-start, not a stored-energy reservoir |
| Vertical face (i+1/2,j) | One x-momentum degree of freedom P_x and its normal velocity u=P_x/m_x |
| Horizontal face (i,j+1/2) | One y-momentum degree of freedom P_y and velocity v=P_y/m_y |
| Momentum dual volume | Derived inertial mass m_f: half the mass from each adjacent cell; at an outer boundary, the one available half-cell. It is not an additional material inventory |
| Fixed geometry | Cell area h², face length h, half/full dual volumes, wall/port tags and explicit allowed adjacencies. Blocked faces have zero transport and distinct physical sides |
| Derived caches | Component labels, dense pressure/momentum rows, sparse operators, IC factors and flux scratch, all tagged by geometry/coefficient revision |

Each component's dual volumes partition its domain for that momentum component;
summing x-dual and y-dual masses together would double-count material and is
forbidden. Velocities represent a piecewise-constant dual-volume field using
face-centre quadrature. Its energy is `K_h=0.5 sum_f P_f²/m_f`, summing x and y
contributions. Its integrated momentum is `(sum P_x, sum P_y)`. Reference field
samples and continuum integrals are reported separately; quadrature error cannot
be hidden by comparing only discrete totals.

Constant-density incompressibility means target M[c]=rho h². Do not reset an
advected inventory to that target. Reconstruct dual inertia from the actual
owned masses; reject if `abs(M[c]/(rho h²)-1)>1e-8`, or if F-contract's tighter
mass/volume budgets fail. The permitted discrepancy is a monitored numerical
residual, not a compressible phase model. All reference initializations set
M[c]=rho h² exactly; species merely partition that mass. Binary64 arithmetic
and fixed row/reduction order define the reference execution configuration.

Domain/port/material IDs are stable references. Cell indices and solver rows
are dense implementation indices tied to a grid revision. A membrane disconnects
both primal transport and the momentum/viscosity stencils; no interpolation,
preconditioner edge or ghost value may bridge its two sides. Corner contact
alone does not connect pressure regions. Flood-fill only permitted open faces.

An explicitly resolved internal domain has its own grid inventories and momentum;
the associated chamber must not also own well-mixed contents for the same material.
Automatic conversion between those representations is excluded. A future physical
opening creates an explicit allowed adjacency/transfer; mere spatial proximity
does not merge internal and environmental fields.

## 3. Conservative transport and one staged substep

Use interval-start divergence-free velocity u^n for all explicit transport over
Delta t. First-order time integration is intentional and must be measured under
refinement. Final projected u^(n+1) drives the next interval, not a retroactive
second inventory update in this one. The trace must distinguish transport fluxes
actually used from endpoint velocities.

For oriented primal face a→b, `Q_f=ell_f u_f^n` in m²/s. Upwind density and
composition come from the donor cell (a for Q≥0, b otherwise):
`Phi_f=Q_f M_d/A_d`, `Phi_f,k=Phi_f q_d,k/M_d`, in kg/s. The same signed
`Delta t Phi_f,k` is subtracted from a and added to b, once. Reservoirs carry
explicit external postings. No limiting by independent recipient clamping and
no negative-amount clipping; an invalid proposal rejects.

Construct momentum-dual mass fluxes by the arithmetic half-sums of adjoining
primal mass fluxes. For an x-face dual volume, its left/right fluxes are half
the two bracketing x-face mass fluxes; top/bottom fluxes are half the y-fluxes of
the two adjoining half-cells. Interchange x/y for y momentum. At a physical
boundary use only its actual half-cell, with prescribed boundary flux; never
average across a blocked face. Opposite postings use one stored dual flux.
This construction makes dual mass change exactly the corresponding half-sum
of primal mass changes, up to measured rounding error.

Advect the represented component momentum using that dual mass flux times the
donor dual velocity component. Reconstruct `m_f^(a)` from updated cell inventories
and set `u_f^(a)=P_f^(a)/m_f^(a)`. Thus mass and momentum use the same transported
material; no separate interpolation of velocity bypasses conservation. This
donor-cell transport has numerical diffusion. Its kinetic-energy residual is
measured separately from viscosity and is never available fuel/heat. Constituent
diffusion and reactions are zero here; detailed species laws remain downstream.

Substep order, entirely in candidate buffers:

1. Validate geometry, connected components, density/inventories and interval-start
   velocity divergence. Select Delta t under section 6 and freeze all boundary data.
2. Form primal/dual fluxes and stage inventories and momenta conservatively.
3. Add prescribed body-force impulses `Delta P=m_f^(a) g Delta t`. Meter force
   work with the corresponding average of pre/post-force velocities.
4. Apply the coupled implicit viscous solve from section 4, obtaining u*.
5. Apply section 5's pressure projection, obtaining endpoint velocity and pressure.
6. Recompute true residuals, all local/global accounts and validity checks. Commit
   together, or discard the entire attempted substep and use C-world's bounded
   retry/prefix semantics. Every stage's allocation/solve/rejected work counts.

Prescribed velocity faces are constraints, not unconstrained momenta silently
overwritten after the solve. Account their removed momentum equation as support/
inlet reaction and work, including viscous and pressure contributions. Static
solid walls do zero work but can exchange impulse and angular impulse.

## 4. Viscous stress and work

Use a single coupled backward-Euler solve for Newtonian symmetric stress
`tau=mu(grad u + grad u^T)`, with constant nonnegative mu. On the MAC grid take
normal derivatives at cell centres and shear `d_y u + d_x v` at corners, using
centred differences and the actual half-distance to a face-aligned wall.
The discrete dissipation quadratic form is the area-weighted sum
`2 mu[(d_x u)²+(d_y v)²] + mu(d_y u+d_x v)²`.
Assemble its symmetric nonnegative stiffness K_v by the transpose of the same
strain operator used to compute stresses. This includes cross-component terms;
do not substitute unrelated scalar filters when constructing wall reactions.

For free momentum DOFs, with M_d=diag(m_f^(a)), solve
`(M_d + Delta t K_v) u* = M_d u^(b) + Delta t f_wall`.
Here u^(b) follows the body-force step and f_wall comes from eliminated prescribed
boundary values. Use PCG/IC(0) as for pressure, with a 200-iteration cap and true
relative L2 residual ≤1e-8 or nondimensional absolute L2 residual ≤1e-10.
K_v has rigid modes, but M_d makes the viscous system SPD; no pressure-style
gauge pin is applied to it. Nonpositive mass, invalid pivots or nonconvergence
reject the attempt. For mu=0 this stage is exactly the identity.

For homogeneous stationary walls/periodicity and an exact solve,
`Delta K_visc = -Delta t (u*)^T K_v u* - 0.5 ||u*-u^(b)||²_Md`.
The first term is physical discrete viscous dissipation; the second is
backward-Euler numerical damping. With nonzero wall data, add actual wall work
and evaluate strain using those data. Record the residual of this identity from
the true algebraic solve. Keep the energy loss from transport, viscous time
integration, pressure projection and physical stress in separate columns.

For the channel below, tangential u is at y_j=(j+1/2)h. A stationary no-slip wall
uses zero wall velocity at distance h/2: ghost u_-1=-u_0. Consequently the first
row of the scalar shear reduction is `(u_1-3u_0)/h²`; interior rows are
`(u_(j+1)-2u_j+u_(j-1))/h²`. This is the chosen stencil, including its quantified
coarse-passage error. Do not silently replace it with a different wall formula.

## 5. Pressure, boundaries and disconnected components

### 5.1 Compatible pressure operator

Let B be integrated divergence on free normal-velocity faces: for a face oriented
from cell a to b its column is +ell in a and -ell in b. Pressure-open exterior
faces have the one signed entry for their incident cell. Known velocity boundary
fluxes form q_N, positive outwards. Therefore continuity is `B u + q_N=0`.
This integrated operator must be the transpose partner of the pressure force;
do not independently code incompatible divergence and gradient stencils.

Let b_p have signed `ell p_boundary` on pressure-open faces, and zero internally.
For the full physical pressure, not a pressure increment, solve

`A_p p = b,    A_p = B M_d^-1 B^T`

`b = -(B u* + q_N)/Delta t + B M_d^-1 b_p`

`u^(n+1) = u* + Delta t M_d^-1 (B^T p - b_p)`.

B u has units m²/s; A_p p and b have units m²/s². On a full constant-density
interior square face, the matrix edge weight is `ell²/m_f=1/rho`; dividing a
row by cell area recovers the usual 1/(rho h²) coefficient. A pressure boundary
has half a momentum dual volume, giving weight 2/rho (distance h/2), not an
arbitrary small-cell regularizer.

For homogeneous closed/periodic boundaries with an exact solve, pressure changes
kinetic energy by `-0.5 ||u^(n+1)-u*||²_Md`. This is numerical projection loss,
not viscosity. With open/known-flux boundaries, use endpoint pressure work
`W_p=-Delta t[b_p^T u^(n+1)+p^T q_N]`. Then
`Delta K_projection-W_p = -0.5 ||Delta u||²_Md + Delta t p^T(B u^(n+1)+q_N)`.
The final term exposes incomplete convergence locally and globally. Stationary
walls have q_N=0. Include advected energy separately using the actual transport
fluxes; pressure work alone is not an open-boundary energy balance.

### 5.2 Boundary rules

| Boundary | Transport / velocity | Pressure / viscosity |
| --- | --- | --- |
| Impermeable no-slip stationary wall | Normal velocity and all species flux exactly zero; tangential wall velocity zero | Normal pressure correction from prescribed normal velocity, not arbitrary p=0; symmetric stress supplies wall traction |
| Impermeable free-slip stationary wall | Zero normal velocity and inventory flux | Zero tangential viscous traction; wall pressure reaction retained |
| Periodic pair | One shared flux and momentum edge, posted once on each side; wrap within the same domain | Pressure periodic unless a separately metered mean force represents a pressure drop; periodicity does not supply a pressure reference |
| Velocity inlet | Prescribed normal velocity, tangential data and nonnegative constituent fractions summing to one | Pressure uses the induced Neumann correction; inlet impulse/work and advected energy explicit |
| Pressure reservoir | Prescribed p_boundary, free normal velocity; incoming composition/density/tangential state defined when backflow occurs | Natural zero viscous traction on the open face during the viscous stage, then prescribed pressure in projection; include splitting error under refinement |

Do not prescribe both normal flow and pressure on the same boundary. Outgoing
transport uses the interior donor; incoming transport uses the declared reservoir
state. Undefined backflow data cause failure, not extrapolated negative amounts.
For a pressure reservoir, the pressure datum is physical relative to the common
environmental reference; prescribed open-boundary work uses that same reference.
Open viscous boundary splitting is not qualified by the periodic channel alone.

### 5.3 Nullspaces, compatibility and solver

Build separate systems for every face-connected component. Any component touching
a pressure-Dirichlet face is anchored physically and has no constant nullspace.
Closed, periodic or all-velocity components each have one constant pressure mode;
check their net prescribed flux before removing that mode. A disconnected one-cell
closed component has no free pressure DOF: it still gets the compatibility check.

For an all-Neumann component, require `abs(sum b)<=1e-12 max(1,sum abs(b))` after
nondimensionalization. A larger imbalance is an incompatible boundary/flux failure,
not a reason to subtract a mean or invent a sink. For accepted roundoff-sized
imbalance only, remove the uniform RHS mean, record that correction, and retain
the original RHS for the final physical residual/volume checks. Pin the smallest
deterministic cell ID to p=0 by removing its row **and column**. Never hide the
pinned row's original residual. Disconnected regions must not share a pin.

This gauge is a numerical convention. In a sealed resolved internal domain it
does not determine absolute transmembrane pressure or a compressibility law.
The later geometry/mechanics design must supply that physical closure before
coupling deformable walls. An arbitrary gauge must never become a chamber force.
For fixed walls the pressure-gradient/flow solution is meaningful independently
of that missing absolute-pressure closure.

Use PCG with standard IC(0): deterministic row order; retain only the original
lower-triangle sparsity; compute `L_ii=sqrt(A_ii-sum_k L_ik²)` and retained
`L_ij=(A_ij-sum_k L_ik L_jk)/L_jj`. Apply forward/back substitution for LL^T.
No dropped-fill compensation, diagonal shift, solver fallback or tolerance
relaxation is implicit. Nonpositive/nonfinite pivots or PCG denominators reject
with component/row identity. Build factors for the actual constrained SPD matrix.
Retain pressure as a warm start only after successful commit; tag factors by exact
matrix/coefficient revision and rebuild when changed. All rebuild cost is counted.

Recompute unpreconditioned residual `r=b-A_p p` every 10 iterations and at exit.
Acceptance requires ALL of: relative L2 residual ≤1e-8 (or nondimensional absolute
L2 ≤1e-10), every-cell `Delta t abs(Bu+q_N)≤1e-8 A_c`, and
`abs(Bu+q_N)/A_c≤1e-6 s^-1`. Check original unpinned rows and RHS, as well as
every component separately; a large region cannot hide a small region's failure.
The pressure cap is 200 PCG iterations per solve, inherited as an unapproved
proposal from F-contract. A reported preconditioned norm or small iterate change
alone never establishes convergence.

## 6. Timestep, support and failure rules

Base Delta t=0.00125 s and output H=0.02 s follow F-contract. In addition require
outgoing primal mass fraction and outgoing dual mass fraction per substep ≤0.5,
using the actual available donor masses. This is the positivity/advective CFL
screen for the chosen unsplit donor update. Check the estimate before staging and
the actual candidate afterwards; negative inventories or inconsistent dual mass
reconstruction reject rather than clamp. Reject nonfinite data or nonpositive
mass before division.

Backward Euler removes an explicit diffusion stability limit, but not an accuracy
limit: propose `nu Delta t/h²≤0.25` and use dt refinement to measure its extra
damping. For a sudden body force also require `|g| Delta t²/h≤0.25`; this is a
screen, not a substitute for endpoint CFL and pressure checks. No acoustic CFL
is claimed for this incompressible model.

Follow F-contract's four halvings, at most 512 substep attempts per output,
and prefix-commit failure semantics. A stationary split has one pressure solve
per attempt, not four automatic coupling passes. IC breakdown, nonconvergence,
unbalanced components, stale topology, density drift or exceeded residual/energy
budgets all fail explicitly. Repeated solves cannot consume unlimited work.
Previous accepted state/time, inventories, pressure warm start and physical
accounts survive rejection. Diagnostic attempt counters may advance separately.

Face-aligned passages preserve every open face; never close a narrow channel to
improve conditioning. Geometry below F-contract's fixed g_min=0.25 m is unsupported.
Meeting g_min is necessary but does not establish accuracy: the selected viscous
wall stencil needs more than four cells for the proposed channel gate (section 7).
Do not merge regions or discard cells based on a condition-number estimate.
Fractional cut faces/tiny cut cells are not supported by this full-cell law;
their inertia, flux, stress and pressure operators require the separate boundary
design, retaining these transpose and ownership identities.

## 7. Worked references and local/work oracles

These values are calculations, not observed simulation results. All run gates
below are proposals requiring approval. Use inherited mass, impulse, leakage,
pressure and energy accounts without weakening them. Additional viscous cases
have declared physical dissipation and are distinct from F-contract's nu=0 cases.

### R0 — Uniform pressure/rest and uniform momentum

Use a 1×1 m box, h=1/16 m, rho=1, M_total=1 kg, zero velocity. For the open
rest case set all reservoir pressures to p0=3 N/m and compatible zero-flow
incoming state. Every cell has M=1/256 kg, every gradient and Q is zero, and the
matrix equation is satisfied by p=p0 because B^T p=b_p. Pressure work, viscous
dissipation and energy change are all zero. Require the F-contract Q0 local
speed/pressure/energy limits; verify pressure on every cell, not just mean flow.

Repeat with closed and periodic boundaries: p0 and p0+7 N/m must produce the
same flow; the solver's pinned pressure is zero, so compare gradients after
gauge alignment rather than failing because it did not retain an arbitrary p0.
Repeat as two disconnected boxes with separate pins and perturb only one RHS;
the other component's velocities/inventories must not change.

Uniform-momentum variant: 2×1 m periodic box, u=0.2 m/s, v=-0.1 m/s, rho=1,
any constant mu≥0. Every dual transport divergence and every strain is zero.
Expected P=(0.4,-0.2) kg m/s and K=0.05 J, unchanged. Require local velocity
error ≤1e-10 m/s, component momentum closure under F-contract and per-output
energy residual ≤1e-12 J. This exercises nonzero advection without confusing
numerical diffusion of gradients with conservation of uniform motion.

### R1 — No-slip channel and power

Domain length L=2 m, width Hc=1 m, periodic x and stationary no-slip y walls.
rho=1 kg/m², nu=0.1 m²/s, mu=0.1 kg/s, constant acceleration g_x=0.1 m/s².
G=rho g_x=0.1 N/m² represents a metered mean pressure gradient; do not also
apply a pressure drop on the periodic seam. Base h=1/16 m, Delta t=0.00125 s.

Continuum steady solution:
`u(y)=G y(Hc-y)/(2 mu)`, v=0,
`u_max=G Hc²/(8 mu)=0.125 m/s`,
`Q=G Hc³/(12 mu)=0.0833333333333 m²/s`,
`P_body=G L Q=0.0166666666667 W`.
The two wall reactions sum to `-G L Hc=-0.2 N`; each wall's shear magnitude is
G Hc/2=0.05 N/m. Wall work is zero. Physical dissipation
`mu L integral (du/dy)² dy` equals P_body, and
`K= rho L G² Hc^5/(240 mu²)=0.00833333333333 J`.

For the specified half-distance stencil, the exact discrete steady values are
`u_j=G[y_j(Hc-y_j)+h²/4]/(2 mu)`, y_j=(j+1/2)h.
The pointwise offset from the sampled continuum is `G h²/(8 mu)`;
relative to the exact dual-strip averaged velocity it is `G h²/(6 mu)`.
The measured discrete flux is
`Q_h=sum_j h u_j=Q+G Hc h²/(6 mu)`, so relative flux/power error is
`2(h/Hc)²`. This includes quadrature error; reporting only centre samples would
understate the integrated flow error. Discrete wall shear remains exactly G Hc/2.

| Ny | h (m) | Pointwise offset (m/s) | Q_h (m²/s) | Flow/power error | Discrete power (W) |
| --- | --- | --- | --- | --- | --- |
| 16 | 0.0625 | 0.00048828125 | 0.083984375 | 0.78125% | 0.016796875 |
| 32 | 0.03125 | 0.0001220703125 | 0.08349609375 | 0.1953125% | 0.01669921875 |
| 64 | 0.015625 | 0.000030517578125 | 0.0833740234375 | 0.048828125% | 0.0166748046875 |

A future implementation must match the discrete solution to ≤1e-8 m/s at every
sample and the continuum pointwise error to ≤0.5% u_max; require flux and work
error ≤2% and wall-force error ≤2%. Compare local face traction and the positive
viscous quadratic sum to the body-force power. Its steady dissipation should
equal **discrete** power; additionally report the difference from continuum
power as spatial discretization error, not a physical source.

For the force-then-viscosity split, metered force work over a step also includes
the average-velocity quadrature term `0.5 M_total g_x² Delta t²`. In exact steady
discrete flow this is cancelled by the viscous stage's BE numerical damping;
the physical power values above use the steady velocity. Retain both terms in
the stage audit rather than misclassifying the extra term as physical dissipation.

Initialize once with the exact discrete steady solution to isolate wiring, and
separately from rest to exercise viscosity. The slowest continuum startup decay
time is `Hc²/(pi² nu)=1.013211836 s`; use 10 s then 20 s, retaining startup cost
and errors. The continuum startup reference is
`u(y,t)=sum_(n odd) [4 g_x Hc²/(nu pi³ n³)] [1-exp(-nu(n pi/Hc)²t)] sin(n pi y/Hc)`.
Bound its series remainder below one tenth of the comparison tolerance. A
direct steady-only run does not establish startup behavior or solve convergence.

### R2 — Viscous decay with conserved mean momentum

Use the 2×1 m periodic box, rho=1, nu=0.1, v=0 and
`u(y,0)=U0+a0 sin(2 pi y/Hc)`, U0=0.2 m/s, a0=0.1 m/s, Hc=1 m.
Advection is identically zero for this shear field: no x dependence and v=0.
Continuum amplitude `a(t)=a0 exp(-nu k²t)`, k=2 pi/Hc, time constant
tau=0.2533029591 s. Mean momentum P_x=0.4 kg m/s is constant;
`K(t)=0.5 rho L Hc U0² + rho L Hc a(t)²/4`.
Initial K=0.045 J, mean-motion K=0.04 J. At t=1 s,
a=0.0019296302911 m/s and K=0.0400018617365 J.
Physical dissipation rate is `mu L Hc k² a(t)²/2`, and its time integral equals
lost fluctuation energy. It cannot consume the uniform mean motion.

Sample at the MAC face centres. The discrete eigenvalue is
`lambda_h=4 sin²(pi/Ny)/h²`, and backward Euler predicts
`a_h(n)=a0 [1+nu lambda_h Delta t]^(-n)`.
Check each face against that discrete field and compare amplitude, momentum and
continuum energy separately. The missing within-dual-cell variation is a spatial
quadrature approximation, not deleted inventory. If a reference initializes
exact dual averages instead of samples, multiply both initial reference and
discrete amplitudes by sinc(pi/Ny); never mix those initialization conventions.

| Ny | Delta t (s) | a_h at 1 s (m/s) | Error against continuum (m/s) |
| --- | --- | --- | --- |
| 16 | 0.00125 | 0.00204882191633 | 0.00011919162522 |
| 32 | 0.000625 | 0.00196369311403 | 0.00003406282293 |
| 64 | 0.0003125 | 0.00194046492771 | 0.00001083463661 |

For each viscous step, with amplitude changing a_old→a_new, discrete physical
dissipation is `Delta t nu lambda_h (rho L Hc/2) a_new²` and numerical damping
is `(rho L Hc/4)(a_new-a_old)²`. Their sum must equal the lost discrete kinetic
energy to the algebraic-solve tolerance. Do not label their sum physical viscosity.
Pressure should add no loss to this already divergence-free mode.

Propose local error against the discrete eigenmode ≤1e-8 m/s, absolute amplitude
error against continuum ≤0.5% a0, momentum error ≤1e-10 kg m/s, and physical
work/energy comparison error ≤2% of initial fluctuation energy 0.005 J.
Apply F-contract's separate cumulative numerical-residual budget with E*=0.005 J,
not the larger mean-motion energy. Inspect 0, 0.25, 0.5 and 1 s, then extend to
2 s (>7 tau) to expose residual mean damping; tiny late amplitudes use the fixed
initial-amplitude scale, never a vanishing denominator. Require dt-only and
h/dt refinement as well as the shown combined sequence.

### R3 — Narrow passages, isolation and rejection controls

Repeat R1 with physical Hc=0.25 m, L=2 m and the same G/mu. At base h=1/16 m,
Ny=4. Analytic Q=0.00130208333333 m²/s, whereas the selected discrete law gives
Q_h=0.00146484375 m²/s: **12.5% high**, and body power is 12.5% high as well.
At 8 and 16 cells across the same physical gap the errors are 3.125% and 0.78125%.
Pointwise error divided by the true peak velocity is 1/Ny²: 6.25%, 1.5625% and
0.390625%, respectively. The 2% flow/work gate needs at least 10 cells across;
the local 0.5%-of-peak-velocity gate needs at least 15. The power-of-two
refinement satisfying both uses h=1/64 m, 16 cells. Geometry support alone
is therefore insufficient at the proposed base grid. This is an analytic rejection
of this stencil/resolution for that gate, not a measured runtime result and not
authorization to refine the whole coupled experiment or weaken the budget.

Also define two 1×1 m chambers separated by a face-aligned sealed membrane, and
two 1×1 m chambers joined by a length-1 m, width-0.25 m straight corridor on the
same h grid. For the sealed case require two pressure components and zero
cross-wall scalar/momentum/viscous stencil entries. For the open corridor require
one component, finite conductance and paired through-flow; compare section/face
fluxes and entrance pressure fields against a separately refined run. Fully
developed Poiseuille values apply inside a straight periodic channel, not at a
chamber entrance. Do not mislabel entrance losses as a failed Poiseuille oracle.

Invalid controls: an all-velocity sealed component with net prescribed inflow,
opposite imposed flux imbalances in disconnected components that cancel globally,
nonpositive IC pivots, an artificially restricted iteration cap, and a corridor
below 0.25 m. Each must fail before commit with actual time/state preserved.
No islands may disappear because they are small; no single global gauge or global
RHS correction may conceal a component's incompatible flux.

## 8. Iteration, memory and full-cost instrumentation

Report per component and per solve: active cells/unknowns, boundary types, gauge
cell, compatibility correction, nonzeros, initial/final true residuals, maximum
cell divergence/volume defect and its identity, IC minimum pivot, PCG iterations,
matvecs, triangular solves, rebuilds, breakdown reason and accepted/rejected time.
Include prescribed-pressure work, support reactions, momentum/constituent closure,
transport dissipation, physical viscosity, BE damping and projection loss.
Aggregate both signed and absolute local errors; a zero total is insufficient.

Use compressed sparse rows with binary64 coefficients, checked 32-bit column IDs
and 64-bit row offsets; reject index overflow. For a 5-point full-cell pressure
matrix, a planning estimate is 5N entries for A, 3N for lower IC and eight N-long
binary64 working arrays: about `60N+36N+16N+64N=176N` bytes, or 2.75 MiB for
N=16384, plus row-end constants. This is **not** total simulation memory or a
measured allocation. Add geometry/labels/indices, inventories, momentum arrays,
both candidate and committed state, face masses/fluxes, viscosity matrix/factors,
boundary data, journal/retry storage, thread scratch and allocator capacity.
Count shared buffers once but concurrent peaks honestly. Record actual allocated
bytes, high-water marks and process working-set/private-byte peaks separately.

Time the complete requested H including transport, viscosity/pressure assembly,
factor construction, both solves, safety checks, work accounting, restoration and
all retries. Separate startup, steady and narrow-passage windows; never amortize
a failed solve out of the sample. Report mean/p95/p99/max and actual simulated
seconds divided by wall seconds, with actual CPU/compiler/precision/worker state.
Keep F-contract's proposed complete-work limits as future gates; no performance
claim follows from sparsity or an estimated iteration count. IC triangular solves
and long thin components may limit parallel throughput; measure rather than
assume that 16 workers accelerate them.

## 9. Qualification and downstream handoff

Before running acceptance, approve fixture coefficients, thresholds and hardware;
implement independently checked operators/oracles; then use the existing Bitloop
trace workflow through C-app. Every trial/commit checks finite state, inventories,
connectivity, component compatibility, residuals and energy. Reference cases have
every-step local checks; retain compact extrema/first failure, selected field maps
and fixed-time summaries rather than dumping all fields every frame.

For refinement use F-contract's factor-0.7 improvement rule and its 0.01-times-
acceptance-limit floor, with frozen physical geometry. Preserve the 0.25 m gap
as h changes. R0 assesses exact discrete invariants; R1 and R2 distinguish the
implemented discrete law from continuum error; R3 exposes narrow-boundary risk.
None implements F-contract Q1–Q6 moving geometry or content/mechanics coupling.
Later boundary design must provide sided cuts and conservative operators compatible
with this layout, and physical pressure references for sealed deformable interiors.
That compatibility must be demonstrated rather than inferred from the matrix form.

Restart will require owned inventories/momenta, actual time/revision, domain/port
identities, material/boundary configuration and any pressure warm-start or cache
state that changes continuation. Rebuildable stencils/factors can be omitted only
with a declared deterministic reconstruction. No checkpoint implementation is
added here; F-contract remains authoritative on rollback and continuation tests.

## 10. Task verification record

The task inspects the actual F-contract, project instructions, current source and
selected-task metadata. No required input is inferred solely from an artifact ID.
The specification maps acceptance as follows: sections 2–6 define storage, flux,
boundaries/nullspaces and advancement; section 7 supplies worked references/local
and work oracles; sections 5, 6 and 8 cover disconnected/narrow regions and
pressure-iteration/memory instrumentation.

Numerical tables are direct binary64 PowerShell evaluations of the printed
formulas, not a solver execution. Further algebra checks verify the channel
stencil at every row, its wall-force/work balance, the shear-mode BE energy split,
and a two-cell pressure projection's sign, divergence and energy loss.

PowerShell binary64 audit, executed during T-design-flow:

| Calculation checked | Actual observation | Arithmetic audit threshold |
| --- | --- | --- |
| R1, Ny=16, every discrete steady row: `mu L_h u+G` | Maximum residual 7.08e-16 N/m² | ≤1e-12 N/m² |
| R1 stress quadratic versus driving power | Both 0.016796875 W; difference 0 W | ≤1e-12 W |
| R2 first BE step, a_old=0.1 m/s, Ny=16, Delta t=0.00125 s | Physical loss 4.82458743374e-5 J; numerical loss 1.17519952287e-7 J; identity error 1.17e-18 J | ≤1e-14 J |
| Two unit-area cells, one unit-length free face, m_f=1 kg, u*=1 m/s, Delta t=0.00125 s; pin p_a=0, p_b=800 N/m | Final u=0 and divergence=0; projection loss 0.5 J; energy identity residual 0 J | ≤1e-14 for velocity/energy checks in their respective units |
| R3 minimum-gap channel formula | Q=0.00130208333333 versus Q_h=0.00146484375 m²/s; 12.5% error | Exceeds proposed 2% flow/work gate; known candidate limitation |

The two-cell check is an operator sign/energy calculation with a deliberately
non-solenoidal predictor, not an admissible initialized flow run. These arithmetic
tolerances check the written formulas; they do not replace physical qualification
budgets or demonstrate convergence/iteration counts of an implemented solver.
Tables at Ny=16/32/64 were recalculated; local error and integrated flow/work
error were kept separate. The negative R3 result is retained for review rather
than hidden by the successful algebra checks.

Document checks inspect all three task acceptance groups, the fixed choice of
method, local and global oracles, proposed-value labels, existing local links,
and dimensional consistency. Production source and F-contract hashes are checked
against their retained/input identities. No build, solver run, memory measurement
or runtime performance result is claimed for this documentation-only task.
Production source, F-contract, build configuration, dependencies and framework
code are unchanged by this task.
