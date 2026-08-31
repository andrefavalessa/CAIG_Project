# CAIG MATLAB Simulation

## 1. Project objective

This project develops a MATLAB simulation of a Cold Atom Interference Gyroscope (CAIG) and its integration with a Fiber-Optic Gyroscope (FOG).

**Main paper:** Zhang et al. (2019), *A Novel Monitoring Navigation Method for Cold Atom Interference Gyroscope*.

**Supporting paper:** Wang et al. (2023), *Improving measurement performance via fusion of classical and quantum accelerometers*. Wang is complementary and does not replace the gyroscope equations from Zhang.

Development flow:

~~~~text
CAIG physics -> CAIG + FOG -> frame misalignment -> triaxial motion
-> Kalman estimation -> noise validation -> Monte Carlo -> duration study
-> synchronization study -> MATLAB timetable architecture
-> modular end-to-end simulation and software regression
~~~~

---

## 2. Project structure

~~~~text
CAIG_Project/
├── CAIG_Main_Simulation.m
├── README.md
├── config/
│   └── getSimulationConfig.m
├── motion/
│   └── generateLevel2Sway.m
├── sensors/
│   ├── simulateFOG.m
│   ├── simulateCAIG.m
│   └── simulateCAIGPhysicsY.m
├── synchronization/
│   └── synchronizeSensors.m
├── estimation/
│   └── runZhangKalman.m
├── validation/
│   └── validateMainSimulation.m
├── visualization/
│   ├── printSimulationSummary.m
│   └── plotSimulationResults.m
├── utils/
│   └── skewMatrix.m
├── 01_V1_CAIG_Physics/
│   ├── CAIG_V1_ideal.m
│   └── validation/
│       ├── CAIG_V1_validation_OmegaCrossG.m
│       ├── CAIG_V1_validation_phase_detection.m
│       └── CAIG_V1_validation_scale_factor_dynamic_range.m
├── 02_V2_Hybrid_CAIG_FOG/
│   ├── CAIG_V2_1_imuSensor_FOG.m
│   ├── CAIG_V2_2_misalignment.m
│   ├── CAIG_V2_3_triaxial_sway.m
│   ├── CAIG_V2_4a_Kalman_ideal.m
│   ├── CAIG_V2_4b_Kalman_noisy.m
│   └── CAIG_V2_4c_Kalman_timetable.m
├── 03_Analysis/
│   ├── CAIG_Kalman_trackingKF_validation.m
│   ├── CAIG_noise_model_sensitivity.m
│   ├── CAIG_V2_5_MonteCarlo.m
│   ├── CAIG_V2_5_MonteCarlo_timetable.m
│   ├── CAIG_V2_6_duration_study.m
│   ├── CAIG_V2_6_duration_study_timetable.m
│   ├── CAIG_V2_7_synchronization_test.m
│   ├── CAIG_V2_8_timetable_synchronization.m
│   ├── CAIG_V2_9_interpolation_noise_covariance.m
│   ├── FOG_AllanVariance_validation.m
│   └── Zhang_Figure6_ConstantSpeed_Behavior.m
├── 04_Figures/
│   ├── Analysis/
│   ├── V1/
│   │   ├── CAIG_V1_validation_phase_detection.pdf
│   │   ├── CAIG_V1_validation_scale_factor_dynamic_range.pdf
│   │   ├── grafv1.pdf
│   │   ├── grafv2.pdf
│   │   ├── grafv3.pdf
│   │   ├── testg1.pdf
│   │   └── testg2.pdf
│   └── V2/
│       ├── CAIG_V2_1_CAIG_FOG.pdf
│       ├── CAIG_V2_2_imuSensor_misalignment.pdf
│       ├── CAIG_V2_3_triaxial_sway.pdf
│       ├── CAIG_V2_4_Kalman.pdf
│       ├── CAIG_V2_4b_noisy_Kalman.pdf
│       └── CAIG_V2_4b_noisy_Kalman2.pdf
└── 05_References/
    └── parameter_sources.md
~~~~

The modular main simulation is the recommended entry point. The numbered V1/V2 folders preserve validated development stages, while `03_Analysis` contains independent scientific and software-validation evidence. Those analysis scripts are not called by the modular main.

### Modular workflow

~~~~matlab
cfg = getSimulationConfig();
truth = generateLevel2Sway(cfg);
caigPhysics = simulateCAIGPhysicsY(truth,cfg);
fog = simulateFOG(truth,cfg);
caig = simulateCAIG(truth,cfg);
sync = synchronizeSensors(fog,caig,truth,cfg);
results = runZhangKalman(truth,sync,cfg);
validation = validateMainSimulation(...);
printSimulationSummary(...);
plotSimulationResults(...);
~~~~

The random execution order is intentionally fixed:

~~~~text
rng default -> simulate FOG -> simulate CAIG
~~~~

Validation and plotting do not generate random numbers. The main script determines the project root from its own location and adds the project folders with `addpath(genpath(projectRoot))`, so it does not depend on the MATLAB current working directory.

### Module responsibilities

