# Zhang-style monitoring figures with an explicit CAIG chain

Self-contained MATLAB illustration of constant-speed and level-2 sway identification,
based on [Zhang et al. (2019)](https://doi.org/10.3390/s19020222). No other
CAIG_Project stage or Phase 5 machinery is imported.

**Status:** 1 ms reconstructs within a declared ideal principal-branch envelope.
At 20 ms both cases violate that branch and stop before the normal Zhang filter.
Separately labeled known-branch controls use simulator signs/fringe integers to
diagnose the downstream filter. They are not autonomous acquisition.

## Run from a clean clone

Tested with MATLAB R2025a Update 1 and Navigation Toolbox. `imuSensor` and
`gyroparams` are required; `NoiseType` requires R2023b or later (older releases
not tested). Dependency analysis also lists Sensor Fusion and Tracking Toolbox
as an alternative provider; this run actually checked out Navigation Toolbox.
Base MATLAB provides the KF, timetables and plotting. No Python, Simulink,
Statistics toolbox or downloaded data is required to reproduce these cases.

```sh
git clone https://github.com/andrefavalessa/CAIG_Project.git
cd CAIG_Project
git switch review/zhang-scientific-audit-20260916
```

In MATLAB, navigate to `05_Zhang_Physical_Figure_Reproduction`:

```matlab
manifest = reproduce_all;  % four cases, fresh explicit comparison inputs
addpath('review');
checks = verify_review(manifest.outputRoot);
report = run_convergence_review(manifest.outputRoot); % optional diagnostics
```

Every invocation creates a new directory under `outputs/runs/`. PNG, FIG, MAT
and JSON outputs include separate blocked-main diagnostics and known-branch
controls. A supplied output directory must be empty. Historical files directly
under `outputs/` are never overwritten or implicitly loaded.

Four individual scripts also work:

```matlab
run_figure6_style_constant_speed
run_figure8_style_triaxial_sway
run_figure6_style_constant_speed_T20ms
run_figure8_style_triaxial_sway_T20ms
```

Both 20 ms scripts work without a 1 ms MAT file. An optional explicit comparison
uses `figrepro_runT20ms(caseName,pwd,emptyOutputDir,baselineMatFile)`.
Returned result structs contain figure paths; `openfig(path,'visible')` opens
saved figures. `run_convergence_review` also accepts an explicitly supplied
historical directory containing both 1 ms MAT files, read-only.

## Model and structure

```text
true angular motion -> separate loop phases -> P1/P2
 -> separate phase reconstruction -> differential phase / Kdual
 -> reconstructed CAIG rate -> causal FOG synchronization -> Zhang filter
```

`config/`, `motion/`, `sensors/`, `synchronization/`, `estimation/`, and `plotting/`
contain the model; top-level runners orchestrate it. `review/` contains bounded
diagnostics and regression checks. Truth is restricted to generation and
post-estimation tests, except for the clearly labeled simulator-informed control
and simulation-side branch audit. Neither is an operational ambiguity detector.

Constant motion has linear sensitivity rank 3/6 and does not identify all states.
Sway has rank 6/6 and approaches the injected parameters. This supports the
qualitative Figure 6/8 comparison, not exact curves or a hardware claim.
The separately declared review metric confirms historical sway alignment at
56.21 s and its first joint/bias interval at 363.21 s. Zhang's 74.60 s is not
reproduced as an equivalent stopping criterion from the published details.

Read [traceability](docs/SCIENTIFIC_TRACEABILITY.md),
[convergence findings](docs/CONVERGENCE_FINDINGS.md), [20 ms results](README_T20ms.md),
[limitations](docs/LIMITATIONS.md), and [changes and checks](docs/CHANGELOG.md).

## Result and publication policy

Historical outputs remain intact locally; their SHA-256 hashes are in
`review/preservation/historical_manifest.json`. Generated `outputs/` and
`review/local/` are ignored: MAT/FIG files are reproduced, not versioned.
Small review JSON records and one explanatory PNG are versioned under
`review/results/`; they are evidence, never runtime prerequisites. MATLAB
binary formats/graphics may vary across releases; deterministic numeric
regression was checked on the stated release. No paper PDFs, external-stage
archives or local credentials are included. No distribution license is added.
