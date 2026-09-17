# Scientific limitations and research questions

This is a deterministic illustrative simulation with a physical
probability chain, not validated sensor performance. Strengths include separate
loop histories, measurement-only filter interfaces, causal timestamp checks,
probability interventions, nullspace/covariance checks and reproducible seeds.

Limitations: ideal atomic readout and gravity compensation; three virtual axes;
quasi-static/matched rectangular averages instead of atom sensitivity dynamics;
restricted positive principal branch at 1 ms; oracle-only control at 20 ms;
finite simulator rotation versus first-order filter; assumed noise and geography;
one sea state and a small diagnostic seed sample. Conditional KF covariance
is not demonstrated frequentist coverage. Full rank does not imply rapid or
unbiased estimation. Algebraic round-trip accuracy does not validate hardware.

The function `figrepro_verify` tests the fixed demonstration
configuration. Its rank/noise/end-state assertions are not a general parameter
acceptance suite. Large MATLAB structs/MAT files retain useful provenance but
are costly; they remain generated artifacts rather than versioned datasets.
The two interrogation-time configurations use distinct forward and
synchronization paths whose timing assumptions are specified separately.

Next scientific steps: obtain Zhang's simulation code or numerical R/Q/noise,
waveform and stopping criterion; derive the interrogation sensitivity function;
model realistic probability/phase noise and contrast; assess estimator consistency
under finite rotation; then design an acquisition experiment with measurable
sign/fringe information. These extensions, including autonomous ambiguity
resolution, are not included in the implemented experiments.
