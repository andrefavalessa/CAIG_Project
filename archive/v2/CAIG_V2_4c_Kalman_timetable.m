%% CAIG_V2_4c_Kalman_timetable.m
%
% Hybrid CAIG + FOG monitoring simulation using MATLAB timetable
% synchronization and the six-state Kalman filter from the
% Zhang et al. (2019) architecture.
%
% Main difference relative to V2.4b:
%
% OLD:
%   OmegaFOG(1:20:end,:)
%
% NEW:
%   timetable + retime
%
% The scientific model is intentionally unchanged.
%
% State:
%
%   X = [phi_x phi_y phi_z eps_Fx eps_Fy eps_Fz]^T
%
% FOG:
%   EMCORE EG-1300
%   ARW = 0.002 deg/sqrt(h)
%   NoiseType = 'single-sided'
%
% CAIG:
%   Tackmann et al. (2012)
%   equivalent short-term sensitivity:
%   6.1e-7 rad/s/sqrt(Hz)
%
% Current CAIG mapping:
%
%   sigma_CAIG = N_CAIG * sqrt(Fs_CAIG/2)
%
% Synchronization:
%
%   FOG measurements are stored in a timetable and retimed
%   explicitly to the CAIG timestamps.
%
% For this baseline test, both clocks are perfectly aligned.
% Therefore retime should reproduce the old manual indexing
% to numerical precision.

clear;
clc;
close all;

rng default;

%% ============================================================
% 1. GENERAL SETTINGS
% =============================================================

duration = 120;       % [s]

FsFOG  = 100;         % [Hz] Zhang
FsCAIG = 5;           % [Hz] Zhang

dtFOG  = 1/FsFOG;
dtCAIG = 1/FsCAIG;

tFOG = ...
    (0:dtFOG:duration-dtFOG).';

tCAIG = ...
    (0:dtCAIG:duration-dtCAIG).';

NFOG = ...
    length(tFOG);

NCAIG = ...
    length(tCAIG);

sampleRatio = ...
    FsFOG/FsCAIG;

assert( ...
    mod(sampleRatio,1) == 0, ...
    'FOG/CAIG sample-rate ratio must be integer.');

fprintf('============================================\n');
fprintf('CAIG V2.4c - KALMAN + TIMETABLE\n');
fprintf('============================================\n\n');

fprintf('Simulation duration = %.1f s\n',duration);
fprintf('FOG sample rate     = %.1f Hz\n',FsFOG);
fprintf('CAIG sample rate    = %.1f Hz\n',FsCAIG);
fprintf('FOG / CAIG ratio    = %.0f\n\n',sampleRatio);

%% ============================================================
% 2. ZHANG LEVEL-2 TRIAXIAL SWAY
% =============================================================

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
% 3. TRUE MISALIGNMENT
% =============================================================

phiTrueDeg = ...
    [1;2;3];

phiTrue = ...
    deg2rad(phiTrueDeg);

phiSkew = ...
    skewMatrix(phiTrue);

% Zhang first-order transformation
%
% C_A^F = I - [phi x]

C_A_F = ...
    eye(3) - phiSkew;

