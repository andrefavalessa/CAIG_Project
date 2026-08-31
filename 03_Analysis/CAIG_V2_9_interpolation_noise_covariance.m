%% CAIG_V2_9_interpolation_noise_covariance.m
%
% Study of the effect of MATLAB linear interpolation on the
% white-noise covariance of the FOG signal.
%
% Main question:
%
% When noisy FOG measurements are retimed to CAIG epochs that
% do NOT coincide with the original 100-Hz FOG sampling grid,
% how does linear interpolation modify the effective FOG noise
% variance and consequently the observation covariance R?
%
%
% FOG:
%   EMCORE EG-1300
%   ARW = 0.002 deg/sqrt(h)
%   Fs_FOG = 100 Hz
%   NoiseType = 'single-sided'
%
%
% CAIG:
%   Fs_CAIG = 5 Hz
%   current equivalent white-noise model
%
%
% IMPORTANT:
%
% This script contains:
%
%   - no physical angular motion
%   - no misalignment
%   - no FOG bias
%   - no Kalman filter
%
% The purpose is ONLY to characterize the statistics produced
% by interpolation.
%
%
% For independent white-noise samples:
%
%       n_interp = (1-alpha)n_k + alpha n_(k+1)
%
% therefore
%
%       Var(n_interp)
%
%       = [(1-alpha)^2 + alpha^2] sigma_FOG^2
%
%
% This relation is tested numerically using MATLAB:
%
%       timetable + retime(...,'linear')

clear;
clc;
close all;

%% ============================================================
% 1. GENERAL SETTINGS
% =============================================================

FsFOG = ...
    100;                % [Hz]

FsCAIG = ...
    5;                  % [Hz]

duration = ...
    3600;               % [s]

dtFOG = ...
    1/FsFOG;

dtCAIG = ...
    1/FsCAIG;

tFOG = ...
    (0:dtFOG:duration-dtFOG).';

tCAIG0 = ...
    (0:dtCAIG:duration-dtCAIG).';

NFOG = ...
    length(tFOG);

NCAIG = ...
    length(tCAIG0);

fprintf('============================================\n');
fprintf('CAIG V2.9 - INTERPOLATION NOISE COVARIANCE\n');
fprintf('============================================\n\n');

fprintf('Duration         = %.1f s\n', ...
    duration);

fprintf('FOG sample rate  = %.1f Hz\n', ...
    FsFOG);

fprintf('CAIG sample rate = %.1f Hz\n', ...
    FsCAIG);

fprintf('FOG samples      = %d\n', ...
    NFOG);

fprintf('CAIG samples     = %d\n\n', ...
    NCAIG);

%% ============================================================
% 2. FOG NOISE MODEL
% =============================================================

% EMCORE EG-1300 ARW

ARW_FOG_deg_sqrt_h = ...
    0.002;

N_FOG = ...
    deg2rad(ARW_FOG_deg_sqrt_h) ...
    / sqrt(3600);

% Validated single-sided MATLAB scaling

sigmaFOG = ...
    N_FOG ...
    * sqrt(FsFOG);

varFOG = ...
    sigmaFOG^2;

fprintf('FOG NOISE MODEL\n');
fprintf('--------------------------------------------\n');

fprintf('ARW        = %.6f deg/sqrt(h)\n', ...
    ARW_FOG_deg_sqrt_h);

fprintf('NoiseType  = single-sided\n');

fprintf('N_FOG      = %.6e rad/s/sqrt(Hz)\n', ...
    N_FOG);

fprintf('sigma_FOG  = %.6e rad/s\n', ...
    sigmaFOG);

fprintf('var_FOG    = %.6e (rad/s)^2\n\n', ...
    varFOG);

%% ============================================================
% 3. CAIG NOISE MODEL
% =============================================================

% Tackmann et al. (2012)
%
% Current project equivalent white-noise interpretation.

N_CAIG = ...
    6.1e-7;             % rad/s/sqrt(Hz)

sigmaCAIG = ...
    N_CAIG ...
    * sqrt(FsCAIG/2);

varCAIG = ...
    sigmaCAIG^2;

fprintf('CAIG NOISE MODEL\n');
fprintf('--------------------------------------------\n');

fprintf('N_CAIG     = %.6e rad/s/sqrt(Hz)\n', ...
    N_CAIG);

fprintf('sigma_CAIG = %.6e rad/s\n', ...
    sigmaCAIG);

fprintf('var_CAIG   = %.6e (rad/s)^2\n\n', ...
    varCAIG);

