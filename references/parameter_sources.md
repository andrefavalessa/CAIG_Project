# Parameter Sources

This document classifies every parameter used by the active modular baseline. It distinguishes values stated by Zhang, external experimental values, derived quantities, and project modeling assumptions.

## Parameter traceability

| Parameter | Value | Source | Classification | Used in |
|---|---:|---|---|---|
| CAIG sample rate, `Fs_CAIG` | 5 Hz | Zhang et al. (2019) | From Zhang | Configuration, CAIG simulation, synchronization, Kalman updates |
| FOG sample rate, `Fs_FOG` | 100 Hz | Zhang et al. (2019) | From Zhang | Configuration, FOG simulation, synchronization |
| FOG bias | 0.1 deg/h | Zhang et al. (2019) | From Zhang | FOG simulation and six-state monitoring model |
| CAIG/FOG frame misalignment | `[1; 2; 3]` deg | Zhang et al. (2019) | From Zhang | A-frame/F-frame transformation and regression baseline |
| Level-2 roll sway | 0.50 deg amplitude, 20 s period | Zhang et al. (2019) | From Zhang | Triaxial truth motion |
| Level-2 pitch sway | 0.20 deg amplitude, 30 s period | Zhang et al. (2019) | From Zhang | Triaxial truth motion |
| Level-2 heading sway | 0.30 deg amplitude, 30 s period | Zhang et al. (2019) | From Zhang | Triaxial truth motion |
| CAIG bias | Treated as negligible | Zhang et al. (2019) | From Zhang | System-level CAIG rate abstraction |
| Monitoring state | `[phi_x phi_y phi_z eps_Fx eps_Fy eps_Fz]^T` | Zhang et al. (2019) | From Zhang | Six-state `trackingKF` implementation |
| Pulse separation time, `T` | 24.7 ms | Tackmann et al. (2012) | External experimental value | V1 CAIG phase and scale factors |
| Atomic velocity, `vAtom` | 2.79 m/s | Tackmann et al. (2012) | External experimental value | V1 CAIG phase and scale factors |
| Reported rotation sensitivity, `N_CAIG` | 6.1e-7 rad/s/sqrt(Hz) | Tackmann et al. (2012) | External experimental value | Input to the project CAIG noise mapping |
| Rb-87 D2 wavelength, `lambda` | 780.241209686 nm | Steck | External reference value | Effective wave vector |
| FOG angle random walk | 0.002 deg/sqrt(h) | EMCORE EG-1300 | External hardware value | FOG white-noise model |
| Standard gravity, `g0` | 9.80665 m/s^2 | Conventional standard gravity | External conventional value | V1 CAIG gravity phase |
| Effective wave vector, `keff` | `4*pi/lambda` = approximately 1.610575e7 1/m | Derived from `lambda` | Derived value | V1 CAIG phase and scale factors |
| FOG noise density, `N_FOG` | 5.817764e-7 rad/s/sqrt(Hz) | Converted from EMCORE ARW | Derived value | MATLAB `gyroparams.NoiseDensity` |
| FOG sample sigma, `sigmaFOG` | 5.817764e-6 rad/s | `N_FOG*sqrt(Fs_FOG)` | Derived using the validated single-sided convention | Observation covariance and noise validation |
| Single-interferometer scale factor, `Ksingle` | 5.482884e4 s | `2*keff*vAtom*T^2` | Derived value | CAIG physics validation |
| Dual-interferometer scale factor, `Kdual` | 1.096577e5 s | `4*keff*vAtom*T^2` | Derived value | Phase-to-rate consistency check |
| Measurement sigma, `sigmaZ` | 5.897171e-6 rad/s | `sqrt(sigmaFOG^2 + sigmaCAIG^2)` | Derived for independent sensor noise | Aligned-baseline measurement covariance |
| Measurement covariance diagonal | 3.477663e-11 (rad/s)^2 | `sigmaZ^2` | Derived value | Aligned-baseline `R` |

## Project modeling assumptions

| Assumption | Current implementation | Scope |
|---|---|---|
| Zhang level-2 sway time history | Sinusoidal roll, pitch, and heading | Zhang supplies amplitudes and periods but not the exact waveform |
| FOG MATLAB spectral convention | `NoiseType = 'single-sided'` | Supported by the project's independent Allan-variance validation |
| CAIG discrete sample noise | `sigmaCAIG = N_CAIG*sqrt(Fs_CAIG/2)` = 9.644947e-7 rad/s | Project conversion; **not specified by Tackmann** |
| System-level CAIG axes | Identical independent CAIG white-noise level on all three axes | Rate-level abstraction; not a physical triaxial atom-interferometer geometry |
| Sensor-noise relationship | Independent FOG and CAIG white noise | Used to derive `sigmaZ` and `R` |
| Process covariance | `Q = 0` | Frozen simulation has constant true bias and misalignment states |
| Clock relationship | FOG and CAIG clocks exactly aligned in the main baseline | `retime` selects existing FOG epochs; offset-clock studies remain separate |
| Kalman measurement matrix | True simulated angular rate is used inside `H` | Isolates the Zhang observation model from errors-in-variables effects |

## Interpretation boundaries

- The Zhang CAIG physical validation is currently a Y-sensitive dual-interferometer geometry.
- The three-axis CAIG data supplied to the monitoring filter is a separate system-level rate abstraction.
- Transition probability is not inverted to generate the main CAIG angular-rate output.
- Frame-to-frame CAIG/FOG misalignment is not MATLAB `gyroparams.AxesMisalignment`.
- Historical scripts under `archive/v1`, `archive/v2`, and `experiments/legacy_analysis` preserve independent development and validation evidence.
