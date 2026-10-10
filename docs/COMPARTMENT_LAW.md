# F-contents-law: pressure-bearing compartments

Draft 1, 2026-10-10. MindGraph task **T-design-contents**.
This is a candidate specification, not an implemented or adopted physical model.
All additional numerical limits and example parameters below are **PROPOSED /
UNAPPROVED**. The inherited fixture values and budgets remain unapproved too.

Input inspected: [F-contract, draft 1.1](PHYSICAL_CONTRACT.md), SHA-256
`48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07`.
The current [scene](../Substrate/Substrate.cpp) contains only the diagnostic pilot;
it has no compartment implementation and its checkpoint hooks return false.
This deliverable adds no runtime dependency, solver, thermal model or alternative
world. The passive proof and subsequent active laboratory remain the work-package
scope; this design does not claim rich-world scale or endurance.

## 1. Meaning and ownership

A compartment contains one spatially uniform composition and areal density. Its
mass is real; its geometry and velocity field determine its inertia. Uniform
composition is a constitutive approximation, not permission to create circulation,
erase a jet, pool connected chambers or attach their mass to membrane vertices.

| Owner | Authoritative state or output |
| --- | --- |
| C-mechanics | Oriented structural loops, vertex positions and velocities, structure mass, supports. Content inertia enters its coupled equations but is never added again as structural mass |
| C-boundary | Actual area, centroid, area moments, oriented facets and their velocities, physical port locations/sides. Derived geometry owns no inventory |
| C-contents | Constituent masses, material law, admissible circulation state, closure identity, and content energy/momentum accounts. Pressure, density, total mass and inertia are derived |
| C-fluid | Any explicitly resolved interior instead of this compartment, and the exterior. A region cannot have both owners |
| C-world | Candidate/commit boundary, stable IDs, time, exchange settlement and bounded failure |

Use chamber/material/port IDs and generations with the committed revision. Dense
quadrature, triangulation and solver indices are disposable. Each constituent
mass q_s is in kg; M=sum(q_s)>0 and Y_s=q_s/M. Species partition M. This draft
allows inert tracer constituents with the **same** barotropic material law; it
does not infer mixture pressure from fuel, temperature or a gas-law particle count.
Changing material parameters or reacting species requires an explicit energy law.

Lengths are m, actual area A is m², rho=M/A is kg/m², pressure is N/m, inertia
is kg m², circulation is m²/s, energy is J. There is no hidden thickness. The
normal n points from contents to the exterior on the CCW loop. Positive wall work
is delivered **by contents to wall**. Exterior loads are posted separately.

## 2. Pressure, storage and finite changes

