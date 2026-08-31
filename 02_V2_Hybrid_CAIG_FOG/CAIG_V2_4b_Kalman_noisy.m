%% CAIG_V2_4b_Kalman_noisy.m
%
% Hybrid CAIG + FOG monitoring simulation with measurement noise
% and a six-state Kalman filter.
%
% Main architecture:
%   Zhang et al. (2019)
%   "A Novel Monitoring Navigation Method for Cold Atom
%   Interference Gyroscope"
%
% State vector:
%
%   X = [phi_x phi_y phi_z eps_Fx eps_Fy eps_Fz]^T
%
% where:
%   phi     = CAIG/FOG frame misalignment
%   eps_F   = FOG constant bias
%
% IMPORTANT NOISE MODEL UPDATE
% ----------------------------
%
% FOG:
%   EMCORE EG-1300 ARW = 0.002 deg/sqrt(h)
%
%   The ARW is modeled using:
%
%       NoiseType = 'single-sided'
%
%   which is consistent with the MathWorks Allan-variance
%   parameter-scaling workflow.
%
%   Therefore:
%
%       sigma_FOG = N_FOG * sqrt(Fs_FOG)
%
%
% CAIG:
%   Tackmann et al. (2012) rotation sensitivity:
%
%       6.1e-7 rad/s/sqrt(Hz)
%
%   This is treated as an equivalent short-term white
%   angular-rate output noise level.
%
%   Current project modeling convention:
%
%       sigma_CAIG = N_CAIG * sqrt(Fs_CAIG/2)
%
%   This interpretation is a modeling assumption and was
%   evaluated separately in the CAIG noise sensitivity study.
%
%
% The purpose of this script is NOT to reproduce every
% experimental noise source of a real CAIG/FOG system.
%
% It extends the structurally validated V2.4a model by adding
% experimentally motivated white measurement noise.

clear;
clc;
close all;

rng default;

%% ============================================================
% 1. GENERAL SETTINGS
% =============================================================

duration = 120;       % [s] simulation choice

FsFOG  = 100;         % [Hz] Zhang
FsCAIG = 5;           % [Hz] Zhang

dtFOG  = 1/FsFOG;
dtCAIG = 1/FsCAIG;

tFOG = ...
    (0:dtFOG:duration-dtFOG).';

tCAIG = ...
    (0:dtCAIG:duration-dtCAIG).';

NFOG  = length(tFOG);
NCAIG = length(tCAIG);

sampleRatio = FsFOG/FsCAIG;

assert( ...
    mod(sampleRatio,1) == 0, ...
    'FOG/CAIG sample-rate ratio must be integer.');

idxCAIGinFOG = ...
    1:sampleRatio:NFOG;


fprintf('============================================\n');
fprintf('CAIG V2.4b - NOISY KALMAN FILTER\n');
fprintf('============================================\n\n');

fprintf('Simulation duration = %.1f s\n', duration);
fprintf('FOG sample rate     = %.1f Hz\n', FsFOG);
fprintf('CAIG sample rate    = %.1f Hz\n', FsCAIG);
fprintf('FOG / CAIG ratio    = %.0f\n\n', sampleRatio);

%% ============================================================
% 2. ZHANG LEVEL-2 TRIAXIAL SWAY
% =============================================================

% Zhang provides the level-2 roll/pitch/heading amplitudes
% and periods, but not the exact time-domain waveform.
%
% Sinusoidal attitude motion is therefore a simulation
% assumption.

OmegaA_FOG = ...
    generateLevel2Sway(tFOG);

OmegaA_CAIG = ...
    generateLevel2Sway(tCAIG);


fprintf('Maximum true body angular rates\n');

fprintf('X = %.6f deg/s\n', ...
    max(abs(rad2deg(OmegaA_CAIG(:,1)))));

fprintf('Y = %.6f deg/s\n', ...
    max(abs(rad2deg(OmegaA_CAIG(:,2)))));

