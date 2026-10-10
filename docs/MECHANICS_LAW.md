# F-mechanics-law: compliant mechanics and contact

Draft 1, 2026-10-10. MindGraph task **T-design-mechanics**.
This selects one candidate: a total-Lagrangian finite-element structure with
compressible tissue triangles and tensile line elements, projected implicit
midpoint advancement, and unilateral Coulomb contact with inelastic impacts.
These are constituent elements of one mechanical system, not alternative backends.
No production algorithm or dependency is added by this specification task.

**All additional coefficients, limits, solver caps and example parameters in this
document are PROPOSED / UNAPPROVED.** Inherited numerical values are unapproved too.
Ownership, paired exchange and honest failure are mandatory. Human approval of a
qualification configuration and measured qualification remain separate from design.

Required input inspected: [F-contract draft 1.1](PHYSICAL_CONTRACT.md), SHA-256
`48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07`.
The actual [scene source](../Substrate/Substrate.cpp) still implements only pilot
tick/time observations; it supplies no mechanics or physical checkpoint support.
`bitloop_new_project(Substrate ...)` remains the project entry in
[CMakeLists.txt](../CMakeLists.txt). No configure/build is needed for this design.

## 1. Ownership, geometry and mass

C-mechanics owns rest topology, structural material, positions q, velocities v or
canonical momenta p=M_s v, structural mass matrix M_s, and support constraints.
Vertex/element/material/support IDs are stable with generations; dense matrix
indices and collision candidates are derived. C-world owns advancement, accepted
time and revision. C-boundary derives physical sides and geometry from these same
structures. Scene, camera, rendering and telemetry do not enter these equations.

Tissue triangles occupy their actual area. A membrane or independent fiber has
line mass and zero geometric thickness. Boundary edges of a tissue mesh do not
automatically receive another membrane mass or spring. An embedded fiber can
reinforce the existing tissue inventory, or own explicitly additional material;
that choice is made at construction, with its mass counted exactly once. Exterior
fluid and chamber contents exclude the area already occupied by tissue. They
retain their own inertia; receiving their reaction loads never adds a second copy
of their mass to M_s.

Use m, kg, s. Reference areal density rho_s is kg/m²; line density lambda_e is
kg/m. Two-dimensional stresses and Lamé coefficients are N/m, line tension and
line extensional coefficient S are N. Energy is J. There is no hidden thickness,
three-dimensional plane-stress conversion or material mass created by stretching.

For a positively oriented reference triangle (X0,X1,X2), A_e>0, assign fixed mass
m_e=rho_s A_e and the consistent linear-triangle matrix

```text
M_e = (m_e/12) [[2,1,1],[1,2,1],[1,1,2]] tensor I_2.
```

It is positive definite and exactly integrates kinetic energy of any affine
velocity field on that triangle. Assemble shared-node contributions. Current
density is rho_s/J. For a line element of reference length l_r, follow F-contract:
mass lambda_e l_r, half at each endpoint. Thus M_s includes consistent tissue
blocks and diagonal line contributions. All free degrees of freedom must have
positive mass; an unowned massless free node is invalid. Prescribed supports are
eliminated degrees of freedom with measured reactions, not extremely large masses.

The line mass convention has a known inertia error. About any origin, endpoint
lumping exceeds the uniform straight-line polar inertia by
`lambda_e l_r |x1-x0|²/6`. Report that error and its refinement, rather than calling
the lumped line an exact continuum inertia. No consistent-line replacement of the
contract's specified mass assignment is made here.

## 2. Constitutive laws and force assembly

### 2.1 Area-bearing tissue

Let `Dm=[X1-X0, X2-X0]`, `Ds=[x1-x0, x2-x0]`, `F=Ds inverse(Dm)`, `J=det(F)>0`.
Choose the following genuinely two-dimensional compressible neo-Hookean energy:

```text
W(F) = mu/2 [trace(F^T F)-2-2 ln(J)] + lambda_T/2 [ln(J)]²
U_e = A_e W
P = mu (F-F^-T) + lambda_T ln(J) F^-T
sigma = P F^T / J
f_i = -A_e P grad_X(N_i), i=0,1,2.
```

