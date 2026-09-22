function cfg = figrepro_config(caseName)
%FIGREPRO_CONFIG Fixed design choices; full parameter provenance in README.
% The estimator receives cfg.inverse/cfg.filter only, never cfg.simulation.

cfg.caseName = caseName;
cfg.durationSec = 600;  % Existing constant-speed/duration studies.

% FOG cadence, white-noise convention and reproducible realization.
cfg.fog.sampleRateHz = 100;  % Zhang simulation cadence.
cfg.fog.arwDegSqrtHour = 0.002;  % Adopted EMCORE EG-1300 ARW bound.
cfg.fog.noiseDensity = deg2rad(cfg.fog.arwDegSqrtHour) / 60;
cfg.fog.noiseType = 'single-sided';  % Existing project Allan validation.
cfg.fog.seed = 5606;  % Fixed reproducibility choice, both cases.

% Simulation-only mounting misalignment, bias and prescribed motion.
cfg.simulation.misalignmentRad = deg2rad([1;2;3]);  % Zhang; rotation-vector interpretation.
cfg.simulation.biasFRadPerSec = deg2rad([.1 .1 .1]) / 3600;
cfg.simulation.swayAmplitudeRad = deg2rad([.5 .2 .3]);  % Zhang level 2.
cfg.simulation.swayPeriodSec = [20 30 30];

% Frozen navigation conditions for the constant-speed case.
cfg.simulation.latitudeRad = deg2rad(45);  % Legacy geographic assumption.
cfg.simulation.headingRad = deg2rad(30);  % Zhang constant-speed scenario.
cfg.simulation.speedMPerSec = 15 * 0.514444;  % 15 knots; legacy conversion.
cfg.simulation.heightM = 0;
cfg.simulation.earthRateRadPerSec = 7.292115e-5;
cfg.simulation.earthSemiMajorM = 6378137;
cfg.simulation.earthFlattening = 1 / 298.257223563;

% Atomic parameters and three virtual sensing geometries.
cfg.caig.sampleRateHz = 5;  % Zhang cadence, not a hardware cycle claim.
cfg.caig.lambdaM = 780.241209686e-9;  % Steck Rb-87 D2.
cfg.caig.kPerM = 4 * pi / cfg.caig.lambdaM;
cfg.caig.atomSpeedMPerSec = 2.79;  % Adopted Tackmann value.
cfg.caig.nominalReferenceTsec = .0247;  % Historical Tackmann default; NOT run here.
cfg.caig.Tsec = .001;  % Existing V3 phase-5 low-T study value.
cfg.caig.readoutSec = .008;  % Availability at 10 ms permits causal interpolation.
cfg.caig.gravityA = [0 0 -9.80665];  % Fixed in A, as in the V3 virtual-triad fixture.
cfg.caig.kDirectionsA = [0 1 0;0 0 1;1 0 0];
cfg.caig.v1DirectionsA = [0 0 1;1 0 0;0 1 0];  % k cross v = positive sensed axis.
cfg.caig.loopOffsetRad = [0 0];
cfg.caig.controlledCommonPhaseRad = pi / 2;

% Constant, known gravity cancellation plus a pi/2 working point. This is a
% new ideal phase-control assumption, not truth-driven feedback or Zhang data.
% No physical feedback servo is modeled.
cfg.caig.sharedPulsePhaseRad = cfg.caig.controlledCommonPhaseRad - ...
    cfg.caig.kPerM * (cfg.caig.kDirectionsA * cfg.caig.gravityA.') * cfg.caig.Tsec^2;
cfg.caig.KdualSec = 4 * cfg.caig.kPerM * cfg.caig.atomSpeedMPerSec * cfg.caig.Tsec^2;
cfg.caig.rateNormBoundRadPerSec = .005;  % Declared operating envelope, not estimated truth.

% Ideal V3 probability readout. Do not silently retain nominal sensitivity
% at a shorter T: finite atom count, detection and phase noise are omitted.
cfg.caig.phaseNoiseStdRad = 0;

% Reconstruction sees calibration and the declared branch, not latent phase.
cfg.inverse.KdualSec = cfg.caig.KdualSec;
cfg.inverse.probabilityTolerance = 32 * eps;
cfg.inverse.assumedLoopIntervalRad = [0 pi];  % Each loop takes +acos, fringe n=0.

% Constant-state Kalman prior; angle states use rad, bias states use rad/s.
cfg.filter.initialState = zeros(6, 1);
cfg.filter.priorStd = [deg2rad([1;2;3]);deg2rad(.1)/3600*ones(3,1)];
cfg.filter.F = eye(6);
cfg.filter.Q = zeros(6);  % Constant bias/alignment, no stochastic drift.

cfg.plot.dpi = 180;
cfg.plot.visible = 'off';  % Scripts save files; openfig can inspect them.

% A design-level branch proof using a fixed motion bound, before simulation.
% |rotation + rotation-gravity| <= 2*k*(v*T^2 + |g|*T^3)*|Omega_A|.
cfg.inverse.maximumDepartureFromMidfringeRad = 2 * cfg.caig.kPerM * ...
    (cfg.caig.atomSpeedMPerSec * cfg.caig.Tsec^2 + ...
     norm(cfg.caig.gravityA) * cfg.caig.Tsec^3) * cfg.caig.rateNormBoundRadPerSec;
assert(cfg.inverse.maximumDepartureFromMidfringeRad < pi / 2, ...
    'figrepro:BranchDesign', 'Operating envelope leaves the declared principal branch.');
assert(2 * cfg.caig.Tsec + cfg.caig.readoutSec < 1 / cfg.caig.sampleRateHz, ...
    'figrepro:Timing', 'Sequential shots must fit the CAIG cycle.');
assert(ismember(caseName, {'constant_speed','triaxial_sway'}), 'Unknown case.');
end