| Module | Responsibility |
|---|---|
| `config/getSimulationConfig.m` | Validated constants, parameter provenance, noise conventions, and regression references |
| `motion/generateLevel2Sway.m` | Zhang level-2 sway and the existing 3-2-1 body-rate equations |
| `sensors/simulateCAIGPhysicsY.m` | V1 Y-axis physical phase validation |
| `sensors/simulateFOG.m` | Zhang frame transformation and MATLAB `gyroparams`/`imuSensor` FOG generation |
| `sensors/simulateCAIG.m` | Three-axis CAIG rate-level abstraction and white noise |
| `synchronization/synchronizeSensors.m` | `timetable`, `retime`, Zhang observation, and manual-index regression check |
| `estimation/runZhangKalman.m` | Six-state Zhang model using MATLAB `trackingKF` |
| `validation/validateMainSimulation.m` | Phase, synchronization, noise-level, and Kalman regression checks |
| `visualization/printSimulationSummary.m` | Grouped terminal report and overall acceptance result |
| `visualization/plotSimulationResults.m` | Existing sensor, phase, misalignment, and bias plots |
| `utils/skewMatrix.m` | Shared skew-matrix convention used by the frame and measurement models |

The modular refactor reduced `CAIG_Main_Simulation.m` from 1,536 lines to 68 lines without changing the validated numerical output.

---

## 3. Version overview

| Version / analysis | Purpose | Result |
|---|---|---|
| Modular main | End-to-end CAIG + FOG workflow | Reproduces the monolithic baseline with all acceptance checks passing. |
| V1 | Ideal CAIG physics | Rotation, total and differential phases and transition probability validated. |
| V2.1 | CAIG + MATLAB conventional gyro | `imuSensor` reproduces the FOG constant bias. |
| V2.2 | CAIG/FOG frame misalignment | Zhang Eq. (16) numerically validated. |
| V2.3 | Triaxial sway | All misalignment states excited; stacked measurement-sensitivity rank = 6/6. |
| V2.4a | Ideal Kalman | Six injected states recovered with almost numerical precision. |
| V2.4b | Noisy Kalman | FOG ARW corrected to the validated single-sided MATLAB convention; noisy estimation characterized. |
| V2.4c | Kalman + timetable | `timetable + retime` replaces manual multirate indexing without changing the Kalman result. |
| V2.5 | Monte Carlo | Statistical estimator performance evaluated with corrected FOG noise. |
| V2.6 | Duration study | Longer observation reduces bias dispersion and RMSE under the current white-noise model. |
| V2.7 | Synchronization study | Millisecond timestamp mismatch can exceed the FOG bias being estimated. |
| V2.8 | MATLAB timetable synchronization | `retime` and `synchronize` validated for aligned and offset CAIG/FOG clocks. |
| Allan validation | FOG noise scaling | `single-sided` reproduces the input ARW scale in the MATLAB Allan-variance workflow. |
| CAIG noise sensitivity | CAIG scaling robustness | Alternative white-noise scaling changes estimator RMSE only modestly because FOG noise dominates the current observation covariance. |

---

## 4. V1 — Ideal CAIG physics

~~~~text
Phi_rot = -2 k_eff · (Omega × v) T^2
~~~~

~~~~text
DeltaPhi_total = k_eff · g T^2 + Phi_rot
                 - 2 k_eff · (Omega × g) T^3 + DeltaPhi0
~~~~

For V1, `DeltaPhi0 = 0`. The dual-interferometer differential phase is

~~~~text
Phi_diff = Phi_tot1 - Phi_tot2
~~~~

The scale factors are

~~~~text
Ksingle = 2 k_eff v T^2
Kdual   = 4 k_eff v T^2
~~~~

Validated values are

~~~~text
Ksingle = 5.482884e4 s
Kdual   = 1.096577e5 s
~~~~

The ideal transition probability used from Zhang is

~~~~text
P = 1/2 (1 - cos(DeltaPhi))
~~~~

Therefore,

~~~~text
P(+Phi) = P(-Phi)
P(Phi)  = P(Phi + 2*pi*n)
~~~~

Fringe contrast is not introduced because it is not part of the Zhang Eq. (10) model currently being reproduced.

### V1 coordinate convention

The baseline V1 geometry uses

~~~~text
v1 = [ v, 0, 0]
v2 = [-v, 0, 0]

k_eff vector = [0, 0, k_eff]

gravity vector:
g = [0, 0, -g0]

initial synthetic rotation: around Y axis
~~~~

With this nominal geometry,

~~~~text
k_eff · (Omega x g) = 0
~~~~

and the rotation-gravity coupling term is zero in the nominal V1 configuration. The term remains implemented because it is part of the general model and was validated separately using a temporary gravity-tilt test.

### V1 simulation-only inputs

~~~~text
Simulation duration        = 20 s
Angular velocity amplitude = 1e-5 rad/s
Angular velocity frequency = 0.1 Hz

Omega_y(t) = 1e-5 sin(2*pi*0.1*t)
~~~~

These are synthetic simulation inputs, not CAIG hardware specifications.

---

## 5. V1 parameter traceability