P is first Piola stress; sigma is current-area stress, both N/m. Gradients of the
linear shape functions are constant in the reference triangle. Obtain the tangent
by differentiating this force, not by replacing it with edge springs. Constant F
makes one exact element evaluation sufficient for this homogeneous material.
This law is objective under rigid rotation and gives zero stress at F=R. There
are no extra diagonal/shear springs, volume constraints or artificial shape goals.

For the tissue reference coupons use mu=2 N/m, lambda_T=4 N/m, rho_s=1 kg/m².
This is moderately compressible tissue, not an incompressible solid. Small-strain
area bulk modulus is lambda_T+mu=6 N/m; lambda_T is not the chamber bulk parameter.
Near-incompressibility is outside this displacement-only triangle design because
locking can corrupt deformation and cost. Do not increase lambda_T without a new
qualified configuration; no mixed-element alternative is introduced here.

### 2.2 Membranes and passive fibers

For `d=x_j-x_i`, `l=|d|`, `t=d/l`, choose the contract's tensile law:

```text
strain e = (l-l_r)/l_r       T_passive = S e
U_e = S (l-l_r)²/(2 l_r)     f_i = +T_passive t, f_j = -T_passive t.
```

Use S=1 N and lambda_e=0.1 kg/m for the contract membrane. No bending stiffness,
compressive buckling, fracture or remeshing is supplied. Committed tensile elements
require e>=0; a negative-tension state is unsupported, not replaced by a zero-force
slack branch. Floating-point uncertainty at exactly zero strain must be bounded
and reported; it is not permission to clamp a finite compression. Q2's driven
compression explicitly replaces the compliant wall response as F-contract states.

An embedded fiber uses the same line energy and material endpoints expressed in
fixed host-element barycentric coordinates. Scatter its equal/opposite forces
through those coordinates; that preserves virtual work, resultant and torque.
Do not append arbitrary nodal forces at unrelated application points. Embedded
constitutive fibers share host mass unless separate reinforcement mass is declared.

### 2.3 External loads and stiff supports

Boundary pressure/contact tractions map through the same structural shape
functions and physical application points. C-contents and C-fluid supply paired
impulse/work proposals; C-mechanics cannot recompute their inertia as a wall mass.
Coupling must settle these loads on one candidate trajectory before commit.

Supported stiff boundaries are externally prescribed rigid planes and capsules,
including F-contract's radius-0.125 m translating capsules. Their actual analytic
geometry, time-dependent pose and velocity are shared with C-boundary. Record
their total force/torque and work in the external ledger. A stationary support
has zero work even with nonzero impulse. A moving support supplies or absorbs
reaction work. Use exact kinematic constraints, not huge spring coefficients.
Arbitrarily stiff free bodies and deforming hard contact coatings are not claimed
by these support fixtures; no parallel rigid-body engine is introduced.

## 3. Integration and bounded solve

### 3.1 Smooth mechanical interval

For a staged interval delta, set `q_m=(q0+q1)/2`, `v_m=(v0+v_star)/2`. Solve

```text
q1-q0 = delta v_m
M_s (v_star-v0) = delta[-grad U(q_m) + f_active,m]
                 + J_external + J_contents + J_fluid
                 + G_n(q_m)^T j_n + G_t(q_m)^T j_t.
```

Here the J terms are integrated loads over this same interval. In an isolated
smooth case j_n=j_t=0 and v1=v_star: this is implicit midpoint. Prescribed-node
positions and velocities use the specified differentiable motion; apply the first
equation only to free coordinates. Eliminated momentum equations return support
impulses. Integrate their work along the prescribed motion; any difference between
its exact displacement and midpoint-velocity displacement belongs in the constraint
integration residual, not unreported work. Unspecified pose/velocity jumps reject.
Treat a time-varying support's actual swept trajectory explicitly,
not as a stationary plane at its final position. The computed finite wall motion
is also the motion supplied for swept fluid geometry and pressure work.

