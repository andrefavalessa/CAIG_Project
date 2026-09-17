%% CAIG_V2_5_MonteCarlo.m
%
% Monte Carlo analysis of the noisy CAIG + FOG Kalman estimator.
%
% Main architecture:
%   Zhang et al. (2019)
%
% Updated FOG noise model:
%   EMCORE EG-1300 ARW = 0.002 deg/sqrt(h)
%   NoiseType = 'single-sided'
%
% CAIG noise:
%   Tackmann et al. (2012) sensitivity
%   6.1e-7 rad/s/sqrt(Hz)
%
% Current CAIG mapping remains:
%   sigma_CAIG = N_CAIG * sqrt(Fs_CAIG/2)
%
% The purpose of this script is to characterize the distribution
% of the final Kalman estimates over multiple independent runs.

clear;
clc;
close all;

%% ============================================================
% 1. SETTINGS
% =============================================================

duration = 120;       % [s]
FsFOG    = 100;       % [Hz]
FsCAIG   = 5;         % [Hz]
nRuns    = 100;

dtFOG  = 1/FsFOG;
dtCAIG = 1/FsCAIG;

tFOG  = (0:dtFOG:duration-dtFOG).';
tCAIG = (0:dtCAIG:duration-dtCAIG).';

NFOG  = length(tFOG);
NCAIG = length(tCAIG);

sampleRatio = FsFOG/FsCAIG;

assert(mod(sampleRatio,1) == 0, ...
    'FOG/CAIG sample-rate ratio must be integer.');

idxCAIGinFOG = 1:sampleRatio:NFOG;

fprintf('============================================\n');
fprintf('CAIG V2.5 - MONTE CARLO\n');
fprintf('============================================\n\n');

fprintf('Simulation duration = %.1f s\n', duration);
fprintf('Monte Carlo runs    = %d\n', nRuns);
fprintf('FOG sample rate     = %.1f Hz\n', FsFOG);
fprintf('CAIG sample rate    = %.1f Hz\n\n', FsCAIG);

%% ============================================================
% 2. TRUE TRIAXIAL SWAY
% =============================================================

OmegaA_FOG  = generateLevel2Sway(tFOG);
OmegaA_CAIG = generateLevel2Sway(tCAIG);

%% ============================================================
% 3. TRUE MISALIGNMENT
% =============================================================

phiTrueDeg = [1; 2; 3];
phiTrue    = deg2rad(phiTrueDeg);

C_A_F = eye(3) - skewMatrix(phiTrue);