| Parameter | Value | Source/classification |
|---|---:|---|
| Atomic species | 87Rb | Zhang |
| D2 transition | Rubidium D2 | Zhang |
| `Fs_CAIG` | 5 Hz | Zhang |
| `T` | 24.7 ms | Tackmann et al. (2012) |
| `v` | 2.79 m/s | Tackmann et al. (2012) |
| `lambda` | 780.241209686 nm | Steck |
| `k_eff` | approximately `4*pi/lambda` | Derived |
| `g0` | 9.80665 m/s^2 | Conventional standard gravity |

Tackmann is used only to fill numerical parameters not provided by Zhang; it does not replace the main Zhang model.

---

## 6. V1 validation

| Test | Result |
|---|---:|
| Rotation-vector/analytical error | approximately `1e-16 rad` |
| Temporary 10-degree gravity tilt: maximum `Omega x g` phase | approximately `8.25e-3 rad` |
| Analytical `Omega x g` error | approximately `8.7e-19 rad` |
| Differential/common-mode floating-point residual | approximately `1.4e-11 rad` |
| `+pi/3`, `-pi/3`, and `pi/3 + 2*pi` | `P = 0.25` |
| `Omega_pi_dual` | approximately `2.864909e-5 rad/s` |
| `Omega_2pi_dual` | approximately `5.729817e-5 rad/s` |

---

## 7. V2 — Hybrid CAIG + FOG

From V2 onward, the internal CAIG physics is treated as validated and the project studies the CAIG + FOG monitoring system.

The conventional FOG uses MATLAB `gyroparams` and `imuSensor`. The CAIG-specific physics remains custom because MATLAB does not provide a ready-made cold-atom gyroscope sensor object corresponding to the Zhang architecture.

The current multirate data architecture uses MATLAB `timetable` objects and `retime` at the CAIG update epochs.

---

## 8. V2.1 — `imuSensor` FOG

Zhang parameters are

~~~~text
CAIG rate = 5 Hz
FOG rate  = 100 Hz
FOG bias  = 0.1 deg/h
CAIG bias = negligible
~~~~

Conversion:

~~~~text
0.1 deg/h = 4.848137e-7 rad/s
~~~~

`paramsFOG.ConstantBias` is used inside `gyroparams`. The initial deterministic simulation validates

~~~~text
FOG - CAIG = FOG bias
~~~~

with practically zero numerical error.

---

## 9. V2.2 — Frame misalignment

This is frame-to-frame misalignment between the CAIG A-frame and FOG F-frame. It is not `gyroparams.AxesMisalignment`.

~~~~text
C_A^F = I - [phi_a x]

phi = [1, 2, 3] deg

DeltaOmega = [Omega_A x] phi + epsilon_F
~~~~

Maximum contributions in the single-axis validation are

~~~~text
X = 0.107787 deg/h
Y = 0
Z = 0.035929 deg/h
~~~~

Eq. (16) numerical errors are essentially zero.

Motion only along Y does not excite `phi_y`, motivating the triaxial-motion study.

---

## 10. V2.3 — Triaxial sway

Zhang level-2 sway values:

| Component | Amplitude | Period |
|---|---:|---:|
| Roll | 0.50 deg | 20 s |
| Pitch | 0.20 deg | 30 s |
| Heading | 0.30 deg | 30 s |

Zhang provides amplitude and period, but not the exact time-domain waveform. Sinusoidal roll, pitch, and heading are therefore a project simulation choice.

Euler-angle rates are converted to body angular rate using the 3-2-1 relationship.

Maximum body rates:

~~~~text
X = 0.157175 deg/s
Y = 0.042435 deg/s
Z = 0.063195 deg/s
~~~~

Eq. (16) numerical errors are approximately `1e-19 rad/s`.

Measurement-sensitivity checks:

~~~~text
rank(stacked [omega x]) = 3/3
rank(stacked H)         = 6/6
~~~~

This is a stacked measurement-sensitivity rank check. It is **not** presented as a complete formal observability proof.

---

## 11. V2.4a — Ideal Kalman filter

State vector:

~~~~text
X = [phi_x phi_y phi_z eps_Fx eps_Fy eps_Fz]^T
~~~~

Baseline state model:

~~~~text
X0  = zeros(6,1)
Phi = I
Q   = 0
~~~~

`P0` is based on

~~~~text
misalignment std = [1, 2, 3] deg
FOG-bias std     = [0.1, 0.1, 0.1] deg/h
~~~~

Zhang defines the measurement covariance `R` but does not provide a numerical value.

V2.4a contains no random measurement noise. Its very small `R` is only a numerical choice for structural validation.

Results:

~~~~text
Estimated misalignment = [1.000000, 2.000000, 3.000000] deg
Estimated FOG bias     = [0.100000, 0.100000, 0.100000] deg/h
~~~~

Errors are approximately numerical precision.

V2.4a is therefore a **noise-free structural Kalman validation**.

---

## 12. FOG Allan-variance noise validation

The EMCORE EG-1300 ARW specification used in the project is

~~~~text
ARW = 0.002 deg/sqrt(h)
~~~~

Conversion:

~~~~text
N_FOG = deg2rad(0.002) / sqrt(3600)
      = 5.817764e-7 rad/s/sqrt(Hz)
~~~~

A dedicated stationary simulation at

~~~~text
Fs = 100 Hz
duration = 3600 s
samples = 360000
~~~~

