# Hybrid Cold-Atom and Fiber-Optic Gyroscope Simulation

MATLAB simulations of cold-atom interferometer gyroscope physics, fiber-optic
gyroscope (FOG) measurements, frame-misalignment estimation and phase ambiguity.
The scientific question is when reconstructed cold-atom gyroscope (CAIG) rates
can support joint estimation of sensor misalignment and FOG bias.

## Measurement chain and experiments

The [Zhang-style experiment](experiments/zhang_2019/README.md) models:

```text
angular motion -> separate loop phases -> two transition probabilities
 -> reconstructed loop phases -> differential phase -> CAIG angular rate
 -> synchronization with FOG measurements -> Zhang monitoring filter
```

It compares constant-speed motion and level-2 triaxial sway at interrogation
times of 1 ms and 20 ms. The separate [modular simulator](docs/MODULAR_BASELINE.md)
uses a three-axis rate-level CAIG abstraction and a Y-axis interferometric
physics check; its filter input is not reconstructed from probabilities.
[Supporting studies](experiments/legacy_analysis/README.md) address noise,
synchronization, observation duration and Kalman implementations.

## Results and interpretation

- **1 ms reconstruction:** ideal loop probabilities recover angular rate within
  a declared principal-branch operating envelope. This verifies the conditional
  inverse, not autonomous fringe acquisition or hardware accuracy.
- **Motion and estimation:** constant motion has linear sensitivity rank 3/6
  and cannot identify all six states. Triaxial sway has rank 6/6 and brings
  estimates near the injected parameters; rank alone does not guarantee convergence.
- **20 ms ambiguity:** both motion cases leave the assumed branch. The normal
  filter is blocked because reconstruction fails before estimation.
- **Known-branch control:** simulator-provided signs and fringe indices isolate
  the downstream estimator from ambiguity resolution. The control retains the
  expected qualitative motion-dependent behavior. Its branch information is
  not available from the hardware observations assumed here, so this is not
  an operational reconstruction result.

Causal ambiguity resolution remains unresolved. The convergence difference
from Zhang's reported 74.60 s remains under investigation: the publication does
not specify enough detail to equate that time with this project's evaluation
criterion. These are simulation-based, qualitative comparisons, not a
quantitatively validated reproduction of Zhang or a hardware demonstration.

Other limitations include ideal probability detection and static gravity
compensation, simplified interrogation dynamics, a rectangular-window
approximation at 20 ms, and finite-rotation simulation with a first-order
Zhang estimator. See [limitations](experiments/zhang_2019/docs/LIMITATIONS.md)
and [convergence analysis](experiments/zhang_2019/docs/CONVERGENCE_FINDINGS.md).

## Run

```sh
git clone https://github.com/andrefavalessa/CAIG_Project.git
cd CAIG_Project
```

From the repository root in MATLAB:

```matlab
manifest = run_zhang_experiment;  % constant-speed and sway, at both times
% Separate rate-level simulation:
CAIG_Main_Simulation
```

Tested with MATLAB R2025a Update 1. The physical-chain experiment requires
`imuSensor` and `gyroparams` (Navigation Toolbox was used); the modular
simulator additionally requires `trackingKF`. See the experiment README for
individual cases and detailed requirements. Use these entrypoints rather than
recursively adding the repository to the MATLAB path.

Each experiment run writes new PNG/FIG/MAT/JSON files under
`experiments/zhang_2019/outputs/runs/`. Nonempty destinations are rejected.
Versioned reference summaries and an explanatory figure are in
[`review/results/`](experiments/zhang_2019/review/results/). Complete generated
outputs are not distributed with the source; existing reference files, when
present, reside directly under `experiments/zhang_2019/outputs/`. No saved
output is required to run the experiment.

## Organization and scientific sources

| Directory | Contents |
|---|---|
| `src/` | Reusable scientific modules for the modular simulator |
| `experiments/` | Independent, reproducible experiments with their own documentation |
| `docs/` | Methodology and supporting scientific documentation |
| `references/` | Bibliography and parameter-source notes |
| `archive/` | Historical implementations and reference figures |

[Scientific traceability](experiments/zhang_2019/docs/SCIENTIFIC_TRACEABILITY.md)
connects sources, equations, implementations and assumptions.
[References](references/README.md) and the [documentation guide](docs/README.md)
provide further detail. Archived implementations are not prerequisites for
understanding or executing the current experiments.
