%% FOG_AllanVariance_validation.m
%
% Validate how gyroparams/imuSensor maps a specified Angle Random Walk
% coefficient into simulated gyroscope data.
%
% Two gyro noise conventions are compared:
%
%   A) NoiseType = 'double-sided'
%   B) NoiseType = 'single-sided'
%
% The resulting measurements are analyzed with Allan variance.
%
% For white angular-rate noise, the MathWorks Allan-variance model gives
%
%       adev(tau) = N / sqrt(tau)
%
% therefore:
%
%       adev(1 s) = N
%
% The goal is to determine which imuSensor noise convention reproduces the
% input ARW coefficient with the expected scaling.

clear;
clc;
close all;

%% ============================================================
% 1. SETTINGS
% =============================================================

Fs = 100;                  % [Hz] Zhang FOG data rate
duration = 3600;           % [s] 1 hour
Nsample = Fs * duration;

fprintf('============================================\n');
fprintf('FOG ALLAN VARIANCE VALIDATION\n');
fprintf('============================================\n\n');

fprintf('Sample rate = %.1f Hz\n', Fs);
fprintf('Duration    = %.1f s (%.2f h)\n', ...
    duration, duration/3600);
fprintf('Samples     = %d\n\n', Nsample);

%% ============================================================
% 2. EMCORE EG-1300 ARW
% =============================================================

ARW_deg_sqrt_h = 0.002;    % deg/sqrt(h)

% Convert:
%
% deg/sqrt(h)
%       ->
% rad/sqrt(s)
%
% which is dimensionally equivalent to
%
% (rad/s)/sqrt(Hz)

N_input = deg2rad(ARW_deg_sqrt_h) / sqrt(3600);

fprintf('Input ARW\n');
fprintf('ARW = %.6f deg/sqrt(h)\n', ARW_deg_sqrt_h);
fprintf('N   = %.6e (rad/s)/sqrt(Hz)\n\n', N_input);

%% ============================================================
% 3. TRUE STATIONARY MOTION
% =============================================================

% Sensor is stationary.
%
% Only gyroscope white noise is relevant in this test.

accelTrue = zeros(Nsample,3);
omegaTrue = zeros(Nsample,3);

%% ============================================================
% 4. MODEL A — DOUBLE-SIDED
% =============================================================

rng(1001,'twister');

gyroDouble = gyroparams( ...
    'NoiseDensity', N_input*ones(1,3), ...
    'NoiseType', 'double-sided');

imuDouble = imuSensor( ...
    'accel-gyro', ...
    'SampleRate', Fs, ...
    'Gyroscope', gyroDouble);

[~, omegaDouble] = imuDouble( ...
    accelTrue, ...
    omegaTrue);

%% ============================================================
% 5. MODEL B — SINGLE-SIDED
% =============================================================

% Use the same random seed so that the comparison is as controlled
% as possible.

rng(1001,'twister');

gyroSingle = gyroparams( ...
    'NoiseDensity', N_input*ones(1,3), ...
    'NoiseType', 'single-sided');

imuSingle = imuSensor( ...
    'accel-gyro', ...
    'SampleRate', Fs, ...
    'Gyroscope', gyroSingle);

[~, omegaSingle] = imuSingle( ...
    accelTrue, ...
    omegaTrue);

%% ============================================================
% 6. SAMPLE STANDARD DEVIATIONS
% =============================================================

sigmaDouble_emp = std(omegaDouble(:,1));
sigmaSingle_emp = std(omegaSingle(:,1));

sigmaDouble_theory = ...
    N_input * sqrt(Fs/2);

sigmaSingle_theory = ...
    N_input * sqrt(Fs);

fprintf('============================================\n');
fprintf('SAMPLE-DOMAIN NOISE\n');
fprintf('============================================\n\n');

fprintf('DOUBLE-SIDED\n');
fprintf('Theoretical sigma = %.6e rad/s\n', ...
    sigmaDouble_theory);
fprintf('Empirical sigma   = %.6e rad/s\n\n', ...
    sigmaDouble_emp);