compared `gyroparams` with

~~~~text
NoiseType = 'double-sided'
NoiseType = 'single-sided'
~~~~

Sample-domain results:

| Model | Theoretical sigma (rad/s) | Empirical sigma (rad/s) |
|---|---:|---:|
| Double-sided | `4.113780e-6` | `4.128459e-6` |
| Single-sided | `5.817764e-6` | `5.838522e-6` |

The empirical single/double ratio was

~~~~text
1.414214
~~~~

which is effectively `sqrt(2)`.

Allan-variance recovery:

| Model | Recovered ARW (deg/sqrt(h)) | Recovered/input |
|---|---:|---:|
| Double-sided | `0.001384` | `0.692077` |
| Single-sided | `0.001957` | `0.978745` |

Therefore, for the current MATLAB Allan-variance parameter-scaling workflow, the FOG baseline uses

~~~~matlab
'NoiseType','single-sided'
~~~~

and

~~~~text
sigma_FOG = N_FOG * sqrt(Fs_FOG)
          = 5.817764e-6 rad/s
~~~~

at `Fs_FOG = 100 Hz`.

This validation establishes consistency with the MATLAB parameter scaling used in the project. It does not by itself reconstruct the exact proprietary EMCORE procedure used to obtain the datasheet ARW.

---

## 13. V2.4b — Noisy Kalman

### FOG model

Source: EMCORE EG-1300.

~~~~text
ARW          = 0.002 deg/sqrt(h)
NoiseDensity = 5.817764e-7 rad/s/sqrt(Hz)
Fs_FOG       = 100 Hz
NoiseType    = single-sided

sigma_FOG = 5.817764e-6 rad/s
~~~~

### CAIG model

Source: Tackmann et al. (2012), reported rotation sensitivity

~~~~text
N_CAIG = 6.1e-7 rad/s/sqrt(Hz)
~~~~

Treating this reported sensitivity as an equivalent short-term white angular-rate output-noise level is a project modeling assumption.

The current baseline mapping remains

~~~~text
sigma_CAIG = N_CAIG * sqrt(Fs_CAIG/2)
           = 9.644947e-7 rad/s
~~~~

for `Fs_CAIG = 5 Hz`.

The CAIG white-noise mapping is kept explicit because Tackmann reports experimental sensitivity rather than a MATLAB `gyroparams` noise-density convention.

### Observation covariance

Assuming independent FOG and CAIG white noise,

~~~~text
sigma_Z = sqrt(sigma_FOG^2 + sigma_CAIG^2)
        = 5.897171e-6 rad/s

R diagonal = 3.477663e-11 (rad/s)^2
~~~~

`Q = 0` remains the baseline because the injected bias and misalignment are constant in the simulation.

Representative corrected single-run result:

~~~~text
Misalignment = [1.000694, 2.005255, 3.008474] deg
FOG bias     = [0.067151, 0.055620, 0.128074] deg/h
~~~~

The single run is not used alone to judge estimator quality; Monte Carlo is used for statistical characterization.

---

## 14. CAIG noise-model sensitivity analysis

Because the Tackmann sensitivity is not explicitly a MATLAB PSD parameter, two CAIG white-noise mappings were compared:

~~~~text
Model A:
sigma_CAIG = N_CAIG * sqrt(Fs_CAIG/2)

Model B:
sigma_CAIG = N_CAIG * sqrt(Fs_CAIG)
~~~~

For `Fs_CAIG = 5 Hz`:

~~~~text
Model A sigma_CAIG = 9.644947e-7 rad/s
Model B sigma_CAIG = 1.364001e-6 rad/s
ratio = sqrt(2)
~~~~

With the FOG model held fixed during that sensitivity study, the resulting change in total observation standard deviation was only a few percent, and estimator RMSE changes were also only a few percent.

This result means that the estimator conclusions are not strongly sensitive to this specific CAIG scaling ambiguity under the current noise hierarchy.

It does **not** prove which CAIG spectral convention is physically correct.

---

## 15. V2.5 — Monte Carlo

`N = 100` runs, `duration = 120 s`, with the corrected single-sided FOG model.

### Misalignment

| Axis | True (deg) | Mean (deg) | Std (deg) | RMSE (deg) |
|---|---:|---:|---:|---:|
| X | 1 | 1.001553 | 0.015163 | 0.015166 |
| Y | 2 | 1.999021 | 0.007131 | 0.007162 |
| Z | 3 | 2.999485 | 0.006870 | 0.006855 |

95% confidence intervals for the mean:

~~~~text
X: [0.998581, 1.004525] deg
Y: [1.997623, 2.000419] deg
Z: [2.998138, 3.000831] deg
~~~~

### FOG bias

| Axis | True (deg/h) | Mean (deg/h) | Std (deg/h) | RMSE (deg/h) |
|---|---:|---:|---:|---:|
| X | 0.1 | 0.083585 | 0.042973 | 0.045801 |
| Y | 0.1 | 0.082062 | 0.040110 | 0.043755 |
| Z | 0.1 | 0.082323 | 0.036647 | 0.040523 |

95% confidence intervals for the mean:

