# CAIG V1 — Ideal Physics Baseline

This folder preserves the original ideal CAIG physics implementation and its independent validation scripts.

- Zhang et al. (2019) provides the main CAIG model.
- Tackmann et al. (2012) supplies the pulse separation time and atomic velocity that are not numerically specified by Zhang.
- Steck supplies the Rb-87 D2 wavelength.

Detailed current parameter traceability is maintained in [`../05_References/parameter_sources.md`](../05_References/parameter_sources.md).

The active modular end-to-end simulator is [`../CAIG_Main_Simulation.m`](../CAIG_Main_Simulation.m). V1 remains a frozen historical validation baseline.