fprintf('SINGLE-SIDED\n');
fprintf('Theoretical sigma = %.6e rad/s\n', ...
    sigmaSingle_theory);
fprintf('Empirical sigma   = %.6e rad/s\n\n', ...
    sigmaSingle_emp);

fprintf('Single / Double empirical ratio = %.6f\n\n', ...
    sigmaSingle_emp/sigmaDouble_emp);

%% ============================================================
% 7. ALLAN VARIANCE
% =============================================================

% allanvar operates on angular-rate measurements.
%
% Use the X axis only because all three axes have identical noise
% parameters in this controlled test.

[avarDouble, tauDouble] = ...
    allanvar(omegaDouble(:,1), 'octave', Fs);

[avarSingle, tauSingle] = ...
    allanvar(omegaSingle(:,1), 'octave', Fs);

adevDouble = sqrt(avarDouble);
adevSingle = sqrt(avarSingle);

%% ============================================================
% 8. ESTIMATE ARW FROM -1/2 SLOPE
% =============================================================

N_double_est = estimateARW( ...
    tauDouble, adevDouble);

N_single_est = estimateARW( ...
    tauSingle, adevSingle);

%% ============================================================
% 9. CONVERT BACK TO deg/sqrt(h)
% =============================================================

ARW_double_est = ...
    rad2deg(N_double_est) * sqrt(3600);

ARW_single_est = ...
    rad2deg(N_single_est) * sqrt(3600);

fprintf('============================================\n');
fprintf('ALLAN VARIANCE RESULTS\n');
fprintf('============================================\n\n');

fprintf('Input ARW\n');
fprintf('%.6f deg/sqrt(h)\n\n', ...
    ARW_deg_sqrt_h);

fprintf('Recovered from DOUBLE-SIDED simulation\n');
fprintf('N   = %.6e (rad/s)/sqrt(Hz)\n', ...
    N_double_est);
fprintf('ARW = %.6f deg/sqrt(h)\n\n', ...
    ARW_double_est);

fprintf('Recovered from SINGLE-SIDED simulation\n');
fprintf('N   = %.6e (rad/s)/sqrt(Hz)\n', ...
    N_single_est);
fprintf('ARW = %.6f deg/sqrt(h)\n\n', ...
    ARW_single_est);

fprintf('Double / input = %.6f\n', ...
    ARW_double_est/ARW_deg_sqrt_h);

fprintf('Single / input = %.6f\n\n', ...
    ARW_single_est/ARW_deg_sqrt_h);

%% ============================================================
% 10. ALLAN-DEVIATION PLOT
% =============================================================

figure;

loglog( ...
    tauDouble, ...
    adevDouble, ...
    'LineWidth', 1.5);

hold on;

loglog( ...
    tauSingle, ...
    adevSingle, ...
    'LineWidth', 1.5);

% Expected ARW line according to MathWorks:
%
% adev(tau) = N/sqrt(tau)

tauRef = logspace( ...
    log10(min(tauSingle)), ...
    log10(max(tauSingle)), ...
    200);

adevExpected = ...
    N_input ./ sqrt(tauRef);

loglog( ...
    tauRef, ...
    adevExpected, ...
    '--', ...
    'LineWidth', 1.5);

xlabel('\tau [s]');
ylabel('Allan deviation [rad/s]');

title('FOG Allan Deviation — NoiseType Validation');

legend( ...
    'double-sided', ...
    'single-sided', ...
    'Expected from input ARW', ...
    'Location', 'best');

grid on;

%% ============================================================
% 11. LOCAL FUNCTION
% =============================================================

function N = estimateARW(tau, adev)

    % MathWorks method:
    %
    % Find the region whose log-log slope is closest to -1/2.
    % Then determine the value of that line at tau = 1 s.

    logTau  = log10(tau);
    logAdev = log10(adev);

    slope = diff(logAdev) ./ diff(logTau);

    targetSlope = -0.5;

    [~, idx] = min(abs(slope - targetSlope));

    b = ...
        logAdev(idx) ...
        - targetSlope*logTau(idx);

    % At tau = 1 s:
    %
    % log10(1) = 0
    %
    % therefore N = 10^b

    N = 10^b;

end