~~~~text
X: [0.075162, 0.092008] deg/h
Y: [0.074201, 0.089924] deg/h
Z: [0.075140, 0.089506] deg/h
~~~~

At 120 s, the misalignment estimates remain close to the injected values, whereas estimation of the much smaller `0.1 deg/h` FOG bias is more difficult.

---

## 16. V2.6 — Duration study

`N = 100` Monte Carlo runs for `120 s`, `300 s`, and `600 s`.

### FOG-bias mean

| Duration | Mean X | Mean Y | Mean Z |
|---|---:|---:|---:|
| 120 s | 0.083585 | 0.082062 | 0.082323 |
| 300 s | 0.095987 | 0.091155 | 0.090641 |
| 600 s | 0.097674 | 0.097263 | 0.094562 |

Units: `deg/h`.

### FOG-bias standard deviation

| Duration | Std X | Std Y | Std Z |
|---|---:|---:|---:|
| 120 s | 0.042973 | 0.040110 | 0.036647 |
| 300 s | 0.028403 | 0.027587 | 0.028896 |
| 600 s | 0.022519 | 0.020330 | 0.019305 |

Units: `deg/h`.

### FOG-bias RMSE

| Duration | RMSE X | RMSE Y | RMSE Z |
|---|---:|---:|---:|
| 120 s | 0.045801 | 0.043755 | 0.040523 |
| 300 s | 0.028545 | 0.028838 | 0.030236 |
| 600 s | 0.022526 | 0.020412 | 0.019963 |

Units: `deg/h`.

### 95% confidence interval of the mean

At 120 s:

~~~~text
X: [0.075162, 0.092008]
Y: [0.074201, 0.089924]
Z: [0.075140, 0.089506]
~~~~

At 300 s:

~~~~text
X: [0.090420, 0.101554]
Y: [0.085748, 0.096562]
Z: [0.084978, 0.096305]
~~~~

At 600 s:

~~~~text
X: [0.093261, 0.102088]
Y: [0.093278, 0.101247]
Z: [0.090778, 0.098346]
~~~~

The 95% confidence interval for the mean is

~~~~text
mean +/- 1.96 * std / sqrt(N)
~~~~

Increasing duration reduces the bias standard deviation and RMSE and generally moves the estimated mean toward the true `0.1 deg/h` value.

The 600-s X and Y confidence intervals contain the true value; Z remains slightly below it in this Monte Carlo set.

This behavior is established **within the current independent white-noise, constant-bias model**. It should not be extrapolated indefinitely to real hardware because long-term drift, bias instability, dead time, clock effects, and correlated noise can change the scaling with observation time.

---

## 17. V2.7 — Synchronization study

Zhang states that CAIG and FOG outputs must be synchronized by data processing and warns that differing data rates/time labels can cause significant errors.

Zhang does not specify averaging, interpolation, nearest-sample selection, or another numerical synchronization method.

Wang's supporting architecture performs the low-rate quantum correction at quantum-sensor measurement epochs.

Timestamp interpolation is therefore a project implementation choice, not a claim about Zhang's exact experimental processing.

FOG and CAIG rates:

~~~~text
FOG  = 100 Hz
CAIG = 5 Hz
~~~~

Artificial delays:

~~~~text
0, 2, 5, 10, 20, 50 ms
~~~~

These delays are simulation choices for robustness testing.

### Naive index-based mismatch

| Delay | X (deg/h) | Y (deg/h) | Z (deg/h) |
|---:|---:|---:|---:|
| 0 ms | approximately zero | approximately zero | approximately zero |
| 2 ms | 0.355636 | 0.063771 | 0.095139 |
| 5 ms | 0.889091 | 0.159427 | 0.237847 |
| 10 ms | 1.778180 | 0.318855 | 0.475696 |
| 20 ms | 3.556342 | 0.637711 | 0.951400 |
| 50 ms | 8.890546 | 1.594278 | 2.378532 |

For small `Delta t`,

~~~~text
e_sync ≈ -omega_dot * Delta t
~~~~

Millisecond mismatch can therefore exceed the target `0.1 deg/h` FOG bias.

The V2.7 timestamp-interpolation test gave, for example, an X maximum residual of approximately

~~~~text
2 ms -> 4.47e-4 deg/h
5 ms -> 6.98e-4 deg/h
~~~~

while 10, 20, and 50 ms fall directly on the 100-Hz FOG grid in this synthetic setup and therefore have interpolation errors close to numerical precision.

Timestamp-aware synchronization reduces deterministic timing mismatch in this idealized test. It does not remove actual sensor noise, timestamp uncertainty, clock jitter, or latency uncertainty.

---

## 18. V2.8 — MATLAB `timetable` synchronization

V2.8 replaces the earlier manual `interp1` synchronization experiment with MATLAB-native time handling using

~~~~matlab
timetable
retime
synchronize
~~~~

The purpose is to represent FOG and CAIG as independent timestamped streams.

### Case A — perfectly aligned clocks

~~~~text
FOG rows  = 12000
CAIG rows = 600
~~~~

Maximum `retime` error:

~~~~text
X = 1.214e-17 rad/s
Y = 1.030e-18 rad/s
Z = 1.518e-18 rad/s
~~~~

`retime` and `synchronize` produced identical results.

