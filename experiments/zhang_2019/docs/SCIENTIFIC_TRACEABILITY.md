# Scientific traceability

Primary source: Zhang et al. (2019), *A Novel Monitoring Navigation Method for
Cold Atom Interference Gyroscope*, [doi:10.3390/s19020222](https://doi.org/10.3390/s19020222).
Page numbers below refer to the printed article. The mapping distinguishes
published concepts from implementation choices and simulation assumptions.

| Article location | Implementation | Status |
|---|---|---|
| pp. 4–6, Eqs. (6)–(10), individual interferometers and differential rotation | `sensors/figrepro_caig.m`, `figrepro_caigT20ms.m`, `figrepro_reconstruct.m` | Two separate loop probabilities retained; ideal symmetric virtual triad, conditional inverse |
| p. 7, Eqs. (11)–(13), A/F frames and errors | `sensors/figrepro_fog.m` | Simulator uses `expm(-skew(phi))`, not the article's first-order matrix |
| pp. 7–8, Eqs. (14)–(18) | `estimation/figrepro_zhang.m` | Six states, `H=[skew(reconstructed omega_A),I]`, raw F minus reconstructed A; Joseph covariance update |
| p. 9, observability discussion | `figrepro_verify.m`, `figrepro_validateT20ms.m` | Stacked, prior-scaled sensitivity rank 3 at constant rate, 6 for this sway; numerical linear rank, not a nonlinear proof |
| p. 10, Eq. (28) and simulation setup | `config/figrepro_config.m` | Zero x0 and P0 from [1,2,3] deg and three 0.1 deg/h standard deviations; bias 0.1 deg/h, sample rates 100/5 Hz |
| p. 10, section 4.1 and Figure 6 | `motion/figrepro_motion.m` | 15 knots, heading 30 deg, zero pitch/roll; geographic rates held constant at an assumed location |
| p. 11, section 4.3, Table 1 | same motion function | Level-2 roll/pitch/heading amplitudes [0.5,0.2,0.3] deg, periods [20,30,30] s; zero initial angles/speed; sine phases and Euler 3-2-1 body-rate mapping are project choices |
| pp. 11–12, Table 2 and Figure 8 | `review/run_convergence_review.m` | Compare qualitatively and evaluate a declared separate metric; only level 2, not levels 4/6 |
| p. 12, Figure 9 | fixed 5 Hz atomic rate here | Paper varies 5/20/100 Hz; increasing T here does NOT increase the data rate |

## Equations and physical assumptions

For each loop: `Phi_i = -2*T^2*k dot (Omega cross v_i) + T^2*k dot g
- 2*T^3*k dot (Omega cross g) + pulsePhase`. Each `P_i=(1-cos(Phi_i))/2`.
The stable half-angle inverse implements positive `acos(1-2*P_i)`. Then
`Omega_rec=(Phi_1_rec-Phi_2_rec)/Kdual`, with `Kdual=4*k*v*T^2` and
`Ksingle=Kdual/2`. There is no direct-rate atomic measurement shortcut.

Geometry `(k,v1)` for sensed X/Y/Z is `(Y,Z)/(Z,X)/(X,Y)`, with `v2=-v1`.
The shared laser phase `pi/2-k dot g*T^2` cancels known static gravity ideally.
Gravity is fixed at `[0,0,-9.80665] m/s^2` in A even during prescribed sway;
this is not a complete moving instrument. Rotation-gravity coupling is retained
in each loop and cancels differentially only for identical loops after valid inversion.
No finite atom count, contrast loss, phase/detection noise, laser jitter, finite
pulse duration, gravity uncertainty, acceleration cross-sensitivity or atomic bias is modeled.

At 1 ms the declared rate envelope is 0.005 rad/s. The bound
`2*k*(v*T^2+norm(g)*T^3)*0.005 < pi/2` certifies the assumed loop interval
given these idealizations. FOG does not select sign or fringe. At 20 ms the
bound fails; a simulator-phase audit blocks the main KF. That audit is NOT
a detector available from probabilities alone. The separate known-branch
control receives simulator signs and integers, then inverts both probabilities.
Its downstream filter has no truth input; the overall control does.

The 1 ms measurement uses midpoint/quasi-static motion and FOG interpolation.
The 20 ms model substitutes a 40 ms rectangular mean (1000 Hz reference,
100 Hz FOG, trapezoidal quadrature) into the phase equations. Neither is a
derived atom-interferometer sensitivity function. There is an 8 ms assumed
readout, giving availability offsets 10/48 ms, with a fixed 200 ms shot period.

## Parameters adopted elsewhere or chosen here

| Value | Provenance and scope |
|---|---|
| 780.241209686 nm; k=4*pi/lambda | Steck, *Rb-87 D Line Data*, revision 1.6, p.15 Table 3 ([source](https://www.steck.us/alkalidata/rubidium87numbers.1.6.pdf)); counterpropagating Raman approximation |
| 2.79 m/s; nominal reference T=24.7 ms | Tackmann et al., [doi:10.1088/1367-2630/14/1/015002](https://doi.org/10.1088/1367-2630/14/1/015002), abstract and pp.9–11; reference T is inactive, their measured sensitivity is not imported |
| 0.002 deg/sqrt(h) FOG ARW | [EMCORE EG-1300 specification](https://www.emcore.com/product/eg-1300-fiber-optic-gyroscope-fog/), upper bound adopted as fixed simulation value, not Zhang's noise |
| T=1 or 20 ms, 600 s, seed 5606 | Project choices; no physical noise improvement is inferred from changing T |
| latitude 45 deg, height 0, WGS84 a=6378137 m, f=1/298.257223563, Earth rate 7.292115e-5 rad/s | Project geographic assumptions in constant-speed case; 0.514444 m/s per knot retained; no position propagation |
| Q=0, F=I | Deterministic constant-state specialization of Zhang Eq. (14); no numerical Q is supplied for this reproduction in the paper |
| R from actual interpolation/integration weights | Project white-noise propagation, ideal atomic readout; paper does not specify a reproducible numerical R/noise realization for section 4 |
| inverse clipping tolerance 32*eps, relative rank threshold 1e-8, timestamp tolerance 64 ulps | Numerical safeguards, not physical accuracy specifications |

All active numbers are in `config/figrepro_config*.m`. Sway omits Earth/transport
rates; constant-speed includes them. The injected [1,2,3] degrees are a finite
rotation vector in the simulator, whereas the estimated state is a small-angle
vector. This produces the model discrepancy quantified in the convergence analysis.

## MATLAB noise convention

The [MathWorks imuSensor algorithm](https://www.mathworks.com/help/nav/ref/imusensor-system-object.html)
uses sample sigma `NoiseDensity*sqrt(Fs/s)`, with s=1 for single-sided and s=2
for double-sided. Here density is `deg2rad(0.002)/60` and sigma at 100 Hz is
5.817764173e-6 rad/s. The `/60` converts sqrt(hours) to sqrt(seconds).
[gyroparams NoiseType](https://www.mathworks.com/help/nav/ref/gyroparams.html)
was added in R2023b. This verifies the chosen MATLAB convention, not an
independent calibration of the manufacturer's spectral convention.

FOG frame rotation is applied before `imuSensor`; its two-input identity-orientation
use is a component-noise adapter in F, not a navigation attitude simulation.
Default axis errors and gyro acceleration sensitivity are zero. No second
misalignment correction is applied. Internal rates are rad/s, angle states rad,
bias states rad/s; displays use deg and deg/h.

## Validation scope

`figrepro_verify.m` and `figrepro_validateT20ms.m` check the implemented
phase/rate identities, probability dependence, causal synchronization and
linear sensitivity under the configured assumptions. Their numerical results
are recorded in `review/results/`. `review/run_convergence_review.m` separates
noise-realization effects from finite-rotation/linear-estimator discrepancies
using the [predefined evaluation protocol](CONVERGENCE_PROTOCOL.md).

These checks establish numerical consistency of the stated simulation, not
hardware performance or a solution to periodic-measurement ambiguity. The
known-branch control supplies simulator sign/fringe labels to test the
conditional inverse and downstream estimator; it is not an operational result.
