# Experiment changelog

## Scientific experiments and reproducibility — 2026-09-16

- Added the explicit dual-loop phase and probability measurement chain for
  constant-speed and level-2 triaxial-sway comparisons.
- Added 20 ms ambiguity diagnostics and separately labeled known-branch
  controls using simulator-provided signs and fringe indices.
- Added independent 20 ms execution with an explicit, optional reference-data
  input for comparisons. Invalid principal-branch reconstruction blocks the
  normal filter before estimation.
- Added fresh output directories and rejection of nonempty destinations;
  `reproduce_all` generates comparison inputs explicitly.
- Documented equation and parameter traceability, including x0/P0 from Zhang
  Eq. (28), project Q/R choices, timing assumptions and ideal readout.
- Added a predefined convergence metric and limited noise, rotation-model and
  seed diagnostics. Plots retain unsmoothed histories and full excursions.

## Reported verification

MATLAB R2025a Update 1 with Navigation Toolbox was used for all four cases.
Execution without pre-existing output files reproduced saved 1 ms estimates,
probabilities and synchronization exactly. The 20 ms diagnostics, principal
candidates and known-branch control estimates/rates also matched reference
results using `isequaln`.

Both 20 ms normal filters remained blocked. Standalone constant-speed execution
required no reference input. A nonempty output destination raised
`figrepro:OutputExists`. Phase/rate round-trip, probability-intervention,
causal-prefix/future-support, FOG scaling, covariance and sensitivity checks
passed. All 14 FIG files reopened; all 14 PNG files passed size/readability
checks. The convergence image was visually reviewed, and Code Analyzer
reported no messages for the checked sources. Numerical records and dependency
information are in `review/results/`.

These are numerical and software checks under the stated assumptions, not
sensor-accuracy, hardware, nonlinear-observability or statistical-coverage
validation. Five additional seeds provide a limited diagnostic; cross-release
bitwise reproducibility is not asserted.
