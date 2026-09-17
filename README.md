# CAIG + FOG simulation and scientific experiments

This MATLAB project studies a Cold Atom Interference Gyroscope (CAIG) and its
combination with a Fiber-Optic Gyroscope (FOG) to estimate frame misalignment
and FOG bias. It separates the modular system-level simulator, independent
experiments and historical development evidence.

**Current experiment:** [Zhang 2019](experiments/zhang_2019/README.md), with an
explicit chain from angular motion through two loop phases, two probabilities,
phase reconstruction, synchronized rates and the Zhang monitoring filter.
This is a qualitative scientific comparison, **not a quantitatively validated
reproduction of Zhang**.

## Run

From the repository root in MATLAB:

```matlab
manifest = run_zhang_experiment;
```

This runs the constant-speed and level-2 sway cases at 1 ms and 20 ms, writing
new PNG/FIG/MAT/JSON outputs under `experiments/zhang_2019/outputs/runs/`.
It never overwrites a nonempty output directory or requires historical MAT
files. The experiment also runs independently from its own folder using
`reproduce_all` or any of its four individual entry scripts.

The separate modular system-level simulation remains available:

```matlab
CAIG_Main_Simulation
```

It uses only the eight explicit directories in `src/`, produces figures and
the workspace struct `SimulationOutput`, and does not write reference files.
Its three-axis CAIG input is a rate-level abstraction; the separate Y-axis
physical check does not turn it into probability-based acquisition.

Tested with MATLAB R2025a Update 1. The Zhang experiment requires `imuSensor`
and `gyroparams` (Navigation Toolbox was used). The modular main additionally
requires `trackingKF`. See the experiment README and
[modular documentation](docs/MODULAR_BASELINE.md) for dependencies and assumptions.
Do not use `addpath(genpath(pwd))`: archived/local functions can shadow active modules.

## Repository map

| Location | Purpose |
|---|---|
| `src/` | Modules actually called by `CAIG_Main_Simulation.m` |
| `experiments/zhang_2019/` | Autonomous physical-chain experiment; its modules stay internal |
| `experiments/legacy_analysis/` | Independent noise, timing, Monte Carlo, duration and filter-comparison studies |
| `archive/v1/`, `archive/v2/` | Preserved historical MATLAB versions |
| `archive/figures/` | Original V1/V2 reference PDF figures, byte-preserved |
| `docs/` | Scientific documentation, execution notes and reorganization evidence |
| `references/` | Bibliography, links and parameter-source register |

## Reference results and limitations

Historical Zhang reference PNG/FIG/MAT/JSON files remain locally at
`experiments/zhang_2019/outputs/` (direct children, distinct from new `runs/`).
Those large generated files are ignored by Git as before. A clone includes
the small reviewed summaries and explanatory image in
[`experiments/zhang_2019/review/results/`](experiments/zhang_2019/review/results/),
the original versioned PDFs in [`archive/figures/`](archive/figures/), and all
source needed to generate fresh results. The hash manifest and move map are in
[`docs/reorganization/`](docs/reorganization/README.md).

**Ambiguity at T=20 ms remains unresolved.** The principal probability inverse
fails in both cases, so the normal filter is blocked. Known-branch controls use
simulator information and do not demonstrate autonomous reconstruction.

**The convergence difference from Zhang remains under investigation.** Noise,
synchronization and finite-rotation/linearized-model differences have been
diagnosed; the paper does not specify enough detail to equate its 74.60 s with
the project's own stopping metric. See
[convergence findings](experiments/zhang_2019/docs/CONVERGENCE_FINDINGS.md) and
[limitations](experiments/zhang_2019/docs/LIMITATIONS.md). Ideal atomic readout
and ideal static gravity compensation also limit interpretation.

No model, parameter, filter or historical result was changed for this layout.
No distribution license has been added. Pre-existing untracked V3 work and
compressed snapshots remain local under ignored `archive/local/`; they are
frozen snapshots, not part of the active MATLAB path or this publication.