fprintf('Z = %.6f deg/s\n\n', ...
    max(abs(rad2deg(OmegaA_CAIG(:,3)))));

%% ============================================================
% 3. TRUE CAIG / FOG FRAME MISALIGNMENT
% =============================================================

% Zhang simulation values

phiTrueDeg = [ ...
    1;
    2;
    3];

phiTrue = ...
    deg2rad(phiTrueDeg);

% Cross-product matrix [phi x]

phiSkew = ...
    skewMatrix(phiTrue);

% Zhang first-order frame transformation:
%
%       C_A^F = I - [phi x]

C_A_F = ...
    eye(3) - phiSkew;

% Ground-truth angular rate expressed in FOG frame

OmegaF_true = ...
    (C_A_F * OmegaA_FOG.').';

%% ============================================================
% 4. TRUE FOG CONSTANT BIAS
% =============================================================

% Zhang:
%
% FOG bias = 0.1 deg/h
% CAIG bias assumed negligible

biasFOG_deg_h = 0.1;

biasFOG = ...
    deg2rad(biasFOG_deg_h)/3600;     % [rad/s]

biasFOGvec = ...
    biasFOG * ones(1,3);


fprintf('True FOG bias\n');

fprintf('= %.6f deg/h\n', ...
    biasFOG_deg_h);

fprintf('= %.6e rad/s\n\n', ...
    biasFOG);

%% ============================================================
% 5. FOG WHITE NOISE
% =============================================================

% EMCORE EG-1300
%
% Angle Random Walk:
%
%       0.002 deg/sqrt(h)

ARW_FOG_deg_sqrt_h = ...
    0.002;

% Convert:
%
% deg/sqrt(h)
%
%       ->
%
% rad/sqrt(s)
%
% which is dimensionally equivalent to
%
% (rad/s)/sqrt(Hz)

N_FOG = ...
    deg2rad(ARW_FOG_deg_sqrt_h) ...
    / sqrt(3600);


% ------------------------------------------------------------
% IMPORTANT CORRECTION
% ------------------------------------------------------------
%
% The FOG ARW is now modeled using the single-sided
% gyroparams convention.
%
% This is consistent with the MathWorks Allan-variance
% parameter-scaling workflow that we validated separately.
%
% Therefore:
%
%       sigma = N * sqrt(Fs)
%

sigmaFOG = ...
    N_FOG * sqrt(FsFOG);


fprintf('FOG NOISE MODEL\n');
fprintf('--------------------------------------------\n');

fprintf('ARW = %.6f deg/sqrt(h)\n', ...
    ARW_FOG_deg_sqrt_h);

fprintf('NoiseDensity = %.6e rad/s/sqrt(Hz)\n', ...
    N_FOG);

fprintf('NoiseType = single-sided\n');

fprintf('Expected sample sigma = %.6e rad/s\n\n', ...
    sigmaFOG);

%% ============================================================
% 6. CREATE FOG USING MATLAB imuSensor
% =============================================================

paramsFOG = ...
    gyroparams( ...
        'ConstantBias', ...
        biasFOGvec, ...
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


% No accelerometer dynamics are required in this simulation.
%
% imuSensor still requires accelerometer input because we use
% the accel-gyro configuration.

accelDummy = ...
    zeros(NFOG,3);


[~, OmegaFOG] = ...
    imuFOG( ...
        accelDummy, ...
        OmegaF_true);


% FOG measurement model:
%
% OmegaFOG =
% OmegaF_true
% + biasFOG
% + white noise

%% ============================================================
% 7. VERIFY FOG NOISE
% =============================================================

fogDeterministic = ...
    OmegaF_true ...
    + repmat(biasFOGvec,NFOG,1);

fogNoiseMeasured = ...
    OmegaFOG ...
    - fogDeterministic;


sigmaFOG_empirical = ...
    std(fogNoiseMeasured,0,1);


fprintf('Empirical FOG white-noise std\n');

fprintf('X = %.6e rad/s\n', ...
    sigmaFOG_empirical(1));

fprintf('Y = %.6e rad/s\n', ...
    sigmaFOG_empirical(2));

fprintf('Z = %.6e rad/s\n\n', ...
    sigmaFOG_empirical(3));

%% ============================================================
% 8. CAIG WHITE NOISE
% =============================================================

% Tackmann et al. (2012):
%
% reported rotation sensitivity:
%
%       6.1e-7 rad/s/sqrt(Hz)
%
% We use this as an equivalent short-term white angular-rate
% noise level.
%
% IMPORTANT:
% This interpretation is a project modeling assumption.

N_CAIG = ...
    6.1e-7;       % [rad/s]/sqrt(Hz)


% Current project baseline mapping.
%
% This convention was tested separately against the
% N*sqrt(Fs) alternative.
%
% The Kalman results changed only by a few percent because
% FOG noise dominates the observation covariance.

sigmaCAIG = ...
    N_CAIG * sqrt(FsCAIG/2);


fprintf('CAIG NOISE MODEL\n');
fprintf('--------------------------------------------\n');

fprintf('Equivalent sensitivity = %.6e rad/s/sqrt(Hz)\n', ...
    N_CAIG);

fprintf('Expected sample sigma  = %.6e rad/s\n\n', ...
    sigmaCAIG);


% Generate independent CAIG white noise

caigNoise = ...
    sigmaCAIG * randn(NCAIG,3);


OmegaCAIG = ...
    OmegaA_CAIG ...
    + caigNoise;


sigmaCAIG_empirical = ...
    std( ...
        OmegaCAIG - OmegaA_CAIG, ...
        0, ...
        1);


fprintf('Empirical CAIG white-noise std\n');

fprintf('X = %.6e rad/s\n', ...
    sigmaCAIG_empirical(1));

fprintf('Y = %.6e rad/s\n', ...
    sigmaCAIG_empirical(2));

fprintf('Z = %.6e rad/s\n\n', ...
    sigmaCAIG_empirical(3));

%% ============================================================
% 9. SYNCHRONIZE FOG WITH CAIG EPOCHS
% =============================================================

% Current baseline:
%
% The CAIG epochs are exactly aligned with every twentieth
% FOG sample.
%
% More general timetable/retime synchronization will be
% introduced in a later implementation.

OmegaFOGatCAIG = ...
    OmegaFOG(idxCAIGinFOG,:);


tFOGatCAIG = ...
    tFOG(idxCAIGinFOG);


syncError = ...
    max(abs(tFOGatCAIG - tCAIG));


fprintf('Timestamp synchronization error\n');

fprintf('%.6e s\n\n', ...
    syncError);

%% ============================================================
% 10. MONITORING OBSERVATION
% =============================================================

% Zhang monitoring observation:
%
%       deltaOmega =
%       Omega_FOG - Omega_CAIG
%
%
% Simplified first-order model:
%
%       deltaOmega =
%       [Omega_A x] phi
%       + epsilon_F
%       + measurement noise

deltaOmega = ...
    OmegaFOGatCAIG ...
    - OmegaCAIG;

%% ============================================================
% 11. OBSERVATION NOISE COVARIANCE
% =============================================================

% Assume independent FOG and CAIG white noise.
%
% Therefore:
%
% sigma_Z^2 =
%
% sigma_FOG^2
% +
% sigma_CAIG^2

sigmaZ = ...
    sqrt( ...
        sigmaFOG^2 ...
        + sigmaCAIG^2);


R = ...
    sigmaZ^2 * eye(3);


fprintf('OBSERVATION NOISE\n');
fprintf('--------------------------------------------\n');

fprintf('sigma_FOG  = %.6e rad/s\n', ...
    sigmaFOG);

fprintf('sigma_CAIG = %.6e rad/s\n', ...
    sigmaCAIG);

fprintf('sigma_Z    = %.6e rad/s\n', ...
    sigmaZ);

fprintf('R diagonal = %.6e (rad/s)^2\n\n', ...
    R(1,1));

%% ============================================================
% 12. KALMAN STATE DEFINITION
% =============================================================

% Zhang Eq. (14):
%
% X =
%
% [ phi_x
%   phi_y
%   phi_z
%   eps_Fx
%   eps_Fy
%   eps_Fz ]

X0 = ...
    zeros(6,1);


% Zhang initial covariance

phiStd0 = ...
    deg2rad([ ...
        1;
        2;
        3]);


biasStd0 = ...
    deg2rad([ ...
        0.1;
        0.1;
        0.1]) ...
    /3600;


initialStd = ...
    [ ...
        phiStd0;
        biasStd0];


P0 = ...
    diag(initialStd.^2);


% States are modeled as constant:
%
%       X_k = X_(k-1)

Phi = ...
    eye(6);


% No process noise in the current model because the injected
% misalignment and bias are constant.
%
% Q = 0 is therefore a simulation-model assumption.

Q = ...
    zeros(6);

%% ============================================================
% 13. STORAGE
% =============================================================

XhatHistory = ...
    zeros(NCAIG,6);

PdiagHistory = ...
    zeros(NCAIG,6);

innovationHistory = ...
    zeros(NCAIG,3);

%% ============================================================
% 14. INITIALIZE KALMAN FILTER
% =============================================================

Xhat = ...
    X0;

P = ...
    P0;

I6 = ...
    eye(6);

%% ============================================================
% 15. KALMAN FILTER
% =============================================================

for k = 1:NCAIG

    %% --------------------------------------------------------
    % Prediction
    % ---------------------------------------------------------

    Xpred = ...
        Phi * Xhat;


    Ppred = ...
        Phi * P * Phi.' ...
        + Q;


    %% --------------------------------------------------------
    % Measurement matrix
    % ---------------------------------------------------------

    % IMPORTANT:
    %
    % H uses the true simulation angular rate.
    %
    % This intentionally isolates the Zhang linear observation
    % model and avoids an errors-in-variables problem that would
    % occur if noisy CAIG measurements were used directly in H.

    omega = ...
        OmegaA_CAIG(k,:).';


    H = ...
        [ ...
            skewMatrix(omega), ...
            eye(3) ...
        ];


    %% --------------------------------------------------------
    % Innovation
    % ---------------------------------------------------------

    z = ...
        deltaOmega(k,:).';


    innovation = ...
        z ...
        - H*Xpred;


    innovationHistory(k,:) = ...
        innovation.';


    %% --------------------------------------------------------
    % Innovation covariance
    % ---------------------------------------------------------

    S = ...
        H*Ppred*H.' ...
        + R;


    %% --------------------------------------------------------
    % Kalman gain
    % ---------------------------------------------------------

    K = ...
        Ppred*H.' / S;


    %% --------------------------------------------------------
    % State update
    % ---------------------------------------------------------

    Xhat = ...
        Xpred ...
        + K*innovation;


    %% --------------------------------------------------------
    % Joseph covariance update
    % ---------------------------------------------------------

    P = ...
        (I6-K*H) ...
        * Ppred ...
        * (I6-K*H).' ...
        ...
        + K*R*K.';


    %% --------------------------------------------------------
    % Store
    % ---------------------------------------------------------

    XhatHistory(k,:) = ...
        Xhat.';


    PdiagHistory(k,:) = ...
        diag(P).';

end

%% ============================================================
% 16. FINAL ESTIMATES
% =============================================================

phiEstimatedDeg = ...
    rad2deg(Xhat(1:3));


biasEstimatedDeg_h = ...
    rad2deg(Xhat(4:6))*3600;


phiErrorDeg = ...
    phiEstimatedDeg ...
    - phiTrueDeg;


biasTrueDeg_h_vec = ...
    biasFOG_deg_h*ones(3,1);


biasErrorDeg_h = ...
    biasEstimatedDeg_h ...
    - biasTrueDeg_h_vec;


fprintf('============================================\n');
fprintf('FINAL KALMAN ESTIMATES\n');
fprintf('============================================\n\n');

fprintf('MISALIGNMENT\n');
fprintf('--------------------------------------------\n');

fprintf('X true      = %.6f deg\n', phiTrueDeg(1));
fprintf('X estimated = %.6f deg\n', phiEstimatedDeg(1));
fprintf('X error     = %.6f deg\n\n', phiErrorDeg(1));

fprintf('Y true      = %.6f deg\n', phiTrueDeg(2));
fprintf('Y estimated = %.6f deg\n', phiEstimatedDeg(2));
fprintf('Y error     = %.6f deg\n\n', phiErrorDeg(2));

fprintf('Z true      = %.6f deg\n', phiTrueDeg(3));
fprintf('Z estimated = %.6f deg\n', phiEstimatedDeg(3));
fprintf('Z error     = %.6f deg\n\n', phiErrorDeg(3));


fprintf('FOG BIAS\n');
fprintf('--------------------------------------------\n');

fprintf('X true      = %.6f deg/h\n', ...
    biasFOG_deg_h);

fprintf('X estimated = %.6f deg/h\n', ...
    biasEstimatedDeg_h(1));

fprintf('X error     = %.6f deg/h\n\n', ...
    biasErrorDeg_h(1));


fprintf('Y true      = %.6f deg/h\n', ...
    biasFOG_deg_h);

fprintf('Y estimated = %.6f deg/h\n', ...
    biasEstimatedDeg_h(2));

fprintf('Y error     = %.6f deg/h\n\n', ...
    biasErrorDeg_h(2));


fprintf('Z true      = %.6f deg/h\n', ...
    biasFOG_deg_h);

fprintf('Z estimated = %.6f deg/h\n', ...
    biasEstimatedDeg_h(3));

fprintf('Z error     = %.6f deg/h\n\n', ...
    biasErrorDeg_h(3));

%% ============================================================
% 17. CONVERT HISTORY TO PRACTICAL UNITS
% =============================================================

phiHistoryDeg = ...
    rad2deg( ...
        XhatHistory(:,1:3));


biasHistoryDeg_h = ...
    rad2deg( ...
        XhatHistory(:,4:6)) ...
    *3600;


phiSigmaDeg = ...
    rad2deg( ...
        sqrt(PdiagHistory(:,1:3)));


biasSigmaDeg_h = ...
    rad2deg( ...
        sqrt(PdiagHistory(:,4:6))) ...
    *3600;

%% ============================================================
% 18. MISALIGNMENT PLOTS
% =============================================================

figure;

subplot(3,1,1);

plot( ...
    tCAIG, ...
    phiHistoryDeg(:,1), ...
    'LineWidth',1.2);

hold on;

yline( ...
    phiTrueDeg(1), ...
    '--');

xlabel('Time [s]');
ylabel('\phi_x [deg]');
title('Estimated CAIG/FOG Misalignment');
grid on;


subplot(3,1,2);

plot( ...
    tCAIG, ...
    phiHistoryDeg(:,2), ...
    'LineWidth',1.2);

hold on;

yline( ...
    phiTrueDeg(2), ...
    '--');

xlabel('Time [s]');
ylabel('\phi_y [deg]');
grid on;


subplot(3,1,3);

plot( ...
    tCAIG, ...
    phiHistoryDeg(:,3), ...
    'LineWidth',1.2);

hold on;

yline( ...
    phiTrueDeg(3), ...
    '--');

xlabel('Time [s]');
ylabel('\phi_z [deg]');
grid on;

%% ============================================================
% 19. FOG BIAS PLOTS
% =============================================================

figure;

subplot(3,1,1);

plot( ...
    tCAIG, ...
    biasHistoryDeg_h(:,1), ...
    'LineWidth',1.2);

hold on;

yline( ...
    biasFOG_deg_h, ...
    '--');

xlabel('Time [s]');
ylabel('\epsilon_{Fx} [deg/h]');
title('Estimated FOG Bias');
grid on;


subplot(3,1,2);

plot( ...
    tCAIG, ...
    biasHistoryDeg_h(:,2), ...
    'LineWidth',1.2);

hold on;

yline( ...
    biasFOG_deg_h, ...
    '--');

xlabel('Time [s]');
ylabel('\epsilon_{Fy} [deg/h]');
grid on;


subplot(3,1,3);

plot( ...
    tCAIG, ...
    biasHistoryDeg_h(:,3), ...
    'LineWidth',1.2);

hold on;

yline( ...
    biasFOG_deg_h, ...
    '--');

xlabel('Time [s]');
ylabel('\epsilon_{Fz} [deg/h]');
grid on;

%% ============================================================
% 20. OBSERVATION PLOT
% =============================================================

figure;

subplot(3,1,1);

plot( ...
    tCAIG, ...
    rad2deg(deltaOmega(:,1))*3600);

xlabel('Time [s]');
ylabel('\delta\omega_x [deg/h]');
title('CAIG - FOG Monitoring Observation');
grid on;


subplot(3,1,2);

plot( ...
    tCAIG, ...
    rad2deg(deltaOmega(:,2))*3600);

xlabel('Time [s]');
ylabel('\delta\omega_y [deg/h]');
grid on;


subplot(3,1,3);

plot( ...
    tCAIG, ...
    rad2deg(deltaOmega(:,3))*3600);

xlabel('Time [s]');
ylabel('\delta\omega_z [deg/h]');
grid on;

%% ============================================================
% 21. LOCAL FUNCTIONS
% =============================================================

function Omega = generateLevel2Sway(t)

    % Zhang level-2 triaxial sway:
    %
    % Roll:
    %   amplitude = 0.50 deg
    %   period    = 20 s
    %
    % Pitch:
    %   amplitude = 0.20 deg
    %   period    = 30 s
    %
    % Heading:
    %   amplitude = 0.30 deg
    %   period    = 30 s
    %
    % Zhang provides amplitudes and periods but not the exact
    % time-domain functions.
    %
    % Sinusoidal waveforms are therefore a simulation choice.

    rollAmp = ...
        deg2rad(0.50);

    pitchAmp = ...
        deg2rad(0.20);

    headingAmp = ...
        deg2rad(0.30);


    rollPeriod = ...
        20;

    pitchPeriod = ...
        30;

    headingPeriod = ...
        30;


    wr = ...
        2*pi/rollPeriod;

    wp = ...
        2*pi/pitchPeriod;

    wh = ...
        2*pi/headingPeriod;


    roll = ...
        rollAmp*sin(wr*t);

    pitch = ...
        pitchAmp*sin(wp*t);


    rollDot = ...
        rollAmp*wr*cos(wr*t);

    pitchDot = ...
        pitchAmp*wp*cos(wp*t);

    headingDot = ...
        headingAmp*wh*cos(wh*t);


    % 3-2-1 Euler-angle rates -> body angular rates
    %
    % p = phidot - psidot*sin(theta)
    %
    % q = thetadot*cos(phi)
    %     + psidot*sin(phi)*cos(theta)
    %
    % r = -thetadot*sin(phi)
    %     + psidot*cos(phi)*cos(theta)

    p = ...
        rollDot ...
        - headingDot.*sin(pitch);


    q = ...
        pitchDot.*cos(roll) ...
        + headingDot.*sin(roll).*cos(pitch);


    r = ...
        -pitchDot.*sin(roll) ...
        + headingDot.*cos(roll).*cos(pitch);


    Omega = ...
        [p q r];

end


function S = skewMatrix(v)

    % Return [v x] such that:
    %
    %       [v x] a = v x a

    v = ...
        v(:);


    S = [ ...
         0,     -v(3),   v(2);
         v(3),   0,     -v(1);
        -v(2),   v(1),   0];

end