OmegaF_true = ...
    (C_A_F * OmegaA_FOG.').';

%% ============================================================
% 4. TRUE FOG CONSTANT BIAS
% =============================================================

biasFOG_deg_h = ...
    0.1;

biasFOG = ...
    deg2rad(biasFOG_deg_h)/3600;

biasFOGvec = ...
    biasFOG*ones(1,3);

fprintf('True FOG bias\n');

fprintf('= %.6f deg/h\n', ...
    biasFOG_deg_h);

fprintf('= %.6e rad/s\n\n', ...
    biasFOG);

%% ============================================================
% 5. FOG WHITE NOISE
% =============================================================

% EMCORE EG-1300 ARW

ARW_FOG_deg_sqrt_h = ...
    0.002;

N_FOG = ...
    deg2rad(ARW_FOG_deg_sqrt_h) ...
    / sqrt(3600);

% Allan-variance validated MATLAB scaling

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
% 6. MATLAB imuSensor FOG
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

accelDummy = ...
    zeros(NFOG,3);

[~,OmegaFOG] = ...
    imuFOG( ...
        accelDummy, ...
        OmegaF_true);

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

% Tackmann et al. (2012)
%
% Equivalent short-term rotation sensitivity.

N_CAIG = ...
    6.1e-7;       % rad/s/sqrt(Hz)

% Current project baseline assumption

sigmaCAIG = ...
    N_CAIG * sqrt(FsCAIG/2);

fprintf('CAIG NOISE MODEL\n');
fprintf('--------------------------------------------\n');

fprintf('Equivalent sensitivity = %.6e rad/s/sqrt(Hz)\n', ...
    N_CAIG);

fprintf('Expected sample sigma  = %.6e rad/s\n\n', ...
    sigmaCAIG);

caigNoise = ...
    sigmaCAIG ...
    * randn(NCAIG,3);

OmegaCAIG = ...
    OmegaA_CAIG ...
    + caigNoise;

sigmaCAIG_empirical = ...
    std( ...
        OmegaCAIG-OmegaA_CAIG, ...
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
% 9. CREATE SENSOR TIMETABLES
% =============================================================

% Convert simulation seconds to MATLAB duration row times.

timeFOG = ...
    seconds(tFOG);

timeCAIG = ...
    seconds(tCAIG);

TT_FOG = ...
    timetable( ...
        OmegaFOG(:,1), ...
        OmegaFOG(:,2), ...
        OmegaFOG(:,3), ...
        ...
        'RowTimes',timeFOG, ...
        ...
        'VariableNames',{ ...
            'OmegaX', ...
            'OmegaY', ...
            'OmegaZ'});

TT_CAIG = ...
    timetable( ...
        OmegaCAIG(:,1), ...
        OmegaCAIG(:,2), ...
        OmegaCAIG(:,3), ...
        ...
        'RowTimes',timeCAIG, ...
        ...
        'VariableNames',{ ...
            'OmegaX', ...
            'OmegaY', ...
            'OmegaZ'});

fprintf('TIMETABLES\n');
fprintf('--------------------------------------------\n');

fprintf('FOG rows  = %d\n', ...
    height(TT_FOG));

fprintf('CAIG rows = %d\n\n', ...
    height(TT_CAIG));

%% ============================================================
% 10. RETIME FOG TO CAIG EPOCHS
% =============================================================

% Core architectural change:
%
% Instead of relying on sample numbers, explicitly evaluate
% the FOG stream at the CAIG timestamps.

TT_FOG_at_CAIG = ...
    retime( ...
        TT_FOG, ...
        TT_CAIG.Properties.RowTimes, ...
        'linear');

OmegaFOGatCAIG = ...
    [ ...
        TT_FOG_at_CAIG.OmegaX, ...
        TT_FOG_at_CAIG.OmegaY, ...
        TT_FOG_at_CAIG.OmegaZ ...
    ];

%% ============================================================
% 11. VALIDATE AGAINST OLD MANUAL METHOD
% =============================================================

% Manual indexing is retained ONLY for this validation.
%
% It is not used by the Kalman path below.

idxManual = ...
    1:sampleRatio:NFOG;

OmegaFOG_manual = ...
    OmegaFOG(idxManual,:);

methodDifference = ...
    OmegaFOGatCAIG ...
    - OmegaFOG_manual;

maxMethodDifference = ...
    max(abs(methodDifference),[],1);

fprintf('TIMETABLE vs OLD 1:20:end\n');
fprintf('--------------------------------------------\n');

fprintf('Maximum difference\n');

fprintf('X = %.6e rad/s\n', ...
    maxMethodDifference(1));

fprintf('Y = %.6e rad/s\n', ...
    maxMethodDifference(2));

fprintf('Z = %.6e rad/s\n\n', ...
    maxMethodDifference(3));

%% ============================================================
% 12. TIMESTAMP CHECK
% =============================================================

timeDifference = ...
    TT_FOG_at_CAIG.Properties.RowTimes ...
    - TT_CAIG.Properties.RowTimes;

maxTimeDifference = ...
    max(abs(seconds(timeDifference)));

fprintf('Maximum timestamp difference\n');

fprintf('%.6e s\n\n', ...
    maxTimeDifference);

%% ============================================================
% 13. MONITORING OBSERVATION
% =============================================================

% Zhang monitoring observation:
%
% deltaOmega =
%
% FOG - CAIG

deltaOmega = ...
    OmegaFOGatCAIG ...
    - OmegaCAIG;

%% ============================================================
% 14. OBSERVATION NOISE COVARIANCE
% =============================================================

% Sensors are independent.
%
% Because the clocks are exactly aligned in this baseline,
% retime selects existing FOG samples and does not alter
% the FOG noise variance.

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
% 15. KALMAN INITIAL CONDITIONS
% =============================================================

X0 = ...
    zeros(6,1);

% Zhang initial covariance values

phiStd0 = ...
    deg2rad([1;2;3]);

biasStd0 = ...
    deg2rad([0.1;0.1;0.1]) ...
    /3600;

P0 = ...
    diag( ...
        [phiStd0;biasStd0].^2);

Phi = ...
    eye(6);

% Constant-state model

Q = ...
    zeros(6);

%% ============================================================
% 16. STORAGE
% =============================================================

XhatHistory = ...
    zeros(NCAIG,6);

PdiagHistory = ...
    zeros(NCAIG,6);

innovationHistory = ...
    zeros(NCAIG,3);

%% ============================================================
% 17. INITIALIZE FILTER
% =============================================================

Xhat = ...
    X0;

P = ...
    P0;

I6 = ...
    eye(6);

%% ============================================================
% 18. KALMAN FILTER
% =============================================================

for k = 1:NCAIG

    % --------------------------------------------------------
    % Prediction
    % ---------------------------------------------------------

    Xpred = ...
        Phi*Xhat;

    Ppred = ...
        Phi*P*Phi.' ...
        + Q;

    % --------------------------------------------------------
    % Measurement matrix
    % --------------------------------------------------------

    % True simulated angular rate is intentionally used in H
    % to isolate the Zhang linear observation model from
    % errors-in-variables effects.

    omega = ...
        OmegaA_CAIG(k,:).';

    H = ...
        [ ...
            skewMatrix(omega), ...
            eye(3) ...
        ];

    % --------------------------------------------------------
    % Measurement
    % --------------------------------------------------------

    z = ...
        deltaOmega(k,:).';

    % --------------------------------------------------------
    % Innovation
    % --------------------------------------------------------

    innovation = ...
        z ...
        - H*Xpred;

    innovationHistory(k,:) = ...
        innovation.';

    % --------------------------------------------------------
    % Innovation covariance
    % --------------------------------------------------------

    S = ...
        H*Ppred*H.' ...
        + R;

    % --------------------------------------------------------
    % Kalman gain
    % --------------------------------------------------------

    K = ...
        Ppred*H.' / S;

    % --------------------------------------------------------
    % State update
    % --------------------------------------------------------

    Xhat = ...
        Xpred ...
        + K*innovation;

    % --------------------------------------------------------
    % Joseph covariance update
    % --------------------------------------------------------

    P = ...
        (I6-K*H) ...
        *Ppred ...
        *(I6-K*H).' ...
        ...
        + K*R*K.';

    % --------------------------------------------------------
    % Store
    % --------------------------------------------------------

    XhatHistory(k,:) = ...
        Xhat.';

    PdiagHistory(k,:) = ...
        diag(P).';

end

%% ============================================================
% 19. FINAL ESTIMATES
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

axesNames = ...
    {'X','Y','Z'};

fprintf('============================================\n');
fprintf('FINAL KALMAN ESTIMATES\n');
fprintf('============================================\n\n');

fprintf('MISALIGNMENT\n');
fprintf('--------------------------------------------\n');

for ax = 1:3

    fprintf('%s true      = %.6f deg\n', ...
        axesNames{ax}, ...
        phiTrueDeg(ax));

    fprintf('%s estimated = %.6f deg\n', ...
        axesNames{ax}, ...
        phiEstimatedDeg(ax));

    fprintf('%s error     = %.6f deg\n\n', ...
        axesNames{ax}, ...
        phiErrorDeg(ax));

end

fprintf('FOG BIAS\n');
fprintf('--------------------------------------------\n');

for ax = 1:3

    fprintf('%s true      = %.6f deg/h\n', ...
        axesNames{ax}, ...
        biasFOG_deg_h);

    fprintf('%s estimated = %.6f deg/h\n', ...
        axesNames{ax}, ...
        biasEstimatedDeg_h(ax));

    fprintf('%s error     = %.6f deg/h\n\n', ...
        axesNames{ax}, ...
        biasErrorDeg_h(ax));

end

%% ============================================================
% 20. HISTORY IN PRACTICAL UNITS
% =============================================================

phiHistoryDeg = ...
    rad2deg(XhatHistory(:,1:3));

biasHistoryDeg_h = ...
    rad2deg(XhatHistory(:,4:6))*3600;

%% ============================================================
% 21. PLOT MISALIGNMENT
% =============================================================

figure;

subplot(3,1,1);

plot(tCAIG,phiHistoryDeg(:,1),'LineWidth',1.2);
hold on;
yline(phiTrueDeg(1),'--');

xlabel('Time [s]');
ylabel('\phi_x [deg]');
title('Kalman Misalignment Estimates - Timetable Architecture');
grid on;


subplot(3,1,2);

plot(tCAIG,phiHistoryDeg(:,2),'LineWidth',1.2);
hold on;
yline(phiTrueDeg(2),'--');

xlabel('Time [s]');
ylabel('\phi_y [deg]');
grid on;


subplot(3,1,3);

plot(tCAIG,phiHistoryDeg(:,3),'LineWidth',1.2);
hold on;
yline(phiTrueDeg(3),'--');

xlabel('Time [s]');
ylabel('\phi_z [deg]');
grid on;

%% ============================================================
% 22. PLOT FOG BIAS
% =============================================================

figure;

subplot(3,1,1);

plot(tCAIG,biasHistoryDeg_h(:,1),'LineWidth',1.2);
hold on;
yline(biasFOG_deg_h,'--');

xlabel('Time [s]');
ylabel('\epsilon_{Fx} [deg/h]');
title('Kalman FOG Bias Estimates - Timetable Architecture');
grid on;


subplot(3,1,2);

plot(tCAIG,biasHistoryDeg_h(:,2),'LineWidth',1.2);
hold on;
yline(biasFOG_deg_h,'--');

xlabel('Time [s]');
ylabel('\epsilon_{Fy} [deg/h]');
grid on;


subplot(3,1,3);

plot(tCAIG,biasHistoryDeg_h(:,3),'LineWidth',1.2);
hold on;
yline(biasFOG_deg_h,'--');

xlabel('Time [s]');
ylabel('\epsilon_{Fz} [deg/h]');
grid on;

%% ============================================================
% LOCAL FUNCTIONS
% =============================================================

function Omega = generateLevel2Sway(t)

    % Zhang level-2 sway parameters

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

    % Zhang does not specify the exact waveform.
    % Sinusoidal attitude motion remains a project assumption.

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

    v = ...
        v(:);

    S = [ ...
         0,     -v(3),   v(2);
         v(3),   0,     -v(1);
        -v(2),   v(1),   0];

end