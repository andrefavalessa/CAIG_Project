# Repository layout review

Scope: paths, launch instructions and documentation only. No scientific model,
parameter, filter, probability reconstruction or historical numerical result
was changed. The prior scientific-review PR had already been merged by the
repository owner; this branch starts from remote main `ee5fb30`.

## Inspection before moving

No applicable AGENTS.md was found in the repository or ancestor directories.
Git state, entry scripts, file I/O, addpath usage and local helper functions
were inspected. The modular main calls only 11 functions in the eight source
directories. Its CAIG is a noisy rate abstraction plus a separate physical
Y-axis check, whereas the Zhang experiment reconstructs two probabilities.
Those models are intentionally not combined.

All 11 scripts in `03_Analysis` implement independent studies, often with local
functions named like the modular helpers. They are not called by either main
workflow and contain no project-file loading/export dependencies. Their study
purposes are indexed in `experiments/legacy_analysis/README.md`. Therefore they
belong with experiments, not `src/` or an indiscriminate MATLAB path.

All 13 PDFs in `04_Figures` were inspected as rendered plots: phase/probability,
rates, frame misalignment and bias histories for V1/V2. They are historical
results rather than a runnable plotting module. Their bytes are preserved.

## Move map

| Previous location | New location | Treatment |
|---|---|---|
| config/, motion/, sensors/, synchronization/, estimation/, validation/, visualization/, utils/ | src/ with the same subdirectories | git mv; MATLAB module bytes unchanged |
| 05_Zhang_Physical_Figure_Reproduction/ | experiments/zhang_2019/ | git mv tracked files; ignored results moved intact; all 27 MATLAB sources unchanged |
| 01_V1_CAIG_Physics/ | archive/v1/ | git mv; only README links updated |
| 02_V2_Hybrid_CAIG_FOG/ | archive/v2/ | git mv, byte-preserved |
| 03_Analysis/ | experiments/legacy_analysis/ | git mv; all script bytes unchanged |
| 04_Figures/ | archive/figures/ | git mv; PDF bytes unchanged |
| 05_References/ | references/ | git mv; location text updated |
| README.md | docs/MODULAR_BASELINE.md | git mv, update paths and label retained model scope |
| untracked V3 directory and three compressed snapshots | archive/local/ (ignored) | Local moves, bytes unchanged, not published or placed on MATLAB path |

`CAIG_Main_Simulation.m` stays at the root; its only code change inserts `src`
in the existing explicit addpath loop. New `run_zhang_experiment.m` adds only
the independent experiment root, delegates to its existing `reproduce_all`,
and restores the previous MATLAB path. No experiment modules were extracted.

The Windows directory rename for Zhang was refused, so tracked files were
moved with individual `git mv` calls and local ignored files with native
file moves. Empty old directories were removed only after checking that they
contained no files. No application was terminated to force a directory move.

## Preservation and checks

Before changes, 598 files (including ignored/local artifacts) were SHA-256
hashed. The full local manifest stays in ignored `local/before.json`.
`reference_hashes.json` records old/new locations and the original digest of
versioned reference figures/summaries and local historical Zhang outputs.
Embedded old paths in historical MAT/JSON records remain provenance, not
rewritten data or runtime dependencies.

`.gitattributes` disables line-ending conversion for versioned reference
artifacts. Some JSON records already had CRLF bytes locally while the old Git
blobs used LF; the new index deliberately retains those original local bytes.
Their parsed JSON content is unchanged. This can appear as a line-ending-only
diff, but permits the same SHA-256 check on Windows and Unix checkouts.

Verify preserved files from any working directory with Python 3.11 or later:

```sh
python docs/reorganization/verify_reference_hashes.py
# On the original workstation, also require the ignored historical outputs:
python docs/reorganization/verify_reference_hashes.py --require-local
```

A clean clone intentionally lacks ignored historical MAT/FIG/PNG outputs,
but includes versioned summaries/figures and can generate all current cases
without them. This policy is unchanged. Do not overwrite reference paths.

MATLAB validation and final counts are recorded in `validation.json` and
`preservation.json`. Large audit logs/new execution files remain ignored.
The archived V3 snapshot and all costly legacy Monte Carlo/duration studies
are not asserted to have been rerun; V3 retains its old external-paper and
relative-path dependencies as historical local evidence.

Final results (MATLAB R2025a Update 1): the entire modular `SimulationOutput`
matched the pre-move run exactly. The relocated Zhang workflow passed all four
cases and historical numerical regression, with both 20 ms normal filters
blocked and the controls kept separate. A clean Git-index checkout with no
ignored outputs independently ran both workflows; 14 PNG and 14 FIG files were
checked, the launcher restored the MATLAB path, and no shared `src/` module
was needed by Zhang. Code Analyzer passed the changed entrypoints and the
experiment's existing source checks. Local Markdown links resolve.

All 598 original files remain accounted for: 592 are byte-identical and six
have only the declared path/documentation changes. All 38 scientific MATLAB
modules and all 69 reference artifacts are byte-identical. On a clean checkout,
all 23 versioned reference artifacts pass the same hash check; 46 documented
ignored historical files are absent and can be regenerated as fresh results.