Midpoint preserves a linear mode's quadratic energy when solved exactly; it does
not exactly conserve nonlinear U. For an isolated structure its constitutive
energy residual is `Delta U-grad U(q_m) dot Delta q`. Objective internal forces
and the symmetric mass matrix also give paired linear/angular momentum. Record
residuals at each element and exchange as well as globally. No velocity rescaling,
energy correction or unexplained damping is permitted to make a step pass.

Use a damped semismooth Newton solve for the force/contact system. Assemble the
actual tangent, including current geometric contact terms and fixed active-law
branches. Solve its linearization with restarted GMRES (restart 40), using scaled
mass blocks and contact Schur diagonals as a preconditioner. Do not use a positive
definite solver on a potentially indefinite geometric/KKT tangent. Temporary
regularization of a search direction is allowed only with the **original**
equations' residual rechecked; it cannot become hidden stiffness or alter the
accepted force law. Singular/redundant contact rows are reported and resolved by
one deterministic independent-row selection retaining all inequality checks.

Each attempt has at most 24 Newton iterations, 200 GMRES iterations per Newton
iteration and 20 line-search reductions. Use merit decrease on scaled true
equation/complementarity residuals, with an admissible-geometry line search.
No decrease or exhausted cap rejects. Proposed infinity-norm tolerances are
1e-10 for position residual/L*, momentum residual/(M* U*) and normalized contact
complementarity. Verify work, geometry, leakage and all F-contract budgets too;
a small nonlinear residual alone is insufficient.

### 3.2 Persistent contact and endpoint compatibility

For a contact pair, g>=0 is the signed nonpenetrating gap, n points toward the
permitted side, and G_n maps generalized velocities to relative normal velocity.
G_t similarly maps relative tangential velocity at the **same physical contact
point**. Include support velocity with the opposite sign. Gap derivatives and
barycentric application weights are updated with the candidate geometry.

For contacts present at the start of a smooth interval, solve jointly:

```text
g(q1,t1) >= 0, j_n >= 0, j_n g(q1,t1) = 0
|j_t| <= mu_c j_n
slip: j_t = -mu_c j_n sign(u_t,m)
stick: u_t,m=0 with j_t inside the same interval.
```

Release a contact that would require adhesive normal impulse. Tangential slip
uses the midpoint relative motion; split a predicted stick/slip reversal rather
than applying a friction impulse through a resolved velocity reversal. Static
and kinetic coefficients are both mu_c in this candidate, and there is no contact
spring or stored friction history. mu_c=0 in the inviscid contract fixtures;
additional dry friction coupons specify mu_c explicitly.

On curved or changing contact geometry the midpoint position equation need not
give a tangent final velocity. Complete this **projected implicit midpoint**
method with an endpoint normal-velocity projection at q1:

```text
v1 = v_star + inverse(M_s) G_n(q1)^T eta
0 <= eta perpendicular to [G_n(q1) v1 + prescribed normal-rate term] >= 0
```

Apply this only to touching constraints with an inward endpoint velocity; an
outward velocity releases. The projection uses no friction impulse and does not
count eta toward physical friction capacity. It is a numerical constraint repair,
not an additional physical collision. Record its kinetic change minus any support
work as numerical residual. Positions are not teleported. Recheck sustained-contact
velocity and friction residuals; projection that spoils them requires a smaller
attempt, not a second unmetered projection loop. Flat sustained-contact reference
cases have eta=0. No exact energy or second-order claim is made for arbitrary
curved contact or contact transitions without convergence evidence.

Every internal reaction is applied to both owners at the same point, using
consistent endpoint weights, and supplies its opposite angular impulse. Equal
linear impulses at different locations are not a complete contact pair. If a
support is prescribed, its force/torque goes to the external ledger instead.

### 3.3 New impacts and continuous collision checks

Use swept AABB broad phase over structural boundary segments and rigid supports,
followed by continuous vertex/segment and segment/segment checks, including
capsule ends. Retain side orientation; an unsigned closest distance must not let
a vertex emerge on the opposite side of a zero-thickness wall. Adjacent shared
topological features are not colliding bodies, but local foldover/self-intersection
still requires detection. Vertex/corner ties supply all incident normal constraints;
do not choose a random normal at zero separation.

