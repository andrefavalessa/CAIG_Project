%% CAIG_noise_model_sensitivity.m
%
% Sensitivity study for the conversion of the CAIG rotation sensitivity
% reported by Tackmann et al. (2012) into discrete-time white noise.
%
% The goal is NOT to determine which convention is physically correct.
% The goal is to determine how sensitive the CAIG+FOG Kalman results are
% to this modeling assumption.
%
% Model A:
%   sigma_CAIG = N_CAIG * sqrt(Fs_CAIG/2)
%
% Model B:
%   sigma_CAIG = N_CAIG * sqrt(Fs_CAIG)
%
% All other simulation parameters are identical.
%
% Zhang et al. (2019) remains the main monitoring architecture.
% Tackmann et al. (2012) supplies the experimental rotation sensitivity.

clear;
clc;
close all;

%% ============================================================
% 1. GENERAL SETTINGS
% =============================================================

duration = 120;       % [s]
FsFOG    = 100;       % [Hz] Zhang
FsCAIG   = 5;         % [Hz] Zhang
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
fprintf('CAIG NOISE MODEL SENSITIVITY STUDY\n');
fprintf('============================================\n\n');

fprintf('Simulation duration = %.1f s\n', duration);
fprintf('Monte Carlo runs    = %d\n', nRuns);
fprintf('FOG rate            = %.1f Hz\n', FsFOG);
fprintf('CAIG rate           = %.1f Hz\n\n', FsCAIG);

%% ============================================================
% 2. ZHANG LEVEL-2 TRIAXIAL SWAY
% =============================================================

OmegaA_FOG  = generateLevel2Sway(tFOG);
OmegaA_CAIG = generateLevel2Sway(tCAIG);

%% ============================================================
% 3. TRUE FRAME MISALIGNMENT
% =============================================================

phiTrueDeg = [1; 2; 3];

phiTrue = deg2rad(phiTrueDeg);

phiSkew = skewMatrix(phiTrue);

% Zhang first-order frame transformation
C_A_F = eye(3) - phiSkew;