%% ============================================================
% 4. GENERATE STATIONARY FOG WHITE NOISE
% =============================================================

% No physical motion and no deterministic bias.
%
% The imuSensor output therefore contains only the modeled
% gyroscope white noise.

rng(1001,'twister');

paramsFOG = ...
    gyroparams( ...
        'ConstantBias', ...
        zeros(1,3), ...
        ...
        'NoiseDensity', ...
        N_FOG*ones(1,3), ...
        ...
        'NoiseType', ...
        'single-sided');

imuFOG = ...
    imuSensor( ...
        'accel-gyro', ...
        ...
        'SampleRate', ...
        FsFOG, ...
        ...
        'Gyroscope', ...
        paramsFOG);

accelTrue = ...
    zeros(NFOG,3);

omegaTrue = ...
    zeros(NFOG,3);

[~,fogNoise] = ...
    imuFOG( ...
        accelTrue, ...
        omegaTrue);

%% ============================================================
% 5. VERIFY ORIGINAL FOG NOISE
% =============================================================

% Population-variance convention is used here because we are
% comparing directly with the theoretical process variance.

varFOG_emp_axes = ...
    var( ...
        fogNoise, ...
        1, ...
        1);

sigmaFOG_emp_axes = ...
    sqrt(varFOG_emp_axes);

sigmaFOG_emp = ...
    sqrt( ...
        mean(varFOG_emp_axes));

fprintf('ORIGINAL FOG EMPIRICAL NOISE\n');
fprintf('--------------------------------------------\n');

fprintf('X sigma = %.6e rad/s\n', ...
    sigmaFOG_emp_axes(1));

fprintf('Y sigma = %.6e rad/s\n', ...
    sigmaFOG_emp_axes(2));

fprintf('Z sigma = %.6e rad/s\n', ...
    sigmaFOG_emp_axes(3));

fprintf('\nMean-equivalent sigma = %.6e rad/s\n', ...
    sigmaFOG_emp);

fprintf('Theory sigma          = %.6e rad/s\n\n', ...
    sigmaFOG);

%% ============================================================
% 6. CREATE FOG TIMETABLE
% =============================================================

timeFOG = ...
    seconds(tFOG);

TT_FOG = ...
    timetable( ...
        fogNoise(:,1), ...
        fogNoise(:,2), ...
        fogNoise(:,3), ...
        ...
        'RowTimes', ...
        timeFOG, ...
        ...
        'VariableNames',{ ...
            'NoiseX', ...
            'NoiseY', ...
            'NoiseZ'});

%% ============================================================
% 7. GENERATE CAIG WHITE NOISE
% =============================================================

% Use one controlled CAIG realization for all timing offsets.
%
% This allows differences among offsets to be attributed mainly
% to the FOG interpolation behavior.

rng(2001,'twister');

caigNoise = ...
    sigmaCAIG ...
    * randn(NCAIG,3);

%% ============================================================
% 8. TIMING OFFSETS TO TEST
% =============================================================

% Artificial offsets.
%
% These values are simulation choices and are NOT measured
% delays from Zhang.

offsetMs = ...
    [0 2 5 7 10];

offsetSec = ...
    offsetMs/1000;

nOffsets = ...
    length(offsetMs);

% FOG period in milliseconds

FOGperiodMs = ...
    1000/FsFOG;

fprintf('TIMING OFFSETS\n');
fprintf('--------------------------------------------\n');

fprintf('FOG sample interval = %.3f ms\n', ...
    FOGperiodMs);

fprintf('Offsets tested      = ');

fprintf('%.1f ', ...
    offsetMs);

fprintf('ms\n\n');

%% ============================================================
% 9. STORAGE
% =============================================================

alpha_all = ...
    zeros(nOffsets,1);

beta_all = ...
    zeros(nOffsets,1);

sigmaFOG_theory_all = ...
    zeros(nOffsets,1);

sigmaFOG_emp_all = ...
    zeros(nOffsets,1);

sigmaFOG_errorPct_all = ...
    zeros(nOffsets,1);

lag1Corr_all = ...
    zeros(nOffsets,1);

sigmaZ_theory_all = ...
    zeros(nOffsets,1);

sigmaZ_emp_all = ...
    zeros(nOffsets,1);

R_theory_all = ...
    zeros(nOffsets,1);

R_emp_all = ...
    zeros(nOffsets,1);

R_errorPct_all = ...
    zeros(nOffsets,1);

%% ============================================================
% 10. LOOP OVER CAIG CLOCK OFFSETS
% =============================================================