An impact is an earliest touching time with inward relative velocity. Bracket it
using certified swept bounds for the actual proposed path and the prescribed
support trajectory; use at most 64 refinements per candidate pair and an event
fraction tolerance of 1e-10. Ambiguous ordering/geometry beyond that tolerance
rejects. Re-solve the smooth motion to that event, since a shortened implicit step
is not generally the same path as the original predictor. Repeat the event bracket
and shortened solve, at most 8 corrections, until motion and event agree.

At the common touching configuration, solve simultaneous impulses using the
Delassus matrix `G inverse(M_s) G^T`. The selected impact law is zero restitution:

```text
v_plus = v_minus + inverse(M_s)(G_n^T j_n + G_t^T j_t)
0 <= j_n perpendicular to u_n,plus >= 0
|j_t| <= mu_c j_n;
sliding j_t=-mu_c j_n sign(u_t,plus), or sticking u_t,plus=0.
```

Use projected contact-block Gauss-Seidel in stable ID/feature order, at most 200
sweeps, checking the simultaneous true residual after each sweep. Finite-element
M_s is not replaced by its diagonal when computing effective masses. Normal and
tangential blocks must be solved together where they couple. Failure, an ambiguous
nonunique branch affecting the declared tolerances, or an energy-increasing
stationary-support impact rejects. This does not promise that arbitrary frictional
contact networks have a unique solution.

The physical impact loss is the negative contact work evaluated with the average
pre/post relative velocity, `D_impact=-sum j dot (u_minus+u_plus)/2 >=0`.
It is the chosen inelastic impact/friction model, not a fit to an unrelated solver
error. Keep its normal and tangential contributions and verify the single-contact
analytic cases below. Impact positions and elastic energy are unchanged. Include
moving-support work and paired angular impulses. The elastic body can store and
release strain energy subsequently; no additional restitution bounce is added.

Continue the remaining interval, using persistent constraints for resting contact.
Limit to 32 event partitions per attempted interval. Simultaneous zero-time impacts
are one group; chattering that exhausts the cap fails. These event pieces are staged
inside one world attempt; they do not advance the committed clock separately or
permit unbounded retries below the contract's minimum retry step. This additional
event-partition convention is a proposed part of the method, to freeze before
qualification. It is not exercised by this document's arithmetic audit.

### 3.4 Accounting and coupling boundary

Use the contract ledger, with positive W delivered to mechanics:

```text
r_mech = Delta(K_s+U_s) - W_external - W_contents - W_fluid - W_active
         + D_sliding + D_impact.
D_sliding = -sum j_t u_t,m >= 0 on sustained contact intervals.
```

Subdivide residual into element integration, solver, normal-contact discretization
and endpoint-projection terms; retain signed, absolute and positive sums. A normal
constraint ideally does zero relative work. Curved-contact discretization/projection
work remains numerical residual, even when negative. Never relabel it physical
friction, heat or fuel. Internal solid contact work and fluid/content exchanges
cancel between owners; supports contribute measured external work. No Rayleigh
damping or numerical drag is included in passive mechanics.

All impulse changes involving fluid-bearing structures would require the other
owners' simultaneous inertial response, not an M_s-only impulse followed by a
fluid redraw. **The supported contact references here are dry mechanics coupons.**
F-contract's passive chamber campaign rejects opposed wet gaps below 0.25 m,
before contact. It supplies no lubrication, drainage or wet-impact closure.
Thus a dry contact pass is not qualification of crawling through unresolved fluid
gaps. Extending that support needs an explicit coupled design and approved gate;
do not delete the intervening fluid or broaden this task to implement it.

## 4. Resolution, degeneracy and failure

Use the actual polygon for chamber geometry and physical tissue boundary facets
for contact/cuts. Stable IDs survive dense reordering; collision candidates are
recomputed from the same structural revision. No remeshing, contact skin, artificial
wall thickness or automatic representation change is supplied.