Retain the contract's single barotrope, with rho0=1 kg/m² and B=10 N/m in its
fixtures (B is the contract's bulk coefficient K). For an actual area A and the
current mass M, define:

```text
Aref = M/rho0                    z = A/Aref
pbar = B (1/z - 1)              rho = M/A
U(A,M) = B [A - Aref - Aref ln(z)]
e = U/M                         h = (B/rho0) ln(rho/rho0)
partial U/partial A = -pbar      partial U/partial M = h = e + pbar/rho
c² = dpbar/drho = B/rho0        dU = -pbar dA + h dM
```

U is recoverable barotropic compression energy relative to the common p=0
reference, not a thermal or metabolic reservoir. U>=0, with its minimum at
A=Aref. Its fixed-area mass curvature is B/(rho0 M)>0. Negative h or pbar relative
to this reference is possible and is not a negative inventory or a numerical
failure. Material tension/cavitation outside the declared range is not modelled.
Require z in [0.8,1.2], finite positive A and M; do not clamp pressure or invent a
minimum mass to avoid a failure. Emptying a chamber is a topology/representation
event requiring another design, not a valid state of this law.

Area is recomputed from the actual proposed polygon, never integrated as a second
independent volume. Aref changes with mass; keeping it at its initialization value
after transfer would break both pressure and energy. Use stable log evaluation
near z=1 to avoid cancellation in U.

For a finite fixed-mass area change, the pressure used for total work is the
secant `p_d = -[U(A1,M)-U(A0,M)]/(A1-A0)`, using the derivative limit at zero
change. If A and M change together, choose the straight positive-state path
`(A(s),M(s))`, s in [0,1], and its integrated derivatives p_d and h_d. Then
`Delta U = -p_d Delta A + h_d Delta M`. Either evaluate the integrals to the
accounting tolerance or split the stages with explicit intermediate energies;
do not mix endpoint pressure work with an unrelated mass-energy update.

For vertex coordinates x, the mean-pressure generalized wall force is
`pbar grad_x A`. The finite counterpart uses a discrete area gradient satisfying
`sum_i grad_d A_i dot Delta x_i = Delta A`. A straight vertex path integrated
gradient supplies this identity for polygon area. Thus the posted mean-pressure
work is +p_d Delta A at the wall and -p_d Delta A at contents. It is zero on a
rigid translation or rotation. The inertial traction below supplies the missing
loads when content momentum changes; a constant pbar alone has zero closed-loop
resultant and cannot accelerate the contents.

## 3. A sealed, uniform-density inertia closure

### 3.1 Velocity is derived from normal motion and circulation

Select a simply connected, fully filled, inviscid, slip-wall closure with spatially
uniform vorticity. It supports non-affine boundaries through an auxiliary
geometry solve; it is not a claim that an arbitrary deforming chamber has an
affine velocity field. No free surface, internal obstacle or separate vortex is
represented. For a sealed chamber let c be its area centroid, r=x-c, J r=(-r_y,r_x),
and Gamma its independently initialized circulation. Set:

```text
d = A_dot/A                  omega = Gamma/(2 A)
v = c_dot + omega J r + grad(phi)
Laplacian(phi) = d           in the actual chamber
normal_derivative(phi) = (v_wall - c_dot - omega J r) dot n
integral(phi dA) = 0         (fixes the scalar nullspace)
Gamma_dot = 0               for the sealed inviscid closure
```

The compatibility condition is `integral(boundary data dl)=A_dot=d A`.
An inconsistent wall flux is a rejection, not a mean RHS to subtract silently.
The same geometry must supply A_dot and the facet velocities. The area-average
of v is c_dot by the transport identity for the centroid; the potential's mean
gradient is therefore zero. Initial Gamma is specified by the experiment, usually
zero. An angular wall speed is **not** an initialization or update for Gamma.

This is a kinetic closure over the existing content owner, not a second set of
fluid inventories. Define its exact moment and energy outputs:

```text
Q = (1/A) integral(r r^T dA)       I = M trace(Q)
P = rho integral(v dA)            L_c = rho integral(r cross v dA)
Kc = (rho/2) integral(|v|² dA)
```

Kc is positive for nonzero velocity. Rigid velocity `v=V+Omega J r` gives
P=M V, L_c=I Omega and Kc=M|V|²/2+I Omega²/2. It is recovered when the initial
circulation is 2 Omega A and the normal boundary motion is compatible. Affine
dilation gives v=V+alpha r and Kc=M|V|²/2+M alpha² trace(Q)/2. A general affine
velocity is recovered by its symmetric quadratic potential and matching uniform
vorticity. These are polynomial reproduction requirements, not an instruction to
force that state when the boundary only prescribes a normal velocity.

In particular a circular wall spinning tangentially around contents initially at
rest supplies no normal motion and no inviscid torque: Gamma remains zero, v=0.
Well-mixed chemistry must not change that answer. An ellipse rotating from rest
generates an irrotational interior flow, not rigid co-rotation (section 6).

### 3.2 Inertial traction and work

Evaluate `a = partial_t v + (v dot grad)v` on the same candidate trajectory.
The uniform-vorticity evolution above makes curl(a)=0 in the continuum closure.
Recover an inertial pressure pi from:

```text
grad(pi) = -rho a             integral(pi dA) = 0
p_wall = pbar + pi
force on wall facet = integral((pbar + pi) n dl)
```

Conservative uniform body acceleration, if introduced, replaces a by a-b and
adds its external work; the present passive fixtures have none. pi is a constraint
reaction enforcing the reduced density/velocity assumption. It is **not** a second
EOS, stored energy, or a claim that spatial density changes are resolved. Its
zero-area-mean gauge keeps the compression store and the inertial reaction distinct.
Calling pbar the complete local wall pressure in an accelerating chamber is wrong.

For the sealed closure, continuity and zero mean pi give these identities:

```text
P_dot = -integral_boundary((pbar+pi) n dl)
d/dt angular momentum about fixed origin = -integral_boundary(x cross (pbar+pi)n dl)
Kc_dot = -integral_boundary(pi v_wall dot n dl)
U_dot = -pbar A_dot
(Kc+U)_dot = -integral_boundary((pbar+pi) v_wall dot n dl)
```

Post the opposite impulse and identical signed work to the wall, using the same
quadrature and candidate velocities. Neither setting Kc from a wall snapshot
without an inertia force, nor applying `M times acceleration` while omitting
shape-dependent terms, satisfies these identities. A solver must retain the full
geometry/time derivative of the closure and its coupling to wall acceleration.
Do not apply a second lumped-mass reaction in addition to pi.

### 3.3 Numerical realization and limits on its cost

For a reference realization select continuous quadratic potential functions on a
deterministic conforming triangulation of the actual polygon. Integrate polynomial
moments exactly to their required degree. Solve the mean-constrained weak form
`integral grad(phi) dot grad(psi) = integral_boundary g psi - integral d psi`.
It reproduces the affine examples without inventing interior mass nodes. Use
matrix-free or sparse assembled projected CG with diagonal scaling, measured true
residuals and the contract's bounded iteration policy. This is a proposed reference
discretization, not a dependency request or an implementation in this task.

Recover pi by the corresponding weak gradient equation. Recompute the full vector
defect `rho a + grad(pi)` and normal-velocity defect independently; a least-squares
pressure projection cannot conceal incompatible acceleration/curl. Enforce the
contract's pressure/flux and work budgets, refining this auxiliary mesh separately
from the exterior grid. Report quadrature, mesh and time errors independently.
Quadratic C0 potentials have discontinuous element gradients: evaluate acceleration
and traction in a consistent weak form including element-interface terms, not by
treating a broken gradient as globally smooth. The discrete kinetic-energy
derivative and posted wall work must still agree to the contract's budgets.
Use a fixed maximum 200 iterations per solve and 4 coupling passes per attempt,
inherited as unapproved caps; failure cannot launch an unlimited fallback solver.
Degenerate triangles or loss of simple connected geometry reject the attempt.

All auxiliary assembly, mesh maintenance, geometry derivatives, solves, staging,
checks and retries belong to complete-work timing and memory. Report unknowns,
iterations, residuals, retained matrices, mesh and scratch alongside exterior
fluid costs. This closure might cost too much to serve as cheap contents; only a
complete measured candidate can settle that. There is no performance claim here.

## 4. Opening and transfer contract

### 4.1 One route and one ledger

An intact boundary has no route. A port has a stable ID, a real open segment and
length, orientation, source/receiver side, wall velocity, material identity and
law identity. A zero-storage resistive port is a **zero-volume interface** between
adjacent owners. A finite-length channel with appreciable stored mass, delay or
inertia must belong to C-fluid or a separately defined physical contents region;
it cannot be an unowned pipe. This draft does not prescribe its detailed flow law.

| Entry for a finite exchange | Required meaning |
| --- | --- |
| Revision and interval | Same accepted candidate interval at both owners; consume once on commit |
| Delta q_s, Delta m | Remove donor fractions of the actual accepted mass; add exactly those amounts to receiver. Sum Delta q_s=Delta m |
| Spatial route | Shared interface point/segment and physical side; retain quadrature point application positions for angular momentum |
| Carried impulse | Integral v_port dm, using the donor-side solved velocity in the common inertial frame. Separate port pressure/viscous reaction impulses |
| Carried energy | Integral (e+|v_port|²/2) dm, plus pressure work from the same port state and motion; dissipation and any channel storage separate |
| Receipt | Accepted mass, impulse, angular impulse, storage/work changes and nonnegative physical dissipation; failure invalidates the whole pair |

At a moving port with normal pointing out of owner a,
`mass_out_rate = integral rho_a (v_a-v_port_wall) dot n dl`.
Pressure work out of a is `integral p_a v_a dot n dl`; separating the moving-wall
part leaves flow work `(p_a/rho_a) mass_out_rate`. At a stationary port the sum of
advected stored energy and flow work is `h_a mass_out_rate`, augmented by
`pi_a/rho_a` when the inertial reaction contributes. Do not post both enthalpy and
the same pressure-flow work. Moving supports also exchange metered impulse/work.
Equal mass rates need not mean equal volume rates when densities differ.

Port velocity is solved from normal flux, tangential boundary data and the donor
velocity closure, not chosen to make a visually plausible jet. Any velocity change
inside a channel has a paired reaction on its walls and a work/storage/dissipation
account. Noncoincident impulse applications require their physical couple; equal
linear impulses alone do not close angular momentum.

### 4.2 Finite conductance, energy and mixing

For a **quasistatic, stationary, same-material resistive interface** the illustrative
law is `m_dot = G (h_a-h_b)`, G>0 with units kg²/(J s). It relaxes pressure because
h is monotone in density for this material. G is a declared parameter, not inferred
from gap size alone. For a fixed-geometry finite step define

```text
h_a^d = [U(Aa,Ma)-U(Aa,Ma-dm)]/dm
h_b^d = [U(Ab,Mb+dm)-U(Ab,Mb)]/dm
dm = dt G (h_a^d-h_b^d)
D_hyd = dm (h_a^d-h_b^d) = dm²/(dt G) >= 0
Delta Ua + Delta Ub + D_hyd = 0
```

Use the derivative limit at dm=0 and a bracketed monotone solve (maximum 64
iterations for this proposed example). Require the true mass-equation residual
to be at most 1e-12 kg for the 1 kg reference scale, and at most one hundredth of
the contract's local mass allowance at other scales. For reversed head, exchange
donor and receiver roles and retain the signed posting in the original route;
upwind fractions and velocity always come from the actual donor.
Require the donor, both z ranges and a
proposed 1% maximum donor-mass change per accepted substep. Also bound transfer by
the equal-density mass for the two volumes, so a large step cannot overshoot and
swap their pressure order. Exceeding a bound requests a bounded smaller substep;
it never clips dm after calculating momentum/work. A closed port has G=0 and
dm=0 exactly. Two chambers remain separate inventories and concentrations.

This law consumes pressure/free-energy difference as explicitly modelled hydraulic
physical dissipation. With no thermal state it is a nonrecoverable sink recorded
in D_physical; it is never returned as fuel. A model intended to predict heating
must carry that thermal state in later scope. The law is not a general inertial
channel law: when kinetic heads, moving supports or pi are material, solve their
momentum and energy balance as well. Reusing the h-only formula for those cases
without those accounts is unsupported.

Composition mixes **only within the receiver** according to its declared well-mixed
approximation: `(q_s,b+dm Y_s,a)/(Mb+dm)`. It does not set both owners to a shared
concentration. Inlet kinetic energy likewise cannot disappear just because a
receiver stores fewer modes. For a translational capture audit, a packet dm at
velocity w joining mass Mb at velocity Vb gives

```text
P_b' = Mb Vb + dm w                  Vb' = P_b'/(Mb+dm)
D_capture = 0.5 dm Mb/(Mb+dm) |w-Vb|²
K_b' - K_b = 0.5 dm |w|² - D_capture
```

This is an explicit perfectly inelastic mixing idealization and a ledger test,
not a rule to dissipate every unresolved motion. General receipt must retain
angular momentum and all supported velocity modes, deriving its capture loss
from their positive kinetic metric. A negative required loss, unmatched torque,
unrepresentable circulation or a physically important inlet jet rejects reduced
receipt and requires a resolved interior. No global velocity/energy correction is
allowed to make a transfer pass.

### 4.3 Spatial compatibility and the scope of an exchange audit

For an open chamber uniform-density continuity requires
`div(v)=A_dot/A-M_dot/M`; port normal data include its actual mass flux divided by
that owner's density. The auxiliary solve must satisfy this compatibility, along
with the receiver's momentum and energy ledger, before a coupled step can commit.
In particular, with `j=(v-v_wall) dot n`, the open-chamber first-moment identity is
`P=M c_dot+integral_boundary rho (x-c) j dl`. The sealed identity P=M c_dot
cannot be used unchanged while mass crosses an off-centre port. The potential
now generally has a nonzero mean gradient; compute P from its actual field.
Inflow cannot arbitrarily reset Gamma or spread local vorticity uniformly. Nonzero
Gamma is supported here only in sealed chambers. This draft supports irrotational,
slowly varying inflow only when the closure and
reaction accounts are compatible; vortical injection and rupture jets require
C-fluid. No general vorticity-injection or finite-channel algorithm is claimed.

The worked exchange below is an exact **isolated exchange-account reference** at
fixed geometry, with a translational capture subproblem. It does not solve the
two chambers' open-boundary spatial flow or certify that a coupled trajectory at
that rate meets this closure's validity limits. Those are separate implementation
checks. A successful packet ledger is necessary and not sufficient for a valid
pressure-driven opening. Finite transport is demonstrated without claiming an
invented homogeneous velocity is a solution of the inlet flow.

## 5. Validity, failure and restart

The density constraint deliberately removes acoustic propagation and spatial
density variations. Proposed screening conditions are
`max |v-c_dot|/c <= 0.1`, `max |pi|/(rho c²) <= 0.01`, and an acoustic crossing
time `diameter/c <= 0.1 T_forcing`. These are conservative initial validity screens,
not physical-error proofs or approvals. Compare to an independent resolved model
at the contract's force/work and trajectory budgets before adopting the reduction.
Chemistry requires a separately justified mixing time at most one tenth the
shortest transfer/reaction time; this draft makes no chemical mixing measurement.

Use a resolved interior when spatial density/acoustic response, sloshing/free
surfaces, stratification, concentration gradients, jets, circulation structure,
viscous spin-up, local shear transport or channel storage changes the experiment.
Multiple holes, pinching/disconnected chambers and unsupported normal motion are
outside this simply connected closure. Preserve the contract's 0.25 m minimum
feature and other support checks. No automatic representation switching is added;
select supported ownership in the fixture before execution or fail honestly.

The mass and energy law remains defined beyond the kinetic approximation's
validity; a finite pbar is not evidence that the closure can advance that state.
In particular:

- Q0 is a rest identity test. Q1/Q2 require radial inertia, not massless contents.
- Q3 acceleration needs the inertial pressure gradient; constant area does not
  eliminate support work.
- Q4 must distinguish initially rotating contents from a wall rotating around
  initially stationary slip contents. The ellipse also challenges the uniform
  density approximation quantitatively (section 6.2).
- Q5 needs the non-affine solve and its measured cost and validity; a scalar radius
  model cannot claim that case. Q6 must preserve the last valid prefix on failure.

All content/port solves, geometry and mechanics stage together. Recompute actual
area, density, composition, kinetic energy, circulation consistency, local work,
momentum and support/validity diagnostics before commit. Apply F-contract's prefix
commit semantics and retry caps; no missing interval, negative-amount clipping,
unrecorded circulation change, pressure clamp or silent freeze is permitted.
Attempt logs are diagnostic; physical ledgers change only on accepted steps.

Checkpoint-relevant content state is chamber/material/port IDs and generations,
species amounts, material constants, circulation and closure version, committed
geometry/motion references, actual time, external/port schedule cursor, and
cumulative physical/numerical accounts. Content momentum represented through the
coupled kinetic closure is stored once in that declared generalized-state
representation; derived P, L and K must agree after restore. Rebuild area/moments,
phi and pi deterministically or save solver/mesh history when it changes the
accepted continuation. No uncommitted packets survive a restart. The current
Bitloop hooks provide none of these guarantees yet.

## 6. Worked account references

These are analytic/algebraic checks, not numerical trajectories or qualification.
All cases use binary64; no randomness. The script in section 7 reproduces the
reported numbers. The discrete polygon is used where stated; continuum circles
and ellipses are separate refinement references, not substituted polygon areas.

### 6.1 Translation and initialized rotation

For the N=128, R=1 m base polygon, A=M=3.140331156954753 in m² and kg, and
`trace(Q)=(2+cos(2 pi/N))/6`. I=1.5695351340759076 kg m². At V=(0.2,-0.1) m/s,
P=(0.628066231390951,-0.314033115695475) kg m/s and
Kc=0.07850827892386883 J. At a_c=(0.03,0.04) m/s²,
`pi=-rho a_c dot r`; contents exert wall force
(-0.0942099347086426,-0.125613246278190) N and wall power
-0.006280662313909506 W. The support provides the opposite force/work to contents;
pressure-storage work is zero because A is fixed. Edge quadrature checks both
force components, torque and power independently of the moment formula.

Initialize actual rigid spin at Omega=0.1/s with Gamma=2 Omega A. Then
L_c=0.156953513407591 kg m²/s and Kc=0.007847675670379538 J.
`pi=rho Omega² (|r|²-trace(Q))/2` balances centripetal acceleration. Its integrated
torque and wall power are zero at constant spin. This energy was supplied in the
initial state; it was not generated by turning a slip wall. With radial scale R
changing and Gamma fixed, Omega varies as R^-2, I as R², so L_c stays constant;
spin energy changes through the computed radial wall work, not a fixed Omega rule.

### 6.2 Rotating ellipse and the Q4 routing limit

For a continuum ellipse with axes a,b rotating at instantaneous angular speed
Omega from irrotational contents, the potential is `phi=k x y` in its aligned
frame, where `k=Omega(a²-b²)/(a²+b²)`. Its normal velocity matches the rotating wall.
Its kinetic rotational coefficient is
`I_irrot=M(a²-b²)²/[4(a²+b²)]`; the rigid-spin coefficient is
`I_rigid=M(a²+b²)/4`. They describe different states and must not be interchanged.
The pressure reaction, including derivatives of the rotating frame, supplies
torque and work. A circle has I_irrot=0 while its initialized rigid-spin inertia
remains M R²/2.

At a=1.25 m, b=0.8 m, M=pi kg these coefficients are
0.303463675727469 and 1.72983945488288 kg m². The specified Q4 period of 2 s gives
Omega_peak=pi²/2 per second. The irrotational velocity has peak magnitude
`|k| a = 2.5836294154384025 m/s`; c=sqrt(10)=3.16227766017 m/s, giving 0.8170153583,
well above the proposed 0.1 screening limit. A crossing-time ratio is also too
large (2.5/c divided by 2 s is about 0.395, above 0.1).

**Decision-bearing limitation:** the existing Q4 ellipse cannot be qualified by
this low-acoustic-speed-variation reduction under these proposed validity screens.
This is an analytic input/assumption mismatch, not a measured density error or a
failed runtime solver. Keep the fixture unchanged; a review must select a suitable
resolved interior (including compressibility if necessary), or explicitly approve
changed scales after assessing the physical budgets. Slowing the fixture silently
or interpreting wall rotation as fluid spin would conceal the mismatch.

### 6.3 Free expansion

Use F-contract's circular Q1 oracle: M=1.1 pi kg, shell mass 0.2 pi kg, R0=1 m,
outer reservoir radius 4 m, exterior rho=1 kg/m² and edge coefficient S=1 N.
At R=1.02 m and R_dot=0.1 m/s, the contract's coupled radial equation gives
R_ddot=0.3089800747511852 m/s². Interior `v=(R_dot/R) r`,
Kc=M R_dot²/4 and `pi_wall=-rho R R_ddot/4=-0.08330345152605485 N/m`.
Thus the net outward content wall power is 0.31374721716642046 W and
`Kc_dot+U_dot+W_wall_dot=0` to 5.56e-17 W in the audit.
The inertia term is exactly the M/2 term in the contract's radial equation;
adding another M/2 wall mass would double count it.

For completeness the independent audit differentiates the shell elastic and
kinetic energy and exterior kinetic energy `pi rho_f (R R_dot)² ln(Ro/R)`.
Adding the outer advected kinetic flux `pi rho_f (R R_dot)³/Ro²` leaves
1.32e-17 W. No reservoir kinetic outflow is discarded. This is a point identity,
not a time integration or evidence of stable free expansion over its horizon.

### 6.4 Compression and recovery

Use the actual base polygon with M=A0 kg and prescribed Q2 radius from 1 to
0.9 m. The area becomes 0.81 A0, not 0.9 A0. At the turning point velocity is
zero; pbar=2.3456790123456783 N/m and U=0.6507090024477902 J. The work received by
contents from the mean pressure is `-integral pbar dA=+0.6507090024477902 J`.
An independent 10,000-panel midpoint integral agrees within 2.48e-10 J.
Recovery returns that compression store to zero. During motion retain
`Kc=M trace(Q0) R_dot²/2` and the corresponding pi work; endpoints at rest do not
justify dropping transient inertia. Ideal complete-cycle content work is zero;
structure/exterior/support accounts still belong to the full Q2 experiment.

### 6.5 Connected finite-rate exchange and capture ledger

Take two distinct fixed-area owners Aa=Ab=1 m², Ma=1.1 kg, Mb=0.9 kg, with the
same material, tracer fractions 0.2 and 0.1, an adjacent resistive interface,
G=0.005 kg²/(J s), and dt=0.1 s. These are additional proposed reference values,
not a change to the passive sealed fixtures. Solve section 4.2's finite equation:

| Observation | Value |
| --- | --- |
| dm, m_dot | 0.000998311836412136 kg; 0.00998311836412136 kg/s |
| Donor/receiver energy secants | 0.948562643580380 and -1.048061029243595 J/kg |
| D_hyd, equal to minus total compression-energy change | 0.001993253045440846 J |
| Receiver tracer fraction after receipt | 0.10011080063339711; donor stays 0.2 |

Only about 0.001 kg moves; the equal-density amount would be 0.1 kg. Neither
pressures nor concentrations become identical in this finite interval. Negative
receiver h is permitted by the fixed energy reference and does not reverse the
positive hydraulic dissipation. Total mass remains exactly 2 kg in the audit;
species postings remove/add the same donor fractions.

For the companion one-dimensional impulse/capture ledger, use port length 0.25 m
and mean donor density 1.1-dm/2. The **flux-derived** upstream speed is
`w=m_dot/(rho_a,mean length)=0.036318729241025284 m/s`. Let the donor translational
mode have this speed and the receiver mode initially -0.02 m/s. The receiver's
post-capture mode is -0.019937598491279733 m/s. Post dm*w at the same interface
point to both owners with opposite signs; take centres/route/velocities collinear
on x so that angular momentum about the origin is zero. The removed donor kinetic
energy is dm*w²/2; the receiver stores that amount minus
D_capture=1.5814681532316898e-6 J. Combined momentum residual is 3.47e-18 kg m/s.

The donor's combined stored/flow-energy removal is dm*h_a^d and the receiver's
compression-energy gain is dm*h_b^d; the difference is the declared resistive loss.
Together with kinetic capture,
`Delta(Ua+Ub+Ka+Kb)+D_hyd+D_capture=0` to 1.67e-19 J. These are separate physical
loss mechanisms and neither is a numerical residual. Application to a real
moving/jet-producing connector needs its additional reaction work and spatial
compatibility in section 4.3; this account example claims no such trajectory.

## 7. Verification record and implementation gates

Relevant capability IDs used: **bitloop** (ownership and diagnostic boundary) and
**simulation-health** (local/global oracles, honest horizon classification).
Read the local skill and routed health guidance; no Bitloop runtime capability was
needed for this document task. No package, build preset or existing source changed.

Reproduce the specification arithmetic and document checks from the project root:

```powershell
./tooling/check_contents_law.ps1 -Document
git diff --check
```

The [audit script](../tooling/check_contents_law.ps1) is a standalone binary64
reference calculation, not production simulation code. Its 20 algebra checks
cover differentiated storage, independent polygon edge integration, radial work,
compression quadrature and finite exchange/capture. Audit tolerances are 1e-8 in
the indicated units for finite differences/quadrature and 1e-12 for exact
identities; they are arithmetic-check tolerances, not substitute physical budgets.
Observed pressure and mass-energy derivative errors were 1.12e-10 N/m and
8.03e-11 J/kg. All 20 checks passed after correcting a PowerShell array-expression
parenthesis in the checker. Required document terms, local link targets and
whitespace are also checked. Compact decisive outputs are retained in section 6;
there was no physical raw run to archive or simulated horizon to report.

F-contract's local and cumulative budgets, dt/refinement matrix and behavioral
horizons remain the gates for an implementation. For sealed mechanics use its
2 s rejection screen, 20 then 40 s behavior windows, and stated extensions;
include a zero-circulation spinning circle and the ellipse state distinction.
For an eventual opening experiment cover at least ten relaxation times
`tau ~= 1/[G (partial h_a/partial Ma + partial h_b/partial Mb)]`, plus onset,
closure and flow reversal, and extend while inventory/work drift is unresolved.
For the equal 1 kg, 1 m² owners above the linearized tau is 10 s. Freeze approved
scales and validity limits first; do not run an unsupported case and call its
continued numerical motion physical acceptance.

Before adoption also demonstrate non-affine Q5, compatible open-port spatial
flow, local inertial traction/flux refinement, conservation under failed attempts,
restart continuation, and complete cost including the auxiliary inertia solves.
Those are future implementation/qualification work, not tests asserted to have
run for this specification. Reserved active/fuel/sensing interfaces remain as in
F-contract; this law supplies no active energy from numerical or hydraulic losses.

| T-design-contents acceptance | Location |
| --- | --- |
| Geometry/inventory pressure, storage, mass/inertia, forces and paired work | Sections 1-3 |
| Translation/rotation, expansion, compression and finite-rate reference accounts | Section 6 and executable algebra audit |
| Opening amount/momentum/energy ownership and validity limits | Sections 4-5 |

Standard continuum background for the control-volume work terms is Richard
Fitzpatrick's [Energy Conservation](https://farside.ph.utexas.edu/teaching/336L/Fluidhtml/node14.html).
His [Circulation and Vorticity](https://farside.ph.utexas.edu/teaching/336L/Fluidhtml/node62.html)
and [Irrotational Flow](https://farside.ph.utexas.edu/teaching/336L/Fluidhtml/node64.html)
explain the circulation and potential-flow identities. The uniform-density
closure, project barotrope, finite secants, validity screens and numerical values
here are project-specific proposals/derivations, not results certified by those
references.
