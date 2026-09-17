clear;
clc;
close all;

%% CAIG V2.2 - imuSensor FOG + CAIG frame misalignment
%
% Main reference:
% Zhang et al. (2019)
%
% Zhang Eq. (11):
%
%   C_A^F = I - [phi_a x]
%
% Zhang Eq. (12):
%
%   omega_F = C_A^F * omega_A
%
% Zhang Eq. (16):
%
%   deltaOmega = [omega_A x] phi_a + epsilon_F
%
%
% Conventional gyro:
%   MATLAB imuSensor + gyroparams
%
% No noise.
% No Kalman filter.
% No gyroparams.AxesMisalignment.
%
% IMPORTANT:
% The misalignment modeled here is the frame misalignment between
% CAIG (A-frame) and FOG (F-frame), not the internal axis
% misalignment property of gyroparams.

%% 1. Simulation parameters

duration = 20;                 % [s], simulation choice

FsFOG  = 100;                  % [Hz], Zhang et al. (2019)
FsCAIG = 5;                    % [Hz], Zhang et al. (2019)

tFOG = ...
    (0:1/FsFOG:duration-1/FsFOG).';

tCAIG = ...
    (0:1/FsCAIG:duration-1/FsCAIG).';

NFOG  = length(tFOG);
NCAIG = length(tCAIG);

%% 2. Ground-truth angular motion in CAIG A-frame
%
% Same synthetic input used previously.
%
% Rotation only around Y.

Omega0 = 1e-5;                 % [rad/s], simulation choice
f = 0.1;                       % [Hz], simulation choice

OmegaA_FOG = zeros(NFOG,3);
OmegaA_CAIG = zeros(NCAIG,3);

OmegaA_FOG(:,2) = ...
    Omega0*sin(2*pi*f*tFOG);

OmegaA_CAIG(:,2) = ...
    Omega0*sin(2*pi*f*tCAIG);

%% 3. CAIG ideal measurement
%
% CAIG bias is neglected, following Zhang's simulation.

OmegaCAIG = OmegaA_CAIG;

%% 4. CAIG-to-FOG frame misalignment
%
% Zhang simulation values:
%
% phi_ax = 1 deg
% phi_ay = 2 deg
% phi_az = 3 deg

phiDeg = [1 2 3];

phi = deg2rad(phiDeg).';       % column vector [rad]

%% 5. Skew-symmetric matrix [phi x]

phiSkew = ...
    [ 0        -phi(3)   phi(2);
      phi(3)    0       -phi(1);
     -phi(2)    phi(1)   0      ];

%% 6. Direction cosine matrix
%
% Zhang Eq. (11)
%
% First-order small-angle approximation.

C_A_F = eye(3) - phiSkew;

%% 7. Transform angular velocity to FOG frame
%
% Zhang Eq. (12)
%
% omega_F = C_A^F * omega_A