Manual `1:20:end` also produced only floating-point-level error because the synthetic clocks were exactly aligned.

### Case B — 5-ms CAIG clock offset

The 5-ms offset is an artificial simulation choice. It is not a claimed Zhang-system delay.

Correct `retime` interpolation error:

~~~~text
X = 3.385895e-9 rad/s = 6.983910e-4 deg/h
Y = 4.178293e-10 rad/s = 8.618348e-5 deg/h
Z = 6.125404e-10 rad/s = 1.263455e-4 deg/h
~~~~

Naive `1:20:end` error:

~~~~text
X = 4.310434e-6 rad/s = 0.889091 deg/h
Y = 7.729239e-7 rad/s = 0.159427 deg/h
Z = 1.153115e-6 rad/s = 0.237847 deg/h
~~~~

Error-reduction factors from timestamp-aware synchronization:

~~~~text
X ≈ 1.273e3
Y ≈ 1.850e3
Z ≈ 1.883e3
~~~~

The practical conclusion is that sample-number indexing is acceptable only when clock alignment is guaranteed. Timestamp-aware processing is more general and better suited to real multirate data.

---

## 19. V2.4c — Kalman + timetable integration

V2.4c integrates the MATLAB-native synchronization layer into the full noisy Kalman baseline.

The scientific model is unchanged relative to the corrected V2.4b:

~~~~text
same ground truth
same FOG model
same CAIG model
same noise levels
same R
same P0
same Q
same H
same Kalman equations
same random seed
~~~~

The only architectural change is

~~~~text
OLD:
OmegaFOG(1:20:end,:)

NEW:
TT_FOG_at_CAIG = retime(
    TT_FOG,
    TT_CAIG.Properties.RowTimes,
    'linear')
~~~~

For the aligned baseline clocks:

~~~~text
Maximum timetable vs manual difference:
X = 3.572446e-17 rad/s
Y = 2.645453e-17 rad/s
Z = 2.081668e-17 rad/s

Maximum timestamp difference:
0 s
~~~~

The final Kalman results are identical to the corrected V2.4b:

~~~~text
Misalignment = [1.000694, 2.005255, 3.008474] deg
FOG bias     = [0.067151, 0.055620, 0.128074] deg/h
~~~~

Therefore, the project can replace manual multirate indexing with `timetable + retime` without changing the validated estimator behavior when timestamps are aligned.

### Current synchronization architecture

~~~~text
FOG 100 Hz
  -> imuSensor / gyroparams
  -> timetable
          \
           -> retime FOG to CAIG epochs
          /
CAIG 5 Hz
  -> custom CAIG model
  -> timetable

retimed FOG - CAIG
  -> DeltaOmega
  -> custom six-state Zhang Kalman filter
~~~~

For the current aligned baseline, `retime` selects existing FOG samples, so the observation covariance remains

~~~~text
R = (sigma_FOG^2 + sigma_CAIG^2) I
~~~~

For genuinely offset timestamps, interpolation changes the noise statistics and may introduce temporal correlation. That case requires a separate covariance study before assuming the same `R`.

---

## 20. Relationship to Wang et al. (2023)

Zhang studies

~~~~text
CAIG + FOG
~~~~

while Wang studies

~~~~text
quantum accelerometer + classical accelerometer
~~~~

Wang's reported data rates are

~~~~text
classical accelerometer = 200 Hz
quantum accelerometer   = 1 Hz
~~~~

The Kalman bias correction is updated at the quantum-sensor rate while the classical sensor continues to provide high-rate output.

This supports the general architecture

~~~~text
high-rate conventional sensor + low-rate quantum correction
~~~~

but Wang does not replace the Zhang gyroscope model.

---

## 21. Modular MATLAB architecture

The main simulation uses small functions grouped by responsibility. MATLAB's built-in sensor, time-management, and filtering tools are retained where they match the validated model:

~~~~text
FOG sensor model:
gyroparams + imuSensor

multirate time management:
timetable + retime
synchronize for combined analysis

noise validation:
allanvar / Allan-variance workflow

main six-state estimator:
trackingKF with a time-varying measurement model
~~~~

The following parts remain custom because they are specific to the research problem:

~~~~text
CAIG phase physics
dual-interferometer equations
CAIG measurement interpretation
Zhang six-state monitoring model
project-specific validation and acceptance criteria
~~~~

The main estimator keeps the Zhang state and measurement equations but executes them through `trackingKF`. The dedicated manual-Kalman validation script remains unchanged in `03_Analysis` as independent evidence.

`insfilterAsync` is relevant as a MATLAB architectural example of asynchronous fusion, but it is not used as a drop-in replacement because its state definition and sensor model differ from the Zhang monitoring model.

The modular boundary does not introduce a scientific boundary: moving an expression into a function does not change its source, physical meaning, units, or validation status. Configuration comments retain the distinction among Zhang values, external experimental values, derived quantities, and project assumptions.

---

## 22. Parameter sources