% True angular rate expressed in FOG frame
OmegaF_true = (C_A_F * OmegaA_FOG.').';

%% ============================================================
% 4. TRUE FOG BIAS
% =============================================================

biasFOG_deg_h = 0.1;

biasFOG = deg2rad(biasFOG_deg_h)/3600;   % [rad/s]

biasFOGvec = biasFOG * ones(1,3);

%% ============================================================
% 5. FOG WHITE NOISE
% =============================================================

% EMCORE EG-1300 representative ARW
ARW_FOG_deg_sqrt_h = 0.002;

% Convert deg/sqrt(h) to (rad/s)/sqrt(Hz)
N_FOG = deg2rad(ARW_FOG_deg_sqrt_h)/sqrt(3600);

% Current MATLAB double-sided imuSensor convention
sigmaFOG = N_FOG * sqrt(FsFOG/2);

fprintf('FOG noise density\n');
fprintf('N_FOG = %.6e rad/s/sqrt(Hz)\n', N_FOG);
fprintf('sigma_FOG = %.6e rad/s\n\n', sigmaFOG);

%% ============================================================
% 6. CAIG NOISE: TWO INTERPRETATIONS
% =============================================================

% Tackmann et al. (2012)
N_CAIG = 6.1e-7;      % rad/s/sqrt(Hz)

% Model A: current project convention
sigmaCAIG_A = N_CAIG * sqrt(FsCAIG/2);

% Model B: alternative sensitivity-to-sample mapping
sigmaCAIG_B = N_CAIG * sqrt(FsCAIG);

fprintf('CAIG sensitivity\n');
fprintf('N_CAIG = %.6e rad/s/sqrt(Hz)\n\n', N_CAIG);

fprintf('Model A: N*sqrt(Fs/2)\n');
fprintf('sigma_CAIG_A = %.6e rad/s\n\n', sigmaCAIG_A);

fprintf('Model B: N*sqrt(Fs)\n');
fprintf('sigma_CAIG_B = %.6e rad/s\n\n', sigmaCAIG_B);

fprintf('sigma_B / sigma_A = %.6f\n\n', ...
    sigmaCAIG_B/sigmaCAIG_A);

%% ============================================================
% 7. OBSERVATION COVARIANCE
% =============================================================

sigmaZ_A = sqrt(sigmaFOG^2 + sigmaCAIG_A^2);
sigmaZ_B = sqrt(sigmaFOG^2 + sigmaCAIG_B^2);

R_A = sigmaZ_A^2 * eye(3);
R_B = sigmaZ_B^2 * eye(3);

fprintf('Observation noise\n\n');

fprintf('Model A:\n');
fprintf('sigma_Z = %.6e rad/s\n', sigmaZ_A);
fprintf('R diag  = %.6e (rad/s)^2\n\n', R_A(1,1));

fprintf('Model B:\n');
fprintf('sigma_Z = %.6e rad/s\n', sigmaZ_B);
fprintf('R diag  = %.6e (rad/s)^2\n\n', R_B(1,1));

fprintf('Change in sigma_Z = %.3f %%\n', ...
    100*(sigmaZ_B/sigmaZ_A - 1));

fprintf('Change in R       = %.3f %%\n\n', ...
    100*(R_B(1,1)/R_A(1,1) - 1));

%% ============================================================
% 8. KALMAN INITIAL CONDITIONS
% =============================================================

X0 = zeros(6,1);

phiStd0 = deg2rad([1 2 3]);

biasStd0 = ...
    deg2rad([0.1 0.1 0.1])/3600;

P0 = diag([ ...
    phiStd0.^2, ...
    biasStd0.^2]);

Phi = eye(6);

% States are constant in this simulation
Q = zeros(6);

%% ============================================================
% 9. STORAGE
% =============================================================

finalA = zeros(nRuns,6);
finalB = zeros(nRuns,6);

%% ============================================================
% 10. MONTE CARLO
% =============================================================

fprintf('Running Monte Carlo...\n');

for run = 1:nRuns

    %% --------------------------------------------------------
    % FOG realization
    % Same FOG realization is used for Models A and B.
    % ---------------------------------------------------------

    rng(10000 + run, 'twister');

    paramsFOG = gyroparams;

    paramsFOG.ConstantBias = biasFOGvec;
    paramsFOG.NoiseDensity = N_FOG * ones(1,3);

    imuFOG = imuSensor( ...
        'accel-gyro', ...
        'SampleRate', FsFOG, ...
        'Gyroscope', paramsFOG);

    accelDummy = zeros(NFOG,3);

    [~, OmegaFOG] = imuFOG( ...
        accelDummy, ...
        OmegaF_true);

    OmegaFOG_CAIG = OmegaFOG(idxCAIGinFOG,:);

    %% --------------------------------------------------------
    % CAIG standard-normal realization
    %
    % IMPORTANT:
    % The SAME random numbers are scaled by sigma_A and sigma_B.
    %
    % This makes the comparison paired and isolates only the
    % noise-amplitude interpretation.
    % ---------------------------------------------------------

    rng(20000 + run, 'twister');

    zCAIG = randn(NCAIG,3);

    OmegaCAIG_A = ...
        OmegaA_CAIG + sigmaCAIG_A*zCAIG;

    OmegaCAIG_B = ...
        OmegaA_CAIG + sigmaCAIG_B*zCAIG;

    %% --------------------------------------------------------
    % Observations
    % ---------------------------------------------------------

    Z_A = OmegaFOG_CAIG - OmegaCAIG_A;
    Z_B = OmegaFOG_CAIG - OmegaCAIG_B;

    %% --------------------------------------------------------
    % Kalman Model A
    % ---------------------------------------------------------

    Xhat = X0;
    P    = P0;

    for k = 1:NCAIG

        Xpred = Phi*Xhat;
        Ppred = Phi*P*Phi.' + Q;

        % Use the true simulation angular rate in H so that
        % this experiment isolates measurement noise only.
        omega = OmegaA_CAIG(k,:).';

        H = [skewMatrix(omega), eye(3)];

        innovation = Z_A(k,:).' - H*Xpred;

        S = H*Ppred*H.' + R_A;

        K = Ppred*H.'/S;

        Xhat = Xpred + K*innovation;

        I6 = eye(6);

        % Joseph stabilized covariance update
        P = (I6-K*H)*Ppred*(I6-K*H).' ...
            + K*R_A*K.';
    end

    finalA(run,:) = Xhat.';

    %% --------------------------------------------------------
    % Kalman Model B
    % ---------------------------------------------------------

    Xhat = X0;
    P    = P0;

    for k = 1:NCAIG

        Xpred = Phi*Xhat;
        Ppred = Phi*P*Phi.' + Q;

        omega = OmegaA_CAIG(k,:).';

        H = [skewMatrix(omega), eye(3)];

        innovation = Z_B(k,:).' - H*Xpred;

        S = H*Ppred*H.' + R_B;

        K = Ppred*H.'/S;

        Xhat = Xpred + K*innovation;

        I6 = eye(6);

        P = (I6-K*H)*Ppred*(I6-K*H).' ...
            + K*R_B*K.';
    end

    finalB(run,:) = Xhat.';

end

fprintf('Monte Carlo completed.\n\n');

%% ============================================================
% 11. CONVERT RESULTS TO PRACTICAL UNITS
% =============================================================

% Misalignment: rad -> deg
phiA_deg = rad2deg(finalA(:,1:3));
phiB_deg = rad2deg(finalB(:,1:3));

% Bias: rad/s -> deg/h
biasA_deg_h = rad2deg(finalA(:,4:6))*3600;
biasB_deg_h = rad2deg(finalB(:,4:6))*3600;

truePhi_deg = phiTrueDeg.';
trueBias_deg_h = biasFOG_deg_h*ones(1,3);

%% ============================================================
% 12. STATISTICS
% =============================================================

meanPhiA = mean(phiA_deg,1);
meanPhiB = mean(phiB_deg,1);

stdPhiA = std(phiA_deg,0,1);
stdPhiB = std(phiB_deg,0,1);

rmsePhiA = sqrt(mean( ...
    (phiA_deg-truePhi_deg).^2,1));

rmsePhiB = sqrt(mean( ...
    (phiB_deg-truePhi_deg).^2,1));


meanBiasA = mean(biasA_deg_h,1);
meanBiasB = mean(biasB_deg_h,1);

stdBiasA = std(biasA_deg_h,0,1);
stdBiasB = std(biasB_deg_h,0,1);

rmseBiasA = sqrt(mean( ...
    (biasA_deg_h-trueBias_deg_h).^2,1));

rmseBiasB = sqrt(mean( ...
    (biasB_deg_h-trueBias_deg_h).^2,1));

%% ============================================================
% 13. PRINT RESULTS
% =============================================================

axesNames = {'X','Y','Z'};

fprintf('============================================\n');
fprintf('MISALIGNMENT RESULTS\n');
fprintf('============================================\n');

for ax = 1:3

    fprintf('\nAxis %s\n', axesNames{ax});

    fprintf('Model A\n');
    fprintf('Mean = %.6f deg\n', meanPhiA(ax));
    fprintf('Std  = %.6f deg\n', stdPhiA(ax));
    fprintf('RMSE = %.6f deg\n', rmsePhiA(ax));

    fprintf('Model B\n');
    fprintf('Mean = %.6f deg\n', meanPhiB(ax));
    fprintf('Std  = %.6f deg\n', stdPhiB(ax));
    fprintf('RMSE = %.6f deg\n', rmsePhiB(ax));

end

fprintf('\n============================================\n');
fprintf('FOG BIAS RESULTS\n');
fprintf('============================================\n');

for ax = 1:3

    fprintf('\nAxis %s\n', axesNames{ax});

    fprintf('Model A\n');
    fprintf('Mean = %.6f deg/h\n', meanBiasA(ax));
    fprintf('Std  = %.6f deg/h\n', stdBiasA(ax));
    fprintf('RMSE = %.6f deg/h\n', rmseBiasA(ax));

    fprintf('Model B\n');
    fprintf('Mean = %.6f deg/h\n', meanBiasB(ax));
    fprintf('Std  = %.6f deg/h\n', stdBiasB(ax));
    fprintf('RMSE = %.6f deg/h\n', rmseBiasB(ax));

end

%% ============================================================
% 14. SUMMARY TABLES
% =============================================================

MisalignmentTable = table( ...
    axesNames.', ...
    truePhi_deg.', ...
    meanPhiA.', ...
    stdPhiA.', ...
    rmsePhiA.', ...
    meanPhiB.', ...
    stdPhiB.', ...
    rmsePhiB.', ...
    'VariableNames', { ...
    'Axis', ...
    'True_deg', ...
    'Mean_A_deg', ...
    'Std_A_deg', ...
    'RMSE_A_deg', ...
    'Mean_B_deg', ...
    'Std_B_deg', ...
    'RMSE_B_deg'});

BiasTable = table( ...
    axesNames.', ...
    trueBias_deg_h.', ...
    meanBiasA.', ...
    stdBiasA.', ...
    rmseBiasA.', ...
    meanBiasB.', ...
    stdBiasB.', ...
    rmseBiasB.', ...
    'VariableNames', { ...
    'Axis', ...
    'True_deg_h', ...
    'Mean_A_deg_h', ...
    'Std_A_deg_h', ...
    'RMSE_A_deg_h', ...
    'Mean_B_deg_h', ...
    'Std_B_deg_h', ...
    'RMSE_B_deg_h'});

disp(' ');
disp('MISALIGNMENT SUMMARY');
disp(MisalignmentTable);

disp(' ');
disp('FOG BIAS SUMMARY');
disp(BiasTable);

%% ============================================================
% 15. RELATIVE EFFECT ON RMSE
% =============================================================

fprintf('\n============================================\n');
fprintf('RELATIVE CHANGE: MODEL B vs MODEL A\n');
fprintf('============================================\n');

for ax = 1:3

    dPhi = ...
        100*(rmsePhiB(ax)/rmsePhiA(ax)-1);

    dBias = ...
        100*(rmseBiasB(ax)/rmseBiasA(ax)-1);

    fprintf('\nAxis %s\n', axesNames{ax});
    fprintf('Misalignment RMSE change = %.3f %%\n', dPhi);
    fprintf('Bias RMSE change         = %.3f %%\n', dBias);

end

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
    roll  = rollAmp*sin(wr*t);
    pitch = pitchAmp*sin(wp*t);

    rollDot    = rollAmp*wr*cos(wr*t);
    pitchDot   = pitchAmp*wp*cos(wp*t);
    headingDot = headingAmp*wh*cos(wh*t);

    % 3-2-1 Euler rates -> body angular rates
    p = rollDot ...
        - headingDot.*sin(pitch);

    q = pitchDot.*cos(roll) ...
        + headingDot.*sin(roll).*cos(pitch);

    r = -pitchDot.*sin(roll) ...
        + headingDot.*cos(roll).*cos(pitch);

    Omega = [p q r];

end


function S = skewMatrix(v)

    v = v(:);

    S = [ ...
         0,    -v(3),  v(2);
         v(3),  0,    -v(1);
        -v(2), v(1),   0    ];

end