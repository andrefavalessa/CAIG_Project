function result = figrepro_runT20ms(caseName, projectRoot, out, baselineFile)
%FIGREPRO_RUNT20MS New-only outputs; preserved 1 ms main is never invoked.

priorPath = path;
pathGuard = onCleanup(@() path(priorPath));
folders = {'config','motion','sensors','synchronization','estimation','plotting'};
for j = 1:numel(folders),
    addpath(fullfile(projectRoot, folders{j}));
end
cfg = figrepro_configT20ms(caseName);
if nargin < 3,
    out = [];
end
if nargin < 4,
    baselineFile = '';
end
out = figrepro_outputDirectory(projectRoot, [caseName '_T20ms'], out);
T = cfg.caig.Tsec;

% Preserve the distinction between effective time, pulse support and readout.
start = (0:1 / cfg.caig.sampleRateHz:cfg.durationSec - 1 / cfg.caig.sampleRateHz).';
effective = start + T;
last = start + 2 * T;
available = last + cfg.caig.readoutSec;
shots = timetable(seconds(available), effective, start, last, available, ...
    'VariableNames', {'EffectiveSec','FirstPulseSec','LastPulseSec','AvailableSec'});

% Generation only: an independent fine-grid physical reference and the FOG.
tReference = (0:1 / cfg.window.referenceSampleRateHz:cfg.durationSec).';
referenceRate = figrepro_motion(tReference, caseName, cfg.simulation);
reference = timetable(seconds(tReference), referenceRate, 'VariableNames', {'RateARadPerSec'});
referenceWindow = figrepro_windowMean(reference, shots, cfg.window.referenceSampleRateHz);
tFog = (0:1 / cfg.fog.sampleRateHz:cfg.durationSec).';
omegaA_FOG = figrepro_motion(tFog, caseName, cfg.simulation);
[fog,fogSimulation] = figrepro_fog(tFog, omegaA_FOG, cfg.fog, cfg.simulation);
[probabilities,latent] = figrepro_caigT20ms(shots, referenceWindow.mean, cfg.caig);

% Preserve the ORIGINAL probability-only inverse as an attempted candidate.
% It cannot know its own branch failure from P1/P2 alone. Do not reinterpret
% folded candidates as validated measurements, and do not feed them to a KF.
principal = figrepro_reconstruct(probabilities, cfg.inverse);
[diagnostics,oracleLabels] = figrepro_T20msDiagnostics(latent, principal, cfg);
mainEstimate = [];
principalSync = figrepro_synchronizeT20ms(fog, principal, cfg.fog);

% Only a certified principal reconstruction may enter the normal filter.
if diagnostics.currentReconstructionValid && cfg.inverse.designEnvelopeGuaranteed
    mainEstimate = figrepro_zhang(principalSync, cfg.filter);
    diagnostics.mainFilterRan = true;
    diagnostics.mainStatus = 'VALID PRINCIPAL-BRANCH RUN';
else
    diagnostics.mainStatus = 'BLOCKED BEFORE FILTER: principal-branch reconstruction not certified';
end

% CONTROL boundary: only the simulator has these discrete labels. Conditional
% inversion still passes through BOTH measured probabilities. This does not
% solve acquisition and is not counted as successful truth-free reconstruction.
control = [];
if ~diagnostics.mainFilterRan && cfg.control.enabled
    control.label = 'KNOWN-BRANCH CONTROL / SIMULATOR ORACLE / NOT AN ACQUISITION RESULT';
    control.cfg = cfg;
    control.branchLabelProvenance = oracleLabels.provenance;
    control.externalBranchLabels = oracleLabels;
    control.probabilities = probabilities;
    control.caig = figrepro_knownBranchControl(probabilities, cfg.inverse, oracleLabels);
    control.synchronized = figrepro_synchronizeT20ms(fog, control.caig, cfg.fog);
    control.estimate = figrepro_zhang(control.synchronized, cfg.filter);
end

% Validation is outside both the inverse and the estimator. No truth used to
% update/repair a main estimate; the main has already stopped when invalid.
validation = figrepro_validateT20ms(cfg, shots, fog, fogSimulation, ...
    probabilities, latent, principal, diagnostics, control, referenceWindow);
comparison.available = ~isempty(baselineFile);
comparison.note = 'No baseline supplied; standalone 20 ms execution requires no historical MAT files.';