for i = 1:nOffsets

    currentOffset = ...
        offsetSec(i);

    %% --------------------------------------------------------
    % Shift CAIG epochs
    % ---------------------------------------------------------

    tCAIG = ...
        tCAIG0 ...
        + currentOffset;

    timeCAIG = ...
        seconds(tCAIG);

    %% --------------------------------------------------------
    % Linear interpolation using MATLAB timetable
    % ---------------------------------------------------------

    TT_FOG_interp = ...
        retime( ...
            TT_FOG, ...
            timeCAIG, ...
            'linear');

    fogNoiseInterp = ...
        [ ...
            TT_FOG_interp.NoiseX, ...
            TT_FOG_interp.NoiseY, ...
            TT_FOG_interp.NoiseZ ...
        ];

    %% --------------------------------------------------------
    % Interpolation fraction alpha
    % ---------------------------------------------------------

    % Because the offset is constant, every CAIG measurement has
    % the same fractional location inside a FOG sampling period.
    %
    % Example:
    %
    % offset = 5 ms
    % FOG period = 10 ms
    %
    % alpha = 0.5

    alpha = ...
        mod( ...
            offsetMs(i), ...
            FOGperiodMs) ...
        / FOGperiodMs;

    % Numerical cleanup

    if abs(alpha) < 1e-12

        alpha = 0;

    end

    alpha_all(i) = ...
        alpha;

    %% --------------------------------------------------------
    % Analytical interpolation variance factor
    % ---------------------------------------------------------

    % n_interp =
    %
    % (1-alpha)n_k
    %
    % +
    %
    % alpha n_(k+1)
    %
    %
    % Assuming n_k and n_(k+1) are independent:
    %
    % Var(n_interp)
    %
    % =
    %
    % [(1-alpha)^2 + alpha^2] sigma^2

    beta = ...
        (1-alpha)^2 ...
        + alpha^2;

    beta_all(i) = ...
        beta;

    sigmaFOG_theory = ...
        sigmaFOG ...
        * sqrt(beta);

    sigmaFOG_theory_all(i) = ...
        sigmaFOG_theory;

    %% --------------------------------------------------------
    % Empirical interpolated FOG variance
    % ---------------------------------------------------------

    varInterpAxes = ...
        var( ...
            fogNoiseInterp, ...
            1, ...
            1);

    sigmaInterpEmp = ...
        sqrt( ...
            mean(varInterpAxes));

    sigmaFOG_emp_all(i) = ...
        sigmaInterpEmp;

    sigmaFOG_errorPct_all(i) = ...
        100 ...
        * (sigmaInterpEmp-sigmaFOG_theory) ...
        / sigmaFOG_theory;

    %% --------------------------------------------------------
    % Lag-1 temporal correlation
    % ---------------------------------------------------------

    corrAxes = ...
        zeros(1,3);

    for ax = 1:3

        corrAxes(ax) = ...
            lag1Correlation( ...
                fogNoiseInterp(:,ax));

    end

    lag1Corr_all(i) = ...
        mean(corrAxes);

    %% --------------------------------------------------------
    % Observation noise
    % ---------------------------------------------------------

    % In the monitoring observation:
    %
    % Z_noise =
    %
    % FOG_noise_interp
    %
    % -
    %
    % CAIG_noise
    %
    %
    % If FOG and CAIG noise are independent:
    %
    % Var(Z)
    %
    % =
    %
    % Var(FOG_interp)
    %
    % +
    %
    % Var(CAIG)

    observationNoise = ...
        fogNoiseInterp ...
        - caigNoise;

    varZempAxes = ...
        var( ...
            observationNoise, ...
            1, ...
            1);

    varZemp = ...
        mean(varZempAxes);

    sigmaZemp = ...
        sqrt(varZemp);

    %% --------------------------------------------------------
    % Analytical R
    % ---------------------------------------------------------

    varFOGinterpTheory = ...
        beta ...
        * varFOG;

    varZtheory = ...
        varFOGinterpTheory ...
        + varCAIG;

    sigmaZtheory = ...
        sqrt(varZtheory);

    Rtheory = ...
        varZtheory;

    %% --------------------------------------------------------
    % Save observation results
    % ---------------------------------------------------------

    sigmaZ_theory_all(i) = ...
        sigmaZtheory;

    sigmaZ_emp_all(i) = ...
        sigmaZemp;

    R_theory_all(i) = ...
        Rtheory;

    R_emp_all(i) = ...
        varZemp;

    R_errorPct_all(i) = ...
        100 ...
        * (varZemp-Rtheory) ...
        / Rtheory;