| Metric | Proposed supported condition and action |
| --- | --- |
| Reference triangles | Positive determinant, min angle >=20 degrees, shape quality `4 sqrt(3) A/sum(edge_length²) >=0.3`; reject invalid construction |
| Current triangles | J>=0.25, principal stretches in [0.5,2], condition ratio <=4, quality >=0.2; observe local strain/stress even when total area is acceptable |
| Line elements | l>=0.5 l_r, finite tangent, tensile e>=0 for the selected material; reject compression rather than changing material law |
| Boundary topology | Zero inversions, non-neighbour crossings, incorrect sides or self-intersections; no endpoint-only check |
| Fluid support | Inherit g_min=0.25 m and the contract's stated local-neighbour exclusion; it is not a mechanical contact clearance or collision-detection exclusion |
| Contact geometry | Signed gap nonnegative with robust side tests; 1e-10 L* solver tolerance bounds roundoff, not permission for finite penetration or side crossing |
| Step motion | Max vertex displacement <=0.25 h, chamber area change <=1%, inherited from F-contract; include support motion in swept checks |

Along a linear vertex path, triangle determinant is quadratic in path fraction.
Check its minimum at endpoints and any stationary point, and locate the first
J=0.25 crossing. Do this for both Newton search paths and the accepted motion path.
Shorten an admissible Newton trial to at most 0.99 of the first invalid fraction;
if no valid descent remains, reject. The log(J) singularity is not an inversion
proof. Even endpoints with J=1 can pass through J=0: F(s)=(1-2s)I is an explicit
negative control. Check line-length minima and continuous boundary intersection
with analogous swept logic, not only determinant.

Tissue coupons use a 1 m reference square split into 8x8 cells, each bisected on
the same diagonal (128 triangles), then 16x16 and 32x32 cells (512 and 2,048
triangles). Maximum edge lengths are sqrt(2)/8, sqrt(2)/16 and sqrt(2)/32 m;
retain material parameters and total mass.
The single triangle below is an exact affine patch oracle, not evidence that one
triangle resolves a deforming organism. F-contract's membrane keeps N=128, then
256/512, fixed S and line density, with recomputed reference lengths and masses.
Narrow tissue/fibers must have declared physical dimensions and resolved topology;
no fracture, buckling of a line or sub-element contact deformation is inferred.

Use base delta=0.00125 s, H=0.02 s, with at most four world-step halvings,
minimum retry delta=7.8125e-5 s, 512 attempted world steps/H and four outer coupling
passes per attempt. Count every contact partition, nonlinear/linear solve, CCD
refinement and rejected evaluation inside those work totals. A world attempt
that exhausts an inner cap fails even if other caps have room.

Implicit stability does not establish phase accuracy. Additionally propose
`delta omega_bound <=0.1` for the tested structural modes. For a uniform membrane
chain, `omega_bound=2 sqrt(S/lambda_e)/l_r`; at N=128 it is 128.8557195585/s, giving
delta omega_bound=0.16107 at the nominal step. One allowed halving meets this
proposed screen. For tissue use the true tangent and a conservative mass lower
bound, not a diagonal mass substituted in the dynamics: each triangle contributes
`(m_e/12) I` to such a lower bound. Scaled absolute row sums of the tangent give a
conservative frequency bound. Large distortion can force rejection if no allowed
step meets accuracy. The screen is not a substitute for the contract's 0.02-cycle
phase budget over the actual horizon or for force/deformation refinement.

Commit only after geometry, constitutive domains, coupled loads, constraints,
physical accounts and budgets all pass. Follow F-contract's **prefix commit**:
failed attempts leave the last accepted state and actual time unchanged; return
advanced duration, failure category and bounded offending IDs. No skipped time,
removed feature, mass change, force clamp or disabled dynamics is an allowed repair.

Checkpoint state includes rest connectivity/geometry, material/mass identities,
committed q and v/p, stable-ID allocators, prescribed-motion cursor, and physical
and numerical ledgers. Declare whether contact active sets, tie ordering and warm
starts are serialized or rebuilt deterministically; include them when they affect
continuation. Do not checkpoint an intermediate event piece or candidate projection.
Existing scene checkpoint hooks do not implement these requirements.

## 5. Worked references

