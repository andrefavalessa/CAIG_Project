clear;
clc;
close all;

%% CAIG V2.4 - Kalman estimation of misalignment and FOG bias
%
% Main reference:
% Zhang et al. (2019)
%
% State:
%
% X = [phi_x phi_y phi_z eps_Fx eps_Fy eps_Fz]'
%
% Zhang Eq. (14):
%
% X(k+1) = Phi*X(k) + Gamma*W(k)
%
% Since misalignment and FOG bias are assumed constant:
%
% Phi = I
%
%
% Zhang Eq. (17):
%
% Z(k) = H(k)*X(k) + V(k)
%
%
% V2.4a PURPOSE:
%
% Validate the Kalman structure before introducing measurement noise.
%
% IMPORTANT:
%
% Zhang provides X0 and P0 but does NOT provide numerical Q and R
% values in the paper.
%
% Therefore:
%
% Q = 0
%
% is used because the six states are constant in this simulation.
%
% R is assigned a small numerical value only to keep the Kalman
% update well-conditioned.
%
% This R value is NOT taken from Zhang et al.
%
% No random measurement noise is added yet.

%% 1. Simulation parameters

duration = 120;                 % [s]

FsFOG  = 100;                   % [Hz], Zhang
FsCAIG = 5;                     % [Hz], Zhang

tFOG = (0:1/FsFOG:duration-1/FsFOG).';
tCAIG = (0:1/FsCAIG:duration-1/FsCAIG).';

NFOG  = length(tFOG);
NCAIG = length(tCAIG);

%% 2. Zhang level-2 triaxial sway

rollAmpDeg    = 0.50;
pitchAmpDeg   = 0.20;
headingAmpDeg = 0.30;

rollPeriod    = 20.00;
pitchPeriod   = 30.00;
headingPeriod = 30.00;

rollAmp    = deg2rad(rollAmpDeg);
pitchAmp   = deg2rad(pitchAmpDeg);
headingAmp = deg2rad(headingAmpDeg);

%% 3. Synthetic attitude
%
% Modeling assumption:
% sinusoidal sway using Zhang amplitudes and periods.

roll = ...
    rollAmp*sin(2*pi*tFOG/rollPeriod);

pitch = ...
    pitchAmp*sin(2*pi*tFOG/pitchPeriod);

heading = ...
    headingAmp*sin(2*pi*tFOG/headingPeriod);

%% 4. Euler rates

rollDot = ...
    rollAmp*(2*pi/rollPeriod).* ...
    cos(2*pi*tFOG/rollPeriod);

pitchDot = ...
    pitchAmp*(2*pi/pitchPeriod).* ...
    cos(2*pi*tFOG/pitchPeriod);

headingDot = ...
    headingAmp*(2*pi/headingPeriod).* ...
    cos(2*pi*tFOG/headingPeriod);

%% 5. Euler rates -> body angular velocity

p = ...
    rollDot ...
    - headingDot.*sin(pitch);

q = ...
    pitchDot.*cos(roll) ...
    + headingDot.*sin(roll).*cos(pitch);

r = ...
   -pitchDot.*sin(roll) ...
    + headingDot.*cos(roll).*cos(pitch);

OmegaA_FOG = [p q r];

%% 6. CAIG epochs

sampleRatio = FsFOG/FsCAIG;

idxCAIGinFOG = ...
    1:sampleRatio:NFOG;

OmegaA_CAIG = ...
    OmegaA_FOG(idxCAIGinFOG,:);

% Ideal CAIG output

OmegaCAIG = OmegaA_CAIG;

%% 7. True frame misalignment
%
% Used ONLY to generate synthetic measurements.
%
% The Kalman filter does NOT receive these values.

phiTrueDeg = [1 2 3];

phiTrue = ...
    deg2rad(phiTrueDeg).';

phiSkew = ...
    [ 0             -phiTrue(3)   phiTrue(2);
      phiTrue(3)     0           -phiTrue(1);
     -phiTrue(2)     phiTrue(1)   0          ];

% Zhang Eq. (11)

C_A_F = eye(3) - phiSkew;