| Source | Parameters / role |
|---|---|
| Zhang | CAIG 5 Hz; FOG 100 Hz; FOG bias 0.1 deg/h; misalignment 1, 2, 3 deg; level-2 sway 0.50 deg/20 s, 0.20 deg/30 s, 0.30 deg/30 s; six-state monitoring architecture |
| Tackmann | `T = 24.7 ms`; `v = 2.79 m/s`; reported rotation sensitivity `6.1e-7 rad/s/sqrt(Hz)` |
| Steck | `lambda = 780.241209686 nm` |
| EMCORE EG-1300 | `ARW = 0.002 deg/sqrt(h)` |
| Standard gravity | `9.80665 m/s^2` |
| MathWorks | `gyroparams`, `imuSensor`, Allan-variance workflow, `timetable`, `retime`, `synchronize` |

Detailed notes are kept in `05_References/parameter_sources.md`.

---

## 23. Modeling assumptions and limitations

- V1 sinusoidal synthetic rotation.
- Zhang remains the main system architecture.
- Parameters absent from Zhang are taken from comparable scientific experiments only when needed and are documented separately.
- Triaxial sway uses sinusoidal roll, pitch, and heading because Zhang supplies amplitudes and periods but not an exact waveform.
- Tackmann sensitivity is interpreted as an equivalent short-term white CAIG angular-rate noise level.
- The current CAIG sample-noise mapping uses `N_CAIG * sqrt(Fs_CAIG/2)` and remains an explicit modeling assumption.
- FOG ARW uses the MATLAB `single-sided` convention validated with Allan variance.
- Three equivalent independent FOG axes are simulated.
- Same independent CAIG white-noise level is used on all three axes.
- FOG and CAIG white noise are independent.
- `Q = 0` because true simulated bias and misalignment are constant.
- The current baseline clocks are exactly aligned.
- `retime(...,'linear')` is the MATLAB-native synchronization choice.
- Artificial timing offsets in V2.7/V2.8 are simulation choices and are not measured Zhang-system delays.
- For truly interpolated noisy FOG samples, the effective measurement covariance may differ from the current `R` and may include temporal correlation.
- The current duration study assumes independent white noise and constant bias; real long-term behavior may include drift, bias instability, dead time, clock effects, and correlated noise.
- The current `H` uses the true simulation angular rate to isolate the Zhang observation model from errors-in-variables effects. Using measured/noisy angular rate in `H` is a separate future problem.
- Stacked rank calculations are measurement-sensitivity checks, not a full formal observability proof.

---

## 24. Current scientific conclusions

1. Zhang's CAIG phase model has been numerically validated in the ideal baseline.
2. The dual interferometer doubles the rotation scale factor and rejects common terms in the implemented geometry.
3. The ideal transition probability has sign and `2*pi` ambiguities.
4. MATLAB `imuSensor`/`gyroparams` can model the conventional FOG layer.
5. The frame-misalignment observation follows Zhang Eq. (16) in the numerical tests.
6. Single-axis motion does not excite all misalignment parameters.
7. Triaxial sway provides measurement sensitivity to all six monitoring states in the stacked test.
8. The ideal Kalman filter recovers the six injected constant states.
9. The corrected FOG ARW mapping is `single-sided` for the MATLAB Allan-variance parameter scaling used in this project.
10. With corrected FOG noise, misalignment remains easier to estimate than the small `0.1 deg/h` FOG bias.
11. Monte Carlo analysis is necessary to characterize the noisy estimator.
12. Increasing observation duration reduces bias dispersion and RMSE under the current white-noise model.
13. Millisecond-level timing mismatch can exceed the target FOG bias.
14. Timestamp-aware synchronization strongly reduces deterministic timing error.
15. MATLAB `timetable + retime` reproduces manual indexing to numerical precision when the clocks are aligned.
16. V2.4c preserves the V2.4b Kalman result while replacing fragile sample-number synchronization with timestamp-based processing.
17. Real offset/noisy interpolation requires a separate covariance analysis before reusing the aligned-case `R` unchanged.

---

## 25. Current project status

### Completed

- MATLAB IMU examples.
- V1 CAIG ideal physics.
- Rotation-phase validation.
- `Omega x g` validation.
- Transition-probability ambiguity validation.
- Dynamic-range/scale-factor validation.
- MATLAB `imuSensor` FOG.
- CAIG/FOG frame misalignment.
- Zhang level-2 triaxial sway model.
- Six-state stacked measurement-sensitivity check.
- Ideal six-state Kalman filter.
- Noisy Kalman filter.
- EMCORE FOG ARW conversion.
- FOG Allan-variance scaling validation.
- Corrected `single-sided` FOG noise integration.
- CAIG white-noise scaling sensitivity analysis.
- Monte Carlo study with corrected FOG noise.
- Duration study with corrected FOG noise.
- Timing-offset sensitivity study.
- MATLAB `timetable`, `retime`, and `synchronize` validation.
- Full noisy Kalman integration with `timetable + retime`.
- Timetable-based Monte Carlo and duration-study variants.
- Modular end-to-end main simulation.
- Software regression against the original monolithic main.

### Current baseline

The recommended end-to-end entry point is

~~~~text
CAIG_Main_Simulation.m
~~~~

It uses the validated FOG noise convention, MATLAB-native timestamp handling, the Zhang six-state `trackingKF` implementation, grouped validation, and the existing plots. The original monolithic behavior was recorded before refactoring and reproduced after modularization.

