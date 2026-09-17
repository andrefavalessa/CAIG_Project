# Review changes and validation (2026-09-16)

The stage was an untracked directory inside the existing `CAIG_Project` Git
repository, on main at 61435b8. Other untracked stages and archives were left
untouched. Work uses `review/zhang-scientific-audit-20260916`; no nested Git
repository or new distribution license was created.

Before source changes, 437 existing repository files outside `.git` were hashed;
source/documentation originals were also copied to ignored local review storage.
The published manifest contains only this stage's historical file hashes.

## Corrections

- Removed the 20 ms runner's implicit load from historical `outputs/`.
  A baseline is now an explicit optional argument; standalone execution is valid.
- Both runners create new result directories and reject nonempty destinations.
  `reproduce_all` supplies fresh comparison prerequisites explicitly.
- Replaced obsolete two-script/path instructions; documented four entry scripts,
  a full workflow, real toolbox use, binary policy and limits of the claims.
- Traced x0/P0 directly to Zhang Eq. (28), separating them from project Q/R.
- Added a preregistered convergence metric and limited noise/rotation/seed
  diagnostics. Display limits include all excursions; no smoothing or tuning.
- Preserved the physical model, filter equations, default parameters and branch
  logic. No ambiguity estimator was added.

## Checks actually executed

MATLAB R2025a Update 1, Navigation Toolbox. A source-only copy started with
`restoredefaultpath` and no `outputs` directory, then ran all four cases.
The original historical baseline was not rerun in place or overwritten.
New-copy estimates, probabilities and synchronization were bit-identical to
saved 1 ms data; 20 ms diagnostics, principal candidates and known-branch
control estimates/rates also matched using `isequaln`.

Both 20 ms main filters stayed blocked. Standalone 20 ms constant-speed ran
without a baseline input; a nonempty destination correctly raised
`figrepro:OutputExists`. Existing phase/rate round-trip, probability intervention,
causal-prefix/future-support, FOG scaling, covariance and sensitivity checks passed.
All 14 generated FIG files reopened; all 14 PNGs passed size/readability checks.
The added convergence PNG was visually reviewed. Code Analyzer reported no
messages for the checked sources. Numerical and dependency evidence is under
`review/results/`; large logs/MAT/FIG and original snapshots stay local/ignored.

Scientific checks demonstrate algebraic consistency and reproducible software
behavior under the stated assumptions, not sensor accuracy, independent
observability validation or statistical coverage. Five extra noise seeds are
a limited diagnostic. Cross-release bitwise reproducibility is not asserted.

Publication includes this stage only. PDFs and archives are excluded; GitHub
repository visibility is unchanged. Historical preservation is checked by
SHA-256, separately from the regression comparisons.