These predict the selected equations' accounts. They are algebra/patch checks,
not measured trajectories, contact performance or coupled qualification. Values
are binary64, with no random seed. The checker linked in section 7 reproduces them.

### M0: membrane extension and chamber prestress

A line with l_r=0.5 m, S=1 N, lambda_e=0.1 kg/m stretched to 0.55 m has
e=0.1, T=0.1 N, energy 0.0025 J and fixed mass 0.05 kg. Equal/opposite endpoint
forces are along the line; quasistatic loading supplies that stored energy. A
0.49 m length is outside the tensile law, not a test of compressive stiffness.

For Q5, l_r=l0/1.1 and T0=0.1 N. At R=1 m the outward nodal pressure load is
`p R sin(2 pi/N)` and the inward edge load is `2 T0 sin(pi/N)`.
`p=T0/[R cos(pi/N)]` balances them exactly. Retain the contract's corresponding
content mass and the smaller rest-length structural mass; using the current edge
length as its mass reference would change this fixture.

### M1: translation, rotation and mass closure

Take X0=(0,0), X1=(1,0), X2=(0,1) m with the tissue coefficients above.
A=0.5 m², mass=0.5 kg. Any rigid translation or rotation of this rest shape has
U=0 and zero elastic force. At uniform V=(0.2,-0.1) m/s, momentum is
(0.1,-0.05) kg m/s and K=0.0125 J. Constant translation needs no force. Prescribed
acceleration a requires the nodal load M_s a and power M a dot V, with its opposite
reaction in the prescribed-motion ledger.

About c=(1/3,1/3) m the exact triangle polar inertia is 1/18 kg m². Initial rigid
velocity at Omega=0.2/s has L=0.0111111111111111 kg m²/s and
K=0.00111111111111111 J, reproduced by consistent mass and independent area
quadrature. A prescribed steady rigid rotation needs centripetal nodal loads
`-Omega² M_s(q-c)` even though elastic force is zero: their resultant, torque and
instantaneous total power are zero. A free unstressed elastic patch with that
initial velocity need not remain rigid; centrifugal deformation is not a failure
of objectivity. Force covariance is checked after rotating a sheared triangle by
0.7 rad and translating it by (2,-3) m.

For the contract's R=1, N=128 membrane, endpoint-lumped structural inertia is
0.628255450186555 kg m² versus 0.628003196451858 kg m² for uniform material along
the polygon edges. The difference 0.000252253734696284 kg m² is the declared
quadrature approximation. Content inertia is separate and is not included here.

### M2: homogeneous shear

On the same triangle impose `F=[[1,gamma],[0,1]]`, gamma=0.2. J=1 and
W=mu gamma²/2=0.04 J/m², so U=0.02 J.
`P=[[0,0.4],[0.4,0]] N/m` and `sigma=[[0.08,0.4],[0.4,0]] N/m`.
Nodal internal forces are f0=(0.2,0.2), f1=(0,-0.2), f2=(-0.2,0) N; their resultant
and current-configuration torque vanish. External quasistatic forces are opposite.
Shear loading work is `integral A mu gamma dgamma=0.02 J`; reversing the prescribed
path returns it. Area preservation in this example does not imply zero shear
energy. Finite differences of all six nodal coordinates check the force gradient.

### M3: compression and controlled recovery

Use F=alpha I, reducing alpha from 1 to 0.9. J=0.81; the actual area becomes
0.405 m² and mass stays 0.5 kg. Both principal Piola stresses are
`mu(alpha-1/alpha)+lambda_T ln(alpha²)/alpha=-1.358760139180678 N/m`.
Stored energy is 0.0651243843543848 J. With A_e=0.5 m²,
`dU/dalpha=2 A_e P_scalar`; independently integrating this expression gives the
same positive compression work to 1.42e-11 J. The inverse prescribed quasistatic
path releases that energy. This is supported **tissue** compression, not a hidden
compressive membrane model. Free release would create kinetic energy/oscillation;
it would not return to rest without a specified sink.

### M4: integration error reference