OmegaF_true = ...
    (C_A_F * OmegaA_FOG.').';

%% 8. FOG bias
%
% Zhang:
% FOG bias = 0.1 deg/h

biasFOG_deg_h = 0.1;

biasFOG_rad_s = ...
    biasFOG_deg_h*pi/180/3600;

biasFOG = ...
    [biasFOG_rad_s ...
     biasFOG_rad_s ...
     biasFOG_rad_s];

%% 9. Configure MATLAB gyro model

paramsFOG = gyroparams;

paramsFOG.ConstantBias = biasFOG;

%% 10. Create imuSensor

imuFOG = imuSensor( ...
    'SampleRate',FsFOG, ...
    'Gyroscope',paramsFOG);

%% 11. Generate FOG synthetic measurements
%
% The angular velocity supplied to imuSensor is already expressed
% in the FOG frame.

accFOG = zeros(NFOG,3);

[~,OmegaFOG] = ...
    imuFOG(accFOG,OmegaF_true);

%% 12. Synchronize FOG and CAIG epochs

sampleRatio = FsFOG/FsCAIG;

idxCAIGinFOG = ...
    1:sampleRatio:NFOG;

OmegaFOGatCAIG = ...
    OmegaFOG(idxCAIGinFOG,:);

OmegaAatCAIG = ...
    OmegaA_FOG(idxCAIGinFOG,:);

OmegaFatCAIG = ...
    OmegaF_true(idxCAIGinFOG,:);

%% 13. Measurement observation
%
% FOG - CAIG

deltaOmega = ...
    OmegaFOGatCAIG - OmegaCAIG;

%% 14. Analytical misalignment contribution
%
% Zhang Eq. (16):
%
% deltaOmega =
%     [omega_A x] phi + epsilon_F
%
% For each sample:
%
%     omega_A x phi

phiMatrix = ...
    repmat(phi.',NCAIG,1);

misalignmentTerm = ...
    cross(OmegaAatCAIG,phiMatrix,2);

%% 15. Expected observation

expectedDeltaOmega = ...
    misalignmentTerm + biasFOG;

%% 16. Verify Eq. (11)-(12)
%
% omega_F - omega_A
%
% should equal
%
% omega_A x phi

misalignmentFromDCM = ...
    OmegaFatCAIG - OmegaAatCAIG;

dcmError = ...
    max(abs( ...
        misalignmentFromDCM ...
        - misalignmentTerm),...
        [],1);

%% 17. Verify Eq. (16)

observationError = ...
    max(abs( ...
        deltaOmega ...
        - expectedDeltaOmega),...
        [],1);

%% 18. Convert to deg/h for visualization

misalignment_deg_h = ...
    misalignmentTerm*180/pi*3600;

deltaOmega_deg_h = ...
    deltaOmega*180/pi*3600;

%% 19. Display

fprintf('\n');
fprintf('============================================\n');
fprintf('CAIG V2.2 - imuSensor + MISALIGNMENT\n');
fprintf('============================================\n');

fprintf('\nDATA RATES\n');

fprintf('CAIG = %.1f Hz\n',FsCAIG);
fprintf('FOG  = %.1f Hz\n',FsFOG);

fprintf('\nFRAME MISALIGNMENT\n');

fprintf('phi_ax = %.2f deg\n',phiDeg(1));
fprintf('phi_ay = %.2f deg\n',phiDeg(2));
fprintf('phi_az = %.2f deg\n',phiDeg(3));

fprintf('\nC_A^F\n');

disp(C_A_F)

fprintf('FOG BIAS\n');

fprintf('Bias = %.6f deg/h\n',...
    biasFOG_deg_h);

fprintf('\nMAXIMUM MISALIGNMENT CONTRIBUTION\n');

fprintf('X = %.6f deg/h\n',...
    max(abs(misalignment_deg_h(:,1))));

fprintf('Y = %.6f deg/h\n',...
    max(abs(misalignment_deg_h(:,2))));

fprintf('Z = %.6f deg/h\n',...
    max(abs(misalignment_deg_h(:,3))));

fprintf('\nDCM VERIFICATION\n');

fprintf('X error = %.3e rad/s\n',...
    dcmError(1));

fprintf('Y error = %.3e rad/s\n',...
    dcmError(2));

fprintf('Z error = %.3e rad/s\n',...
    dcmError(3));

fprintf('\nEQ. (16) VERIFICATION\n');

fprintf('X error = %.3e rad/s\n',...
    observationError(1));

fprintf('Y error = %.3e rad/s\n',...
    observationError(2));

fprintf('Z error = %.3e rad/s\n',...
    observationError(3));

%% 20. Plots

figure;

%% Ground-truth A-frame motion

subplot(3,1,1)

plot( ...
    tCAIG,...
    OmegaAatCAIG(:,1),...
    'LineWidth',1.2)

hold on

plot( ...
    tCAIG,...
    OmegaAatCAIG(:,2),...
    '--',...
    'LineWidth',1.5)

plot( ...
    tCAIG,...
    OmegaAatCAIG(:,3),...
    ':',...
    'LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('\omega_A [rad/s]')

legend( ...
    '\omega_x',...
    '\omega_y',...
    '\omega_z',...
    'Location','best')

title('Ground-Truth Angular Velocity in CAIG A-Frame')

%% Misalignment contribution

subplot(3,1,2)

plot( ...
    tCAIG,...
    misalignment_deg_h(:,1),...
    'LineWidth',1.3)

hold on

plot( ...
    tCAIG,...
    misalignment_deg_h(:,2),...
    '--',...
    'LineWidth',1.3)

plot( ...
    tCAIG,...
    misalignment_deg_h(:,3),...
    ':',...
    'LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('Misalignment [deg/h]')

legend( ...
    'X',...
    'Y',...
    'Z',...
    'Location','best')

title('Frame Misalignment Contribution')

%% FOG - CAIG observation

subplot(3,1,3)

plot( ...
    tCAIG,...
    deltaOmega_deg_h(:,1),...
    'LineWidth',1.3)

hold on

plot( ...
    tCAIG,...
    deltaOmega_deg_h(:,2),...
    '--',...
    'LineWidth',1.3)

plot( ...
    tCAIG,...
    deltaOmega_deg_h(:,3),...
    ':',...
    'LineWidth',1.5)

yline(0.1,':');

grid on

xlabel('Time [s]')
ylabel('\delta\omega [deg/h]')

legend( ...
    '\delta\omega_x',...
    '\delta\omega_y',...
    '\delta\omega_z',...
    'FOG bias',...
    'Location','best')

title('imuSensor FOG - CAIG Observation')