end

%% ============================================================
% 11. PRINT OFFSET-BY-OFFSET RESULTS
% =============================================================

fprintf('============================================\n');
fprintf('INTERPOLATION RESULTS\n');
fprintf('============================================\n');

for i = 1:nOffsets

    fprintf('\nOffset = %.1f ms\n', ...
        offsetMs(i));

    fprintf('--------------------------------------------\n');

    fprintf('alpha = %.3f\n', ...
        alpha_all(i));

    fprintf('beta  = %.6f\n', ...
        beta_all(i));

    fprintf('\nFOG interpolated sigma\n');

    fprintf('Theory    = %.6e rad/s\n', ...
        sigmaFOG_theory_all(i));

    fprintf('Empirical = %.6e rad/s\n', ...
        sigmaFOG_emp_all(i));

    fprintf('Error     = %.3f %%\n', ...
        sigmaFOG_errorPct_all(i));

    fprintf('\nEmpirical lag-1 correlation = %.6f\n', ...
        lag1Corr_all(i));

    fprintf('\nObservation sigma_Z\n');

    fprintf('Theory    = %.6e rad/s\n', ...
        sigmaZ_theory_all(i));

    fprintf('Empirical = %.6e rad/s\n', ...
        sigmaZ_emp_all(i));

    fprintf('\nR diagonal\n');

    fprintf('Theory    = %.6e (rad/s)^2\n', ...
        R_theory_all(i));

    fprintf('Empirical = %.6e (rad/s)^2\n', ...
        R_emp_all(i));

    fprintf('Error     = %.3f %%\n', ...
        R_errorPct_all(i));

end

%% ============================================================
% 12. SUMMARY TABLE
% =============================================================

ResultsTable = ...
    table( ...
        offsetMs.', ...
        alpha_all, ...
        beta_all, ...
        sigmaFOG_theory_all, ...
        sigmaFOG_emp_all, ...
        sigmaFOG_errorPct_all, ...
        lag1Corr_all, ...
        sigmaZ_theory_all, ...
        sigmaZ_emp_all, ...
        R_theory_all, ...
        R_emp_all, ...
        R_errorPct_all, ...
        ...
        'VariableNames',{ ...
            'Offset_ms', ...
            'Alpha', ...
            'VarianceFactor_beta', ...
            'SigmaFOG_Theory', ...
            'SigmaFOG_Empirical', ...
            'SigmaFOG_Error_pct', ...
            'Lag1Correlation', ...
            'SigmaZ_Theory', ...
            'SigmaZ_Empirical', ...
            'R_Theory', ...
            'R_Empirical', ...
            'R_Error_pct'});

fprintf('\n============================================\n');
fprintf('SUMMARY TABLE\n');
fprintf('============================================\n\n');

disp(ResultsTable);

%% ============================================================
% 13. IMPORTANT 5-ms CASE
% =============================================================

idx5 = ...
    find(offsetMs == 5,1);

fprintf('============================================\n');
fprintf('SPECIAL CASE - 5 ms OFFSET\n');
fprintf('============================================\n\n');

fprintf('At 5 ms, alpha = %.1f\n', ...
    alpha_all(idx5));

fprintf('Variance factor beta = %.6f\n', ...
    beta_all(idx5));

fprintf('\nTherefore:\n\n');

fprintf('Var(FOG interpolated) = %.3f * Var(FOG original)\n', ...
    beta_all(idx5));

fprintf('sigma_FOG interpolated / sigma_FOG = %.6f\n', ...
    sqrt(beta_all(idx5)));

fprintf('\nEffective FOG sigma = %.6e rad/s\n', ...
    sigmaFOG_theory_all(idx5));

fprintf('Effective R diagonal = %.6e (rad/s)^2\n\n', ...
    R_theory_all(idx5));

%% ============================================================
% 14. DENSE-TARGET CORRELATION DIAGNOSTIC
% =============================================================

% In the actual project:
%
% FOG  = 100 Hz
% CAIG =   5 Hz
%
% Consecutive CAIG epochs are separated by 20 FOG sample
% intervals.
%
% Therefore the two FOG samples used to interpolate one CAIG
% epoch are not reused in the next CAIG epoch.
%
% We therefore expect approximately ZERO interpolation-induced
% lag-1 correlation in the actual 5-Hz CAIG sequence.
%
%
% However, interpolation CAN create temporal correlation when
% adjacent interpolated outputs share source samples.
%
% To demonstrate this separately, create a diagnostic target
% also running at 100 Hz, shifted by 5 ms.

