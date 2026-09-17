# Independent noise, timing and estimator studies

These self-contained studies use script-local helper functions and MATLAB
toolbox functions. They examine noise assumptions, timing and estimator behavior
independently of `CAIG_Main_Simulation`. They neither load files
from other experiments nor automatically export/overwrite the archived figures.
Run scripts individually; do not add this directory recursively to the main or Zhang experiment path.

| Script group | Scientific/software question |
|---|---|
| `CAIG_Kalman_trackingKF_validation.m` | Manual KF versus MATLAB trackingKF on identical data |
| `CAIG_noise_model_sensitivity.m` | Sensitivity to the CAIG white-noise conversion convention |
| `FOG_AllanVariance_validation.m` | Single/double-sided FOG noise scaling and Allan variance |
| `CAIG_V2_5_MonteCarlo*.m` | Repeated noise realizations, manual and timetable variants |
| `CAIG_V2_6_duration_study*.m` | Observation duration, manual and timetable variants |
| `CAIG_V2_7_synchronization_test.m` | Timestamp offsets |
| `CAIG_V2_8_timetable_synchronization.m` | retime/synchronize behavior |
| `CAIG_V2_9_interpolation_noise_covariance.m` | Interpolation weights and observation covariance |
| `Zhang_Figure6_ConstantSpeed_Behavior.m` | Earlier rate-level constant-speed experiment; distinct from the physical-chain experiment |

From the repository root, for example:

```matlab
run('experiments/legacy_analysis/CAIG_Kalman_trackingKF_validation.m')
```

These scripts clear workspace variables and figures. Run one at a time in a
separate session when preserving interactive work matters. Toolbox requirements
depend on the study; the main workflow does not execute these Monte Carlo
or duration experiments. Nothing here is imported by `experiments/zhang_2019`.