Current regression result:

~~~~text
CAIG phase -> rate consistency : PASS
timetable synchronization     : PASS
FOG synthetic noise level     : PASS
CAIG synthetic noise level    : PASS
Kalman regression             : PASS

OVERALL RESULT: PASS
~~~~

The final modular-main estimates remain

~~~~text
Misalignment = [1.000694, 2.005255, 3.008474] deg
FOG bias     = [0.067151, 0.055620, 0.128074] deg/h
~~~~

### Next implementation task

Use the modular main as the frozen end-to-end software baseline for the next explicitly selected scientific question. New effects should be introduced in dedicated analysis scripts before integration into the main workflow.

Candidate next research steps include:

~~~~text
1. extend the observation-covariance study for genuinely interpolated noisy FOG data
2. introduce more realistic long-term FOG noise from Allan parameters
3. study measured/noisy omega inside H
4. study asynchronous/dropout behavior
5. compare the Zhang-specific architecture with MATLAB asynchronous-fusion design patterns
~~~~

These should be added one at a time and validated independently.

---

## 26. Running scripts

### Recommended modular simulation

From the `CAIG_Project` root:

~~~~matlab
CAIG_Main_Simulation
~~~~

The main script locates its own directory and adds all project subdirectories to the MATLAB path. It can also be launched from another working directory with:

~~~~matlab
projectRoot = 'path/to/CAIG_Project';
run(fullfile(projectRoot,'CAIG_Main_Simulation.m'))
~~~~

The main workflow requires Sensor Fusion and Tracking Toolbox because it uses `trackingKF`. It stops with an explicit error if `trackingKF` is unavailable. The generated `SimulationOutput` struct contains synchronized sensor timetables, estimate histories, CAIG phase/probability outputs, the final estimates, `R`, and the acceptance result.

### Validated development and analysis scripts

**Run each block independently from the `CAIG_Project` root.** Do not run all `cd` blocks sequentially in one MATLAB session without returning to the project root.

### V1

~~~~matlab
cd('01_V1_CAIG_Physics')
CAIG_V1_ideal
~~~~

From the project root, for V1 validation:

~~~~matlab
cd('01_V1_CAIG_Physics/validation')
CAIG_V1_validation_OmegaCrossG
CAIG_V1_validation_phase_detection
CAIG_V1_validation_scale_factor_dynamic_range
~~~~

### Hybrid model

~~~~matlab
cd('02_V2_Hybrid_CAIG_FOG')
CAIG_V2_1_imuSensor_FOG
CAIG_V2_2_misalignment
CAIG_V2_3_triaxial_sway
~~~~

### Kalman

~~~~matlab
cd('02_V2_Hybrid_CAIG_FOG')
CAIG_V2_4a_Kalman_ideal
CAIG_V2_4b_Kalman_noisy
CAIG_V2_4c_Kalman_timetable
~~~~

### Analysis

~~~~matlab
cd('03_Analysis')
FOG_AllanVariance_validation
CAIG_noise_model_sensitivity
CAIG_V2_5_MonteCarlo
CAIG_V2_5_MonteCarlo_timetable
CAIG_V2_6_duration_study
CAIG_V2_6_duration_study_timetable
CAIG_V2_7_synchronization_test
CAIG_V2_8_timetable_synchronization
CAIG_V2_9_interpolation_noise_covariance
CAIG_Kalman_trackingKF_validation
Zhang_Figure6_ConstantSpeed_Behavior
~~~~

---

## 27. References

- Zhang, L., Gao, W., Li, Q., Li, R., Yao, Z., & Lu, S. (2019). *A Novel Monitoring Navigation Method for Cold Atom Interference Gyroscope*. Sensors, 19, 222.
- Wang, X., Kealy, A., Gilliam, C., Haine, S., Close, J., Moran, B., et al. (2023). *Improving measurement performance via fusion of classical and quantum accelerometers*. The Journal of Navigation, 76(1), 91–102.
- Tackmann, G., et al. (2012). *Self-alignment of a compact large-area atomic Sagnac interferometer*. New Journal of Physics.
- Steck, D. A. *Rubidium 87 D Line Data*.
- EMCORE. *EG-1300 Fiber Optic Gyroscope documentation/specifications*.
- MathWorks documentation used for `gyroparams`, `imuSensor`, Allan variance, `timetable`, `retime`, and `synchronize`.

---

## 28. Version policy

- V1 remains frozen as the ideal physical baseline.
- Do not overwrite validated versions when making architectural or physical changes.
- Keep analysis scripts separated from physical-model scripts.
- Use Zhang as the main system model.
- Before adding a physical parameter:
  1. identify its physical meaning;
  2. check whether Zhang specifies it;
  3. if Zhang does not specify it, use a comparable scientific source;
  4. document the source and why it is applicable;
  5. validate the parameter/model independently before integrating it.
- Distinguish clearly among:
  - Zhang-defined parameters;
  - external experimentally sourced parameters;
  - MATLAB implementation choices;
  - synthetic simulation inputs;
  - modeling assumptions.
- A change in implementation infrastructure should first reproduce the previous validated result before being used for new scientific conclusions.