Linearize a tensile 0.5 m line with S=1 N around a force-balanced extension;
k=S/l_r=2 N/m, moving endpoint mass 0.025 kg. Keep a mean extension of 0.05 m
with an explicit constant external balancing load so the small mode never invokes
the unsupported compression branch. For perturbation y0=0.005 m, v0=0.01 m/s and
delta=0.00125 s, define z=omega² delta²/4, omega²=k/m. Midpoint gives

```text
y1 = [(1-z)y0 + delta v0]/(1+z)
v1 = [-omega² delta y0 + (1-z)v0]/(1+z).
```

The quadratic perturbation energy is constant to 8.48e-22 J in this one-step
audit. Including the balancing load's work recovers the full spring account.
Its numerical frequency is `2 atan(omega delta/2)/delta`; after 20 exact periods
the analytic phase discrepancy is -0.000208329427169 cycle, below the proposed
0.02-cycle budget. This does not establish nonlinear energy closure or high-mode
accuracy. Halving time reduces the leading smooth phase error by a factor of four;
contact, retries and coupling require their own measured convergence.

### M5: supported dry contact, friction and moving support

Use a contact-mode reference with diagonal Delassus entries 1/kg (effective normal
and tangential mass 1 kg). It is an algebraic contact-solver fixture, not an orphan
massless mesh vertex or a claim of a solved finite-element collision.

At a stationary horizontal plane, incoming velocity (0.2,-0.1) m/s, mu_c=0.5 and
zero restitution give j_n=0.1 kg m/s, j_t=-0.05 kg m/s and outgoing velocity
(0.15,0) m/s. K falls from 0.025 to 0.01125 J: physical impact loss is 0.01375 J,
split into 0.005 J normal loss and 0.00875 J tangential loss. The support gets the
opposite impulse. At contact x=0.4 m, the normal angular impulses are +/-0.04
kg m²/s about the origin; ignoring the support torque would fail the account.

For sustained contact under a prescribed downward load of 1 N, mu_c=0.3 and
initial horizontal speed 0.2 m/s, the normal reaction is 1 N and sliding friction
is -0.3 N. After delta=0.1 s, speed is 0.17 m/s and displacement is 0.0185 m.
K decreases by 0.00555 J, exactly the friction loss. The normal load/support do
zero work. A horizontal applied load of 0.2 N instead at rest is inside the static
friction cone; friction -0.2 N balances it with zero displacement or dissipation.
An upward separating load releases contact instead of producing adhesion.

For the same normal load but a belt moving at 0.5 m/s, friction on a body initially
at 0.2 m/s is +0.3 N. In 0.1 s its speed becomes 0.23 m/s and K gains 0.00645 J.
The driver supplies 0.015 J; relative-slip dissipation is 0.00855 J. Reporting only
body work would miss the belt energy. These contact intervals use their own stated
duration to expose the account analytically; they do not replace the contract dt.

For geometric negative controls: a point 0.05 m above a stationary plane moving
down at 0.1 m/s first touches at 0.5 s, and `F(s)=(1-2s)I` reaches the proposed
J=0.25 floor at s=0.25 despite positive endpoint determinants. A production CCD
and limiter must detect both; only the determinant reference is audited here.

## 6. Future actuator work without state mutation

The reserved fiber request contains stable material/fiber/fuel-owner IDs, committed
revision, interval, admissible additive tension T_act>=0 and the declared work-cost
law. It is not a write to positions, velocities, rest lengths, strain or energy.
C-mechanics stages `T=T_passive+T_act` through the same paired axial force map.
Work delivered is `W_act=-integral T_act dl`; contraction at positive tension
delivers positive mechanical work, isometric stress delivers zero mechanical work.

C-world/C-biology reserve fuel from its actual inventory owner before solving;
settle the **accepted** work and efficiency on commit and release reservations on
failure. Insufficient fuel rejects or bounds the requested tension before a new
solve, not by clipping work after the motion occurred. Zero fuel cannot supply
positive active work. Negative actuator work is a declared dissipative braking
sink by default, not automatic fuel regeneration. Maintenance cost and detailed
reaction stoichiometry remain biological design work. Any consumed fuel mass must
remain in a specified reaction product account, not vanish from structural inertia.