denseOffset = ...
    0.005;              % [s]

% Stop one sample early to avoid extrapolation at the end.

tDense = ...
    (0:dtFOG:duration-2*dtFOG).' ...
    + denseOffset;

TT_FOG_dense = ...
    retime( ...
        TT_FOG, ...
        seconds(tDense), ...
        'linear');

fogDense = ...
    [ ...
        TT_FOG_dense.NoiseX, ...
        TT_FOG_dense.NoiseY, ...
        TT_FOG_dense.NoiseZ ...
    ];

denseCorrAxes = ...
    zeros(1,3);

for ax = 1:3

    denseCorrAxes(ax) = ...
        lag1Correlation( ...
            fogDense(:,ax));

end

denseCorrEmp = ...
    mean(denseCorrAxes);

% For alpha = 0.5:
%
% y_k     = 0.5 n_k + 0.5 n_(k+1)
%
% y_(k+1) = 0.5 n_(k+1) + 0.5 n_(k+2)
%
% They share n_(k+1).
%
% Cov(y_k,y_(k+1)) = alpha(1-alpha)sigma^2
%
% therefore:
%
% rho_1 =
%
% alpha(1-alpha)
% -------------------------
% (1-alpha)^2 + alpha^2

alphaDense = ...
    0.5;

betaDense = ...
    (1-alphaDense)^2 ...
    + alphaDense^2;

denseCorrTheory = ...
    alphaDense ...
    * (1-alphaDense) ...
    / betaDense;

fprintf('============================================\n');
fprintf('DENSE-TARGET CORRELATION DIAGNOSTIC\n');
fprintf('============================================\n\n');

fprintf('This is NOT the 5-Hz CAIG architecture.\n');
fprintf('It is only a diagnostic demonstration.\n\n');

fprintf('Target rate = %.1f Hz\n', ...
    FsFOG);

fprintf('Offset      = %.3f ms\n', ...
    denseOffset*1000);

fprintf('Theory lag-1 correlation    = %.6f\n', ...
    denseCorrTheory);

fprintf('Empirical lag-1 correlation = %.6f\n\n', ...
    denseCorrEmp);

%% ============================================================
% 15. PLOT - INTERPOLATED FOG SIGMA
% =============================================================

figure;

plot( ...
    offsetMs, ...
    sigmaFOG_theory_all, ...
    '-o', ...
    'LineWidth',1.2);

hold on;

plot( ...
    offsetMs, ...
    sigmaFOG_emp_all, ...
    '--o', ...
    'LineWidth',1.2);

yline( ...
    sigmaFOG, ...
    ':');

xlabel('CAIG clock offset [ms]');
ylabel('FOG noise standard deviation [rad/s]');

title('FOG Noise After Linear Interpolation');

legend( ...
    'Analytical', ...
    'Empirical', ...
    'Original FOG sigma', ...
    'Location','best');

grid on;

%% ============================================================
% 16. PLOT - OBSERVATION COVARIANCE
% =============================================================

figure;

plot( ...
    offsetMs, ...
    R_theory_all, ...
    '-o', ...
    'LineWidth',1.2);

hold on;

plot( ...
    offsetMs, ...
    R_emp_all, ...
    '--o', ...
    'LineWidth',1.2);

xlabel('CAIG clock offset [ms]');
ylabel('R diagonal [(rad/s)^2]');

title('Observation Covariance After FOG Interpolation');

legend( ...
    'Analytical', ...
    'Empirical', ...
    'Location','best');

grid on;

%% ============================================================
% 17. PLOT - LAG-1 CORRELATION
% =============================================================

figure;

plot( ...
    offsetMs, ...
    lag1Corr_all, ...
    '-o', ...
    'LineWidth',1.2);

yline( ...
    0, ...
    '--');

xlabel('CAIG clock offset [ms]');
ylabel('Empirical lag-1 correlation');

title('Interpolated FOG Noise Correlation at 5-Hz CAIG Epochs');

grid on;

%% ============================================================
% LOCAL FUNCTION
% =============================================================

function rho = lag1Correlation(x)

    % Empirical lag-1 correlation coefficient.
    %
    % Uses corrcoef so that no additional toolbox-specific
    % autocorrelation function is required.

    x = ...
        x(:);

    x1 = ...
        x(1:end-1);

    x2 = ...
        x(2:end);

    C = ...
        corrcoef(x1,x2);

    rho = ...
        C(1,2);

end