%% 8. True angular rate in FOG frame
%
% Zhang Eq. (12)

OmegaF_true = ...
    (C_A_F*OmegaA_FOG.').';

%% 9. True FOG bias
%
% Used only to generate sensor data.

biasTrue_deg_h = ...
    [0.1 0.1 0.1];

biasTrue_rad_s = ...
    biasTrue_deg_h*pi/180/3600;

%% 10. MATLAB FOG model

paramsFOG = gyroparams;

paramsFOG.ConstantBias = ...
    biasTrue_rad_s;

imuFOG = imuSensor( ...
    'SampleRate',FsFOG,...
    'Gyroscope',paramsFOG);

accFOG = zeros(NFOG,3);

[~,OmegaFOG] = ...
    imuFOG(accFOG,OmegaF_true);

%% 11. Synchronize FOG to CAIG epochs

OmegaFOGatCAIG = ...
    OmegaFOG(idxCAIGinFOG,:);

%% 12. Measurement vector
%
% Zhang Eq. (16)-(17)
%
% Z = omega_FOG - omega_CAIG

Z = ...
    OmegaFOGatCAIG - OmegaCAIG;

%% ========================================================================
%  KALMAN FILTER
% ========================================================================

%% 13. Initial state
%
% Zhang Eq. (28)

Xhat = zeros(6,1);

%% 14. Initial covariance P0
%
% Zhang Eq. (28)
%
% States 1-3 -> rad
% States 4-6 -> rad/s

sigmaPhi0 = ...
    deg2rad([1 2 3]);

sigmaBias0 = ...
    (0.1*pi/180/3600)*ones(1,3);

P = diag( ...
    [sigmaPhi0.^2 ...
     sigmaBias0.^2]);

%% 15. State transition
%
% Misalignment and bias are constant.

Phi = eye(6);

%% 16. Process-noise covariance
%
% V2.4a assumption:
%
% States are perfectly constant.
%
% Zhang does not provide numerical process-noise covariance.

Q = zeros(6);

%% 17. Measurement-noise covariance
%
% IMPORTANT:
%
% Zhang defines R_k but does not provide a numerical value.
%
% This is a numerical assumption used only for the first
% noise-free Kalman validation.

sigmaMeasurement = 1e-8;       % [rad/s], V2.4a choice

R = ...
    sigmaMeasurement^2*eye(3);

%% 18. Storage

Xhistory = zeros(NCAIG,6);

Phistory = zeros(NCAIG,6);

innovationHistory = zeros(NCAIG,3);

%% 19. Kalman recursion

for k = 1:NCAIG

    %% Prediction

    Xpred = ...
        Phi*Xhat;

    Ppred = ...
        Phi*P*Phi.' + Q;

    %% Observation matrix H(k)
    %
    % Zhang Eq. (18):
    %
    % H = [[omega x] I]

    wx = OmegaCAIG(k,1);
    wy = OmegaCAIG(k,2);
    wz = OmegaCAIG(k,3);

    omegaSkew = ...
        [ 0   -wz   wy;
          wz   0   -wx;
         -wy   wx   0 ];

    H = ...
        [omegaSkew eye(3)];

    %% Innovation

    innovation = ...
        Z(k,:).' - H*Xpred;

    %% Innovation covariance

    S = ...
        H*Ppred*H.' + R;

    %% Kalman gain
    %
    % Use matrix division instead of inv(S).

    K = ...
        (Ppred*H.') / S;

    %% State update

    Xhat = ...
        Xpred + K*innovation;

    %% Covariance update
    %
    % Joseph stabilized form.

    I6 = eye(6);

    P = ...
        (I6-K*H)*Ppred*(I6-K*H).' ...
        + K*R*K.';

    %% Store

    Xhistory(k,:) = Xhat.';

    Phistory(k,:) = diag(P).';

    innovationHistory(k,:) = innovation.';

end

%% 20. Convert estimated states

phiEstimatedDeg = ...
    rad2deg(Xhistory(:,1:3));

biasEstimatedDegH = ...
    Xhistory(:,4:6)*180/pi*3600;

%% 21. Final estimates

phiFinal = ...
    phiEstimatedDeg(end,:);

biasFinal = ...
    biasEstimatedDegH(end,:);

%% 22. Final errors

phiError = ...
    phiFinal - phiTrueDeg;

biasError = ...
    biasFinal - biasTrue_deg_h;

%% 23. Display results

fprintf('\n');
fprintf('============================================\n');
fprintf('CAIG V2.4a - KALMAN FILTER\n');
fprintf('============================================\n');

fprintf('\nTRUE MISALIGNMENT\n');

fprintf('phi_x = %.6f deg\n',phiTrueDeg(1));
fprintf('phi_y = %.6f deg\n',phiTrueDeg(2));
fprintf('phi_z = %.6f deg\n',phiTrueDeg(3));

fprintf('\nESTIMATED MISALIGNMENT\n');

fprintf('phi_x = %.6f deg\n',phiFinal(1));
fprintf('phi_y = %.6f deg\n',phiFinal(2));
fprintf('phi_z = %.6f deg\n',phiFinal(3));

fprintf('\nMISALIGNMENT ERROR\n');

fprintf('X = %.3e deg\n',phiError(1));
fprintf('Y = %.3e deg\n',phiError(2));
fprintf('Z = %.3e deg\n',phiError(3));

fprintf('\nTRUE FOG BIAS\n');

fprintf('X = %.6f deg/h\n',biasTrue_deg_h(1));
fprintf('Y = %.6f deg/h\n',biasTrue_deg_h(2));
fprintf('Z = %.6f deg/h\n',biasTrue_deg_h(3));

fprintf('\nESTIMATED FOG BIAS\n');

fprintf('X = %.6f deg/h\n',biasFinal(1));
fprintf('Y = %.6f deg/h\n',biasFinal(2));
fprintf('Z = %.6f deg/h\n',biasFinal(3));

fprintf('\nBIAS ERROR\n');

fprintf('X = %.3e deg/h\n',biasError(1));
fprintf('Y = %.3e deg/h\n',biasError(2));
fprintf('Z = %.3e deg/h\n',biasError(3));

fprintf('\nFILTER ASSUMPTIONS\n');

fprintf('Q = 0 (constant-state validation)\n');

fprintf('Assumed sigma measurement = %.3e rad/s\n',...
    sigmaMeasurement);

fprintf('NOTE: numerical R is not specified by Zhang.\n');

%% 24. Plot estimated misalignment

figure;

subplot(2,1,1)

plot(tCAIG,...
    phiEstimatedDeg(:,1),...
    'LineWidth',1.3)

hold on

plot(tCAIG,...
    phiEstimatedDeg(:,2),...
    '--',...
    'LineWidth',1.3)

plot(tCAIG,...
    phiEstimatedDeg(:,3),...
    ':',...
    'LineWidth',1.5)

yline(phiTrueDeg(1),'--')
yline(phiTrueDeg(2),'--')
yline(phiTrueDeg(3),'--')

grid on

ylabel('Misalignment [deg]')

legend( ...
    '\hat{\phi}_x',...
    '\hat{\phi}_y',...
    '\hat{\phi}_z',...
    'Location','best')

title('Kalman Estimated CAIG-FOG Misalignment')

%% 25. Plot estimated biases

subplot(2,1,2)

plot(tCAIG,...
    biasEstimatedDegH(:,1),...
    'LineWidth',1.3)

hold on

plot(tCAIG,...
    biasEstimatedDegH(:,2),...
    '--',...
    'LineWidth',1.3)

plot(tCAIG,...
    biasEstimatedDegH(:,3),...
    ':',...
    'LineWidth',1.5)

yline(0.1,'--')

grid on

xlabel('Time [s]')
ylabel('Bias [deg/h]')

legend( ...
    '\hat{\epsilon}_{Fx}',...
    '\hat{\epsilon}_{Fy}',...
    '\hat{\epsilon}_{Fz}',...
    'True bias',...
    'Location','best')

title('Kalman Estimated FOG Bias')