OmegaF_true = (C_A_F * OmegaA_FOG.').';

%% ============================================================
% 4. TRUE FOG BIAS
% =============================================================

biasFOG_deg_h = 0.1;

biasFOG = deg2rad(biasFOG_deg_h)/3600;

biasFOGvec = biasFOG*ones(1,3);

%% ============================================================
% 5. FOG NOISE
% =============================================================

% EMCORE EG-1300 ARW
ARW_FOG_deg_sqrt_h = 0.002;

N_FOG = ...
    deg2rad(ARW_FOG_deg_sqrt_h) ...
    / sqrt(3600);

% Corrected single-sided scaling
sigmaFOG = ...
    N_FOG * sqrt(FsFOG);

fprintf('FOG noise model\n');
fprintf('ARW        = %.6f deg/sqrt(h)\n', ...
    ARW_FOG_deg_sqrt_h);
fprintf('NoiseType  = single-sided\n');
fprintf('N_FOG      = %.6e rad/s/sqrt(Hz)\n', ...
    N_FOG);
fprintf('sigma_FOG  = %.6e rad/s\n\n', ...
    sigmaFOG);

%% ============================================================
% 6. CAIG NOISE
% =============================================================

N_CAIG = 6.1e-7;     % rad/s/sqrt(Hz)

% Current project modeling convention
sigmaCAIG = ...
    N_CAIG * sqrt(FsCAIG/2);

fprintf('CAIG noise model\n');
fprintf('N_CAIG     = %.6e rad/s/sqrt(Hz)\n', ...
    N_CAIG);
fprintf('sigma_CAIG = %.6e rad/s\n\n', ...
    sigmaCAIG);

%% ============================================================
% 7. OBSERVATION COVARIANCE
% =============================================================

sigmaZ = ...
    sqrt( ...
        sigmaFOG^2 ...
        + sigmaCAIG^2);

R = ...
    sigmaZ^2 * eye(3);

fprintf('Observation noise\n');
fprintf('sigma_Z    = %.6e rad/s\n', sigmaZ);
fprintf('R diagonal = %.6e (rad/s)^2\n\n', ...
    R(1,1));

%% ============================================================
% 8. KALMAN INITIAL CONDITIONS
% =============================================================

X0 = zeros(6,1);

phiStd0 = ...
    deg2rad([1;2;3]);

biasStd0 = ...
    deg2rad([0.1;0.1;0.1])/3600;

P0 = ...
    diag([phiStd0; biasStd0].^2);

Phi = eye(6);

Q = zeros(6);

%% ============================================================
% 9. STORAGE
% =============================================================

finalStates = ...
    zeros(nRuns,6);

%% ============================================================
% 10. MONTE CARLO LOOP
% =============================================================

fprintf('Running Monte Carlo...\n');

for run = 1:nRuns

    %% --------------------------------------------------------
    % FOG realization
    % ---------------------------------------------------------

    rng(10000 + run, 'twister');

    paramsFOG = gyroparams( ...
        'ConstantBias', ...
        biasFOGvec, ...
        ...
        'NoiseDensity', ...
        N_FOG*ones(1,3), ...
        ...
        'NoiseType', ...
        'single-sided');

    imuFOG = imuSensor( ...
        'accel-gyro', ...
        'SampleRate', FsFOG, ...
        'Gyroscope', paramsFOG);

    accelDummy = zeros(NFOG,3);

    [~, OmegaFOG] = imuFOG( ...
        accelDummy, ...
        OmegaF_true);

    OmegaFOG_CAIG = ...
        OmegaFOG(idxCAIGinFOG,:);

    %% --------------------------------------------------------
    % CAIG realization
    % ---------------------------------------------------------

    rng(20000 + run, 'twister');

    caigNoise = ...
        sigmaCAIG * randn(NCAIG,3);

    OmegaCAIG = ...
        OmegaA_CAIG ...
        + caigNoise;

    %% --------------------------------------------------------
    % Monitoring observation
    % ---------------------------------------------------------

    Z = ...
        OmegaFOG_CAIG ...
        - OmegaCAIG;

    %% --------------------------------------------------------
    % Kalman initialization
    % ---------------------------------------------------------

    Xhat = X0;
    P    = P0;

    I6 = eye(6);

    %% --------------------------------------------------------
    % Kalman loop
    % ---------------------------------------------------------

    for k = 1:NCAIG

        % Prediction
        Xpred = ...
            Phi*Xhat;

        Ppred = ...
            Phi*P*Phi.' + Q;

        % Use true simulation angular rate in H
        omega = ...
            OmegaA_CAIG(k,:).';

        H = ...
            [skewMatrix(omega), eye(3)];

        z = ...
            Z(k,:).';

        innovation = ...
            z - H*Xpred;

        S = ...
            H*Ppred*H.' + R;

        K = ...
            Ppred*H.'/S;

        Xhat = ...
            Xpred + K*innovation;

        % Joseph covariance update
        P = ...
            (I6-K*H)*Ppred*(I6-K*H).' ...
            + K*R*K.';

    end

    finalStates(run,:) = ...
        Xhat.';

end

fprintf('Monte Carlo completed.\n\n');

%% ============================================================
% 11. CONVERT RESULTS
% =============================================================

phiEstDeg = ...
    rad2deg(finalStates(:,1:3));

biasEstDeg_h = ...
    rad2deg(finalStates(:,4:6))*3600;

truePhiDeg = ...
    phiTrueDeg.';

trueBiasDeg_h = ...
    biasFOG_deg_h*ones(1,3);

%% ============================================================
% 12. STATISTICS
% =============================================================

meanPhi = ...
    mean(phiEstDeg,1);

stdPhi = ...
    std(phiEstDeg,0,1);

meanErrorPhi = ...
    mean(phiEstDeg-truePhiDeg,1);

rmsePhi = ...
    sqrt(mean( ...
        (phiEstDeg-truePhiDeg).^2, ...
        1));


meanBias = ...
    mean(biasEstDeg_h,1);

stdBias = ...
    std(biasEstDeg_h,0,1);

meanErrorBias = ...
    mean( ...
        biasEstDeg_h-trueBiasDeg_h, ...
        1);

rmseBias = ...
    sqrt(mean( ...
        (biasEstDeg_h-trueBiasDeg_h).^2, ...
        1));

%% ============================================================
% 13. 95% CONFIDENCE INTERVAL OF THE MEAN
% =============================================================

CI95_phi_low = ...
    meanPhi ...
    - 1.96*stdPhi/sqrt(nRuns);

CI95_phi_high = ...
    meanPhi ...
    + 1.96*stdPhi/sqrt(nRuns);

CI95_bias_low = ...
    meanBias ...
    - 1.96*stdBias/sqrt(nRuns);

CI95_bias_high = ...
    meanBias ...
    + 1.96*stdBias/sqrt(nRuns);

%% ============================================================
% 14. PRINT RESULTS
% =============================================================

axesNames = {'X','Y','Z'};

fprintf('============================================\n');
fprintf('MISALIGNMENT RESULTS\n');
fprintf('============================================\n');

for ax = 1:3

    fprintf('\nAxis %s\n', axesNames{ax});

    fprintf('True       = %.6f deg\n', ...
        truePhiDeg(ax));

    fprintf('Mean       = %.6f deg\n', ...
        meanPhi(ax));

    fprintf('Std        = %.6f deg\n', ...
        stdPhi(ax));

    fprintf('Mean error = %.6e deg\n', ...
        meanErrorPhi(ax));

    fprintf('RMSE       = %.6f deg\n', ...
        rmsePhi(ax));

    fprintf('95%% CI mean = [%.6f, %.6f] deg\n', ...
        CI95_phi_low(ax), ...
        CI95_phi_high(ax));

end

fprintf('\n============================================\n');
fprintf('FOG BIAS RESULTS\n');
fprintf('============================================\n');

for ax = 1:3

    fprintf('\nAxis %s\n', axesNames{ax});

    fprintf('True       = %.6f deg/h\n', ...
        trueBiasDeg_h(ax));

    fprintf('Mean       = %.6f deg/h\n', ...
        meanBias(ax));

    fprintf('Std        = %.6f deg/h\n', ...
        stdBias(ax));

    fprintf('Mean error = %.6f deg/h\n', ...
        meanErrorBias(ax));

    fprintf('RMSE       = %.6f deg/h\n', ...
        rmseBias(ax));

    fprintf('95%% CI mean = [%.6f, %.6f] deg/h\n', ...
        CI95_bias_low(ax), ...
        CI95_bias_high(ax));

end

%% ============================================================
% 15. SUMMARY TABLES
% =============================================================

MisalignmentTable = table( ...
    axesNames.', ...
    truePhiDeg.', ...
    meanPhi.', ...
    stdPhi.', ...
    meanErrorPhi.', ...
    rmsePhi.', ...
    CI95_phi_low.', ...
    CI95_phi_high.', ...
    'VariableNames', { ...
    'Axis', ...
    'True_deg', ...
    'Mean_deg', ...
    'Std_deg', ...
    'MeanError_deg', ...
    'RMSE_deg', ...
    'CI95_Low_deg', ...
    'CI95_High_deg'});

BiasTable = table( ...
    axesNames.', ...
    trueBiasDeg_h.', ...
    meanBias.', ...
    stdBias.', ...
    meanErrorBias.', ...
    rmseBias.', ...
    CI95_bias_low.', ...
    CI95_bias_high.', ...
    'VariableNames', { ...
    'Axis', ...
    'True_deg_h', ...
    'Mean_deg_h', ...
    'Std_deg_h', ...
    'MeanError_deg_h', ...
    'RMSE_deg_h', ...
    'CI95_Low_deg_h', ...
    'CI95_High_deg_h'});

disp(' ');
disp('MISALIGNMENT SUMMARY');
disp(MisalignmentTable);

disp(' ');
disp('FOG BIAS SUMMARY');
disp(BiasTable);

%% ============================================================
% 16. HISTOGRAMS
% =============================================================

figure;

subplot(3,1,1);
histogram(phiEstDeg(:,1));
xline(truePhiDeg(1),'--');
xlabel('\phi_x [deg]');
ylabel('Count');
title('Monte Carlo Misalignment Estimates');
grid on;

subplot(3,1,2);
histogram(phiEstDeg(:,2));
xline(truePhiDeg(2),'--');
xlabel('\phi_y [deg]');
ylabel('Count');
grid on;

subplot(3,1,3);
histogram(phiEstDeg(:,3));
xline(truePhiDeg(3),'--');
xlabel('\phi_z [deg]');
ylabel('Count');
grid on;


figure;

subplot(3,1,1);
histogram(biasEstDeg_h(:,1));
xline(trueBiasDeg_h(1),'--');
xlabel('\epsilon_{Fx} [deg/h]');
ylabel('Count');
title('Monte Carlo FOG Bias Estimates');
grid on;

subplot(3,1,2);
histogram(biasEstDeg_h(:,2));
xline(trueBiasDeg_h(2),'--');
xlabel('\epsilon_{Fy} [deg/h]');
ylabel('Count');
grid on;

subplot(3,1,3);
histogram(biasEstDeg_h(:,3));
xline(trueBiasDeg_h(3),'--');
xlabel('\epsilon_{Fz} [deg/h]');
ylabel('Count');
grid on;

%% ============================================================
% LOCAL FUNCTIONS
% =============================================================

function Omega = generateLevel2Sway(t)

    % Zhang level-2 sway parameters

    rollAmp    = deg2rad(0.50);
    pitchAmp   = deg2rad(0.20);
    headingAmp = deg2rad(0.30);

    rollPeriod    = 20;
    pitchPeriod   = 30;
    headingPeriod = 30;

    wr = 2*pi/rollPeriod;
    wp = 2*pi/pitchPeriod;
    wh = 2*pi/headingPeriod;

    % Sinusoidal waveform is a simulation assumption

    roll  = ...
        rollAmp*sin(wr*t);

    pitch = ...
        pitchAmp*sin(wp*t);

    rollDot = ...
        rollAmp*wr*cos(wr*t);

    pitchDot = ...
        pitchAmp*wp*cos(wp*t);

    headingDot = ...
        headingAmp*wh*cos(wh*t);

    % 3-2-1 Euler rates -> body angular rates

    p = ...
        rollDot ...
        - headingDot.*sin(pitch);

    q = ...
        pitchDot.*cos(roll) ...
        + headingDot.*sin(roll).*cos(pitch);

    r = ...
        -pitchDot.*sin(roll) ...
        + headingDot.*cos(roll).*cos(pitch);

    Omega = [p q r];

end


function S = skewMatrix(v)

    v = v(:);

    S = [ ...
         0,    -v(3),  v(2);
         v(3),  0,    -v(1);
        -v(2), v(1),   0];

end