function result = figrepro_runCase(caseName, projectRoot, outputDir)
%FIGREPRO_RUNCASE Self-contained orchestration; all writes stay in this project.

priorPath = path;
guard = onCleanup(@() path(priorPath));
folders = {'config','motion','sensors','synchronization','estimation','plotting'};
for k = 1:numel(folders),
    addpath(fullfile(projectRoot, folders{k}));
end
cfg = figrepro_config(caseName);
if nargin < 3,
    outputDir = [];
end
outputDir = figrepro_outputDirectory(projectRoot, [caseName '_T1ms'], outputDir);

% Distinguish the atomic effective epoch from the later readout availability.
tFOG = (0:1 / cfg.fog.sampleRateHz:cfg.durationSec).';
start = (0:1 / cfg.caig.sampleRateHz:cfg.durationSec - 1 / cfg.caig.sampleRateHz).';
effective = start + cfg.caig.Tsec;
last = start + 2 * cfg.caig.Tsec;
available = last + cfg.caig.readoutSec;
shots = timetable(seconds(available), effective, start, last, available, ...
    'VariableNames', {'EffectiveSec','FirstPulseSec','LastPulseSec','AvailableSec'});

% Truth drives sensor generation only; latent atomic phase is kept separate.
omegaA_FOG = figrepro_motion(tFOG, caseName, cfg.simulation);
omegaA_CAIG = figrepro_motion(effective, caseName, cfg.simulation);
[fog,fogSimulation] = figrepro_fog(tFOG, omegaA_FOG, cfg.fog, cfg.simulation);
[probabilities,latentCAIG] = figrepro_caig(shots, omegaA_CAIG, cfg.caig);

% Measurement-only reconstruction, causal matching, then calibration estimation.
caig = figrepro_reconstruct(probabilities, cfg.inverse);
synced = figrepro_synchronize(fog, caig, fogSimulation.sampleSigmaRadPerSec);
estimate = figrepro_zhang(synced, cfg.filter);

% Truth is introduced again only AFTER estimation, for validation/display.
validation = figrepro_verify(cfg, fog, fogSimulation, probabilities, latentCAIG, caig, synced, estimate);
result.cfg = cfg;
result.fog = fog;
result.fogSimulation = fogSimulation;
result.probabilities = probabilities;
result.latentCAIG = latentCAIG;
result.caig = caig;
result.synchronized = synced;
result.estimate = estimate;
result.validation = validation;

result.figureFiles = figrepro_plot(estimate, cfg, outputDir);
stem = ['figure' num2str(6+2*strcmp(caseName,'triaxial_sway')) '_' caseName];
save(fullfile(outputDir, [stem '_results.mat']), 'result', '-v7');
fid = fopen(fullfile(outputDir, [stem '_summary.json']), 'w');
assert(fid >= 0, 'Cannot create summary file.');
fileGuard = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(validation, 'PrettyPrint', true));
fprintf('%s: %.0f s; FOG %.0f Hz, CAIG %.0f Hz; %s\n', ...
    caseName, cfg.durationSec, cfg.fog.sampleRateHz, cfg.caig.sampleRateHz, fogSimulation.backend);
fprintf('CAIG: T=%.1f ms, v=%.2f m/s, Kdual=%.6g s; ideal probability readout.\n', ...
    1e3 * cfg.caig.Tsec, cfg.caig.atomSpeedMPerSec, cfg.caig.KdualSec);
fprintf('Timestamp synchronization passed; sensitivity rank %d/6; validation passed.\n', ...
    estimate.sensitivityRank);
fprintf('Final misalignment [deg]: %.6f %.6f %.6f\n', validation.finalMisalignmentDeg);
fprintf('Final FOG bias [deg/h]: %.6f %.6f %.6f\n', validation.finalBiasDegH);
end