if comparison.available
    baseline = load(baselineFile, 'result');  % Explicit, read-only optional comparison.
    assert(strcmp(baseline.result.cfg.caseName, caseName) && baseline.result.cfg.caig.Tsec == .001, ...
        'figrepro:Baseline', 'Comparison requires the matching 1 ms case.');
    comparison.T1msKsingleSec = baseline.result.cfg.caig.KdualSec / 2;
    comparison.T1msKdualSec = baseline.result.cfg.caig.KdualSec;
    comparison.Kratio = cfg.caig.KdualSec / comparison.T1msKdualSec;
    comparison.T1msMaxAbsLoopPhaseRad = max(abs([baseline.result.latentCAIG.phaseLoop1Rad, ...
        baseline.result.latentCAIG.phaseLoop2Rad]), [], 'all');
    comparison.T1msMaxAbsDifferentialPhaseRad = ...
        max(abs(baseline.result.latentCAIG.phaseDiffRad), [], 'all');
    comparison.T1msOutsidePrincipalFraction = 0;  % Independently check the saved phases.
    savedPhases = [baseline.result.latentCAIG.phaseLoop1Rad,baseline.result.latentCAIG.phaseLoop2Rad];
    assert(all(savedPhases >= 0 & savedPhases <= pi, 'all'));
    comparison.T1msFinalMisalignmentDeg = baseline.result.validation.finalMisalignmentDeg;
    comparison.T1msFinalBiasDegH = baseline.result.validation.finalBiasDegH;
    comparison.note = 'Saved 1 ms files read only; 1 ms used midpoint FOG interpolation, 20 ms uses matched 40 ms rectangular averages. Timing/noise averaging also change.';
end

result.cfg = cfg;
result.probabilities = probabilities;
result.latentCAIG = latent;
result.fog = fog;
result.fogSimulation = fogSimulation;
result.referenceWindow = referenceWindow;
result.principalCandidate = principal;
result.principalCandidateSynchronized = principalSync;
result.estimate = mainEstimate;
result.diagnostics = diagnostics;
result.validation = validation;
result.comparisonWithPreserved1ms = comparison;
result.knownBranchControlRan = ~isempty(control);
result.figureFiles = figrepro_plotT20ms(result, control, out);
summary = diagnostics;
summary.validation = validation;
summary.comparisonWithPreserved1ms = comparison;
summary.matlabVersion = version;
summary.controlRan = ~isempty(control);

if ~isempty(control)
    control.validation = validation.control;
    control.figureFiles = result.figureFiles.control;
    controlStem = fullfile(out, [cfg.outputStem '_known_branch_control']);
    save([controlStem '_results.mat'], 'control', '-v7');
    writeJson([controlStem '_summary.json'], control.validation);
    result.knownBranchControlFile = [controlStem '_results.mat'];
    summary.controlLabel = control.label;
end
save(fullfile(out, [cfg.outputStem '_results.mat']), 'result', '-v7');
writeJson(fullfile(out, [cfg.outputStem '_summary.json']), summary);

fprintf('%s, T=20 ms: Ksingle=%.9f s; Kdual=%.9f s; 2T=40 ms; available=48 ms.\n', caseName, ...
    cfg.caig.KsingleSec, cfg.caig.KdualSec);
fprintf('Max |loop|=%.6f rad; max |differential|=%.6f rad; outside principal: %d/%d shots.\n', ...
    diagnostics.maxAbsAnyLoopPhaseRad, diagnostics.maxAbsAnyDifferentialPhaseRad, ...
    diagnostics.shotsWithAnyLoopOutside, diagnostics.shotCount);
fprintf('Sign required: %.2f%%; nonzero fringe required: %.2f%%; main filter: %s.\n', ...
    100 * diagnostics.fractionShotsRequiringAnyNegativeSign, ...
    100 * diagnostics.fractionShotsRequiringAnyNonzeroFringe, diagnostics.mainStatus);
if ~isempty(control)
    fprintf('KNOWN-BRANCH CONTROL ONLY: rank %d/6; alignment [deg] %.6f %.6f %.6f; bias [deg/h] %.6f %.6f %.6f.\n', ...
        control.estimate.sensitivityRank, validation.control.finalMisalignmentDeg, ...
            validation.control.finalBiasDegH);
end
fprintf('20 ms validation passed; saved outputs with prefix %s.\n', cfg.outputStem);
end

function writeJson(file, value)
fid = fopen(file, 'w');
assert(fid >= 0, 'Cannot write 20 ms summary.');
guard = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(value, 'PrettyPrint', true));
end