A proposed work audit uses T_act=0.2 N, length 0.50 to 0.45 m, passive S=1 N and
l_r=0.4 m (both states tensile). Active work is 0.01 J; passive energy decreases
by 0.009375 J. A quasistatic opposing load absorbs 0.019375 J. With efficiency 0.5
and fuel energy 100 J/kg, fuel cost is 0.0002 kg and conversion loss is 0.01 J.
Numerical, friction and impact losses cannot replenish that inventory. This is an
interface/work example; no controller or metabolism algorithm is implemented.

## 7. Validation record and qualification handoff

Capabilities used: **bitloop** for ownership/integration boundaries and
**simulation-health** for local/global oracles and horizon limits. The local
Bitloop skill, simulation-health and performance guidance were inspected.
No runtime API, build hook, physical trace or rendering capability is newly tested.

Reproduce the arithmetic and document checks from the project root:

```powershell
./tooling/check_mechanics_law.ps1 -Document
git diff --check
```

The [reference checker](../tooling/check_mechanics_law.ps1) performs 33 binary64
algebra checks plus three negative controls: nonpositive material determinant,
swept collapse despite valid endpoints, and compressed tensile-line input. It
does not implement the world solver or claim to test its rejection paths. The
largest force/energy finite-difference mismatch is 5.96e-11 N versus a 1e-8 N
audit tolerance. Compression/recovery work errors are below 1.42e-11 J versus
1e-8 J. Identity checks use 1e-12 in the named units; force covariance is within
1.12e-15 N and contact work residuals within 3.47e-18 J. These are arithmetic
tolerances, not replacement physical acceptance budgets. Decisive values and
conditions are retained in section 5; there is no physical raw run or horizon.

All three task criteria are covered: laws/mass/solver/contact/failure in sections
1-4, worked mechanical oracles in section 5, and resolution/actuator boundaries in
sections 4 and 6. Existing source, build configuration, F-contract and other design
artifacts remain unchanged. New files are this specification and its checker.

Before qualification, freeze an approved configuration and implement independent
oracles. Retain F-contract's local/cumulative energy, deformation, impulse and
volume limits, its refinement floors and its 2 s Q0-Q5 rejection screen followed
by 20/40 s behavior windows and stated extensions. Exercise Q6 bounded failure
and prefix preservation; successful dry algebra is no evidence that it passes.
For mechanical coupons additionally compare time halving and uniform mesh
refinement, cover at least 20 oscillation/load cycles and repeated contact
onset/release, then extend while late-window extrema or residual drift grow.
Check curved capsule contact, multiple contacts, grazing corners, stick/slip
transitions and self-contact continuously, with independent before/after states.
Never infer containment, strain or work from a final screenshot alone.

Complete-work timing and memory include mass/tangent assembly, all Newton/Krylov
work, contact broad/narrow phase, CCD/event re-solves, staging/projections,
coupling/rejected attempts and safety checks. Record matrix/constraint counts,
iterations, active contacts, event count, smallest gap, min J/stretch/quality,
maximum strain, solver residuals, force/work errors and every stopping reason.
Include capacities and peak scratch for mass matrices, Krylov vectors, contact
maps and candidate copies. Use the inherited base-screen limits (mean 20 ms/H,
p95 40 ms/H, max 100 ms/H, 256 MiB) only after approval and actual complete-work
measurement; no throughput or feasibility conclusion is made here.

Background references: Bower's [hyperelastic finite-element formulation](https://solidmechanics.org/Text/Chapter8_4/Chapter8_4.php)
explains virtual-work assembly and the locking risk; its three-dimensional material
formula is not substituted for this document's explicit 2D law.
[Iavernaro, Mazzia and Hairer](https://www.unige.ch/~hairer/preprints/iavernaro-mazzia.html)
discuss implicit midpoint; no smooth fixed-step conservation guarantee is extended
here to contact projections, retries or coupling.
[Baraff's contact notes](https://www.cs.cmu.edu/~baraff/pbm/rigid2.pdf) provide background
on unilateral reaction and impact models. The specific equations, scopes, caps and
numerical references above are project proposals, not qualification by citation.
