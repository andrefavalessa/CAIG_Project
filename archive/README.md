# Preserved development versions and figures

- `v1/`: original ideal CAIG physics and validation scripts.
- `v2/`: original hybrid, misalignment, sway and Kalman scripts.
- `figures/V1/`, `figures/V2/`: 13 historical, single-page PDF plots. Inspection
  confirmed phase/probability, rate, misalignment and bias plots, not source
  modules or external papers. The empty historical `figures/Analysis/` directory
  may exist locally; Git does not track empty directories.
- `local/` (ignored): pre-existing untracked V3 folder and three compressed
  snapshots, moved intact. These retain historical relative paths/provenance
  internally; they are frozen local evidence, not supported active entry points.

No archived directory belongs on the active MATLAB path. V1/V2 scripts remain
self-contained and can be run explicitly, for example from the repository root:

```matlab
run('archive/v1/CAIG_V1_ideal.m')
run('archive/v2/CAIG_V2_4c_Kalman_timetable.m')
```

Run historical scripts separately; their original `clear`/figure behavior is
unchanged. Reference figures must not be overwritten. Git history retains the
old paths, and the reorganization manifest maps each reference to its new path.
