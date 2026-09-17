# T = 20 ms: branch failure and downstream control

Run either T20ms script from this directory. No saved baseline is needed.
`reproduce_all` additionally generates fresh, explicit comparison inputs.
Each run writes separately under `outputs/runs/`; existing files are not overwritten.

Ksingle = **35948.036149664 s**, Kdual = **71896.072299327 s** (400 times the
1 ms gains). Sequence duration is 40 ms, midpoint start+20 ms and availability
start+48 ms. Shots remain 5 Hz. All phase terms, compensation, inverse scaling
and matched FOG integration use the active T. Both loop histories are retained.

| Diagnostic, 3000 shots per case | Constant speed | Level-2 sway |
|---|---:|---:|
| Max absolute loop phase (rad) | 3.377883594 | 107.113239719 |
| Max absolute differential phase (rad) | 3.750599309 | 197.221716680 |
| Shots with any loop outside [0,pi] | 100% | 100% |
| Shots requiring any negative wrapped sign | 100% | 98% |
| Shots requiring any nonzero fringe integer | 100% | 100% |
| Shots requiring sign OR fringe | 100% | 100% |
| Shots with any absolute loop phase > 2*pi | 0% | 100% |
| Truth-free probability inverse valid | No | No |
| Normal Zhang filter | Blocked | Blocked |
| Known-branch control rank | 3/6 | 6/6 |

Statistics use `Phi=s*alpha+2*pi*n`, wrapped into [-pi,pi]. Nonzero n can already
be needed for pi<Phi<2*pi. Thus constant-speed nonzero fringe labels do not mean
its phases exceed 2*pi. Probabilities alone have unbounded sign/fringe families
at either T; at 1 ms a declared design bound excludes alternatives. It fails
at 20 ms. These statistics come from simulated phases, not an operational detector.
Per-axis and per-loop maxima/counts are in the versioned summary JSON files.

The control receives simulator signs and integers, then reconstructs each phase
through its probability. It verifies the downstream path conditionally. Constant
motion remains non-identifiable; sway estimates approach the injected parameters:

| Control | Angles [X,Y,Z] deg | Bias [X,Y,Z] deg/h |
|---|---|---|
| Constant | [0.707408,2.371214,2.689082] | [-0.020947,-0.005925,0.061349] |
| Sway | [1.001026,2.014020,2.986514] | [0.102583,0.096007,0.085323] |

Main figures are blocked-run notices, not fabricated filter histories. Each case
saves two notices, an ambiguity figure and two control figures (PNG/FIG), plus
main/control MAT and JSON files. Prefixes are `figure6_T20ms_constant_speed`
and `figure8_T20ms_triaxial_sway`; control names add `known_branch_control`.

At 1 ms maximum loop/differential phases were 1.575476/0.00937650 rad (constant)
and 1.818196/0.49306589 rad (sway). Differential rotation scales approximately
400-fold; total phases also contain a fixed pi/2 point and a T^3 common term,
so their maxima do not simply scale by 400. Sway uses a rectangular 40 ms mean
instead of a midpoint, slightly changing the phase ratio. FOG averaging reduces
R by 0.21875/0.82. Control-curve changes therefore do not demonstrate an atomic
sensitivity improvement.

Failure occurs before the Zhang filter. No truth repairs the main inverse and
no Phase 5 acquisition machinery is added. The rectangular mean is a reduced
model, not a derived atomic sensitivity function. Readout and static gravity
compensation remain ideal.
