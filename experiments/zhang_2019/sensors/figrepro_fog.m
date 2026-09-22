function [measurement,simulation] = figrepro_fog(tSec, omegaA, model, injection)
%FIGREPRO_FOG One exact A-to-F rotation, then bias/noise in F.

% Mounting misalignment is applied once as a finite frame rotation.
phi = injection.misalignmentRad;
S = [0 -phi(3) phi(2);phi(3) 0 -phi(1);-phi(2) phi(1) 0];
C_F_from_A = expm(-S);  % V3 convention; orthogonal finite rotation.
omegaF = omegaA * C_F_from_A.';

% MATLAB adds the configured F-frame bias and seeded sensor noise.
assert(exist('gyroparams', 'class') == 8 && exist('imuSensor', 'class') == 8, ...
    'figrepro:Toolbox', 'This project requires MATLAB gyroparams and imuSensor.');
params = gyroparams('ConstantBias', injection.biasFRadPerSec, ...
    'NoiseDensity', repmat(model.noiseDensity, 1, 3), 'NoiseType', model.noiseType);
imu = imuSensor('accel-gyro', 'SampleRate', model.sampleRateHz, 'Gyroscope', params, ...
    'RandomStream', 'mt19937ar with seed', 'Seed', model.seed);
[~,measuredF] = imu(zeros(size(omegaF)), omegaF);

% AxesMisalignment is left at its ideal default: frame rotation is already applied.
measurement = timetable(seconds(tSec), measuredF, 'VariableNames', {'RateFRadPerSec'});

% Simulation diagnostics stay outside the measured FOG timetable.
simulation.omegaARadPerSec = omegaA;
simulation.omegaFRadPerSec = omegaF;
simulation.C_F_from_A = C_F_from_A;
simulation.noiseFRadPerSec = measuredF - omegaF - injection.biasFRadPerSec;
% Single-sided density-to-sample conversion also supplies synchronization R.
simulation.sampleSigmaRadPerSec = model.noiseDensity * sqrt(model.sampleRateHz);
simulation.backend = 'MATLAB gyroparams + imuSensor, single-sided';
end
