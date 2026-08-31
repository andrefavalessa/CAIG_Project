clear;
clc;
close all;

%% CAIG V2.3 - Triaxial sway + imuSensor FOG
%
% Main reference:
% Zhang et al. (2019), Section 4.3.
%
% Zhang level-2 sway parameters:
%
% Roll:    amplitude = 0.50 deg, period = 20 s
% Pitch:   amplitude = 0.20 deg, period = 30 s
% Heading: amplitude = 0.30 deg, period = 30 s
%
% IMPORTANT:
% Zhang provides amplitudes and periods, but not the exact
% time-domain sway waveform.
%
% V2.3 ASSUMPTION:
% Roll, pitch and heading are modeled as sinusoids.
%
% No noise.
% No Kalman filter.

%% 1. Simulation

duration = 120;        % [s], simulation choice

FsFOG  = 100;          % [Hz], Zhang
FsCAIG = 5;            % [Hz], Zhang

tFOG = (0:1/FsFOG:duration-1/FsFOG).';
tCAIG = (0:1/FsCAIG:duration-1/FsCAIG).';

NFOG  = length(tFOG);
NCAIG = length(tCAIG);

%% 2. Zhang level-2 sway parameters

rollAmpDeg    = 0.50;
pitchAmpDeg   = 0.20;
headingAmpDeg = 0.30;

rollPeriod    = 20.00;     % [s]
pitchPeriod   = 30.00;     % [s]
headingPeriod = 30.00;     % [s]

rollAmp    = deg2rad(rollAmpDeg);
pitchAmp   = deg2rad(pitchAmpDeg);
headingAmp = deg2rad(headingAmpDeg);

%% 3. Synthetic triaxial attitude
%
% Simulation assumption:
%
% angle(t) = A*sin(2*pi*t/P)
%
% Initial roll, pitch and heading are therefore zero,
% consistent with Zhang Section 4.3.

roll = ...
    rollAmp*sin(2*pi*tFOG/rollPeriod);

pitch = ...
    pitchAmp*sin(2*pi*tFOG/pitchPeriod);

heading = ...
    headingAmp*sin(2*pi*tFOG/headingPeriod);

%% 4. Euler angle rates

rollDot = ...
    rollAmp*(2*pi/rollPeriod) .* ...
    cos(2*pi*tFOG/rollPeriod);

pitchDot = ...
    pitchAmp*(2*pi/pitchPeriod) .* ...
    cos(2*pi*tFOG/pitchPeriod);

headingDot = ...
    headingAmp*(2*pi/headingPeriod) .* ...
    cos(2*pi*tFOG/headingPeriod);

%% 5. Convert Euler rates to body angular velocity
%
% Standard 3-2-1 yaw-pitch-roll relation:
%
% [p]   [1   0        -sin(theta)       ] [phiDot  ]
% [q] = [0   cos(phi)  sin(phi)cos(theta)] [thetaDot]
% [r]   [0  -sin(phi)  cos(phi)cos(theta)] [psiDot  ]
%
% This conversion is a modeling step used to obtain the
% angular-rate input required by the gyro simulation.

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

%% 6. CAIG measurement epochs

sampleRatio = FsFOG/FsCAIG;

idxCAIGinFOG = ...
    1:sampleRatio:NFOG;

OmegaA_CAIG = ...
    OmegaA_FOG(idxCAIGinFOG,:);

% Ideal CAIG output
OmegaCAIG = OmegaA_CAIG;

%% 7. Frame misalignment
%
% Zhang simulation:
%
% phi_ax = 1 deg
% phi_ay = 2 deg
% phi_az = 3 deg

phiDeg = [1 2 3];

phi = deg2rad(phiDeg).';

phiSkew = ...
    [ 0        -phi(3)   phi(2);
      phi(3)    0       -phi(1);
     -phi(2)    phi(1)   0      ];

% Zhang Eq. (11)
C_A_F = eye(3) - phiSkew;

%% 8. Transform true angular rate into FOG frame
%
% Zhang Eq. (12)

OmegaF_true = ...
    (C_A_F*OmegaA_FOG.').';

%% 9. FOG model using MATLAB imuSensor

biasFOG_deg_h = 0.1;

biasFOG_rad_s = ...
    biasFOG_deg_h*pi/180/3600;

biasFOG = ...
    [biasFOG_rad_s ...
     biasFOG_rad_s ...
     biasFOG_rad_s];

paramsFOG = gyroparams;

paramsFOG.ConstantBias = biasFOG;

imuFOG = imuSensor( ...
    'SampleRate',FsFOG, ...
    'Gyroscope',paramsFOG);

accFOG = zeros(NFOG,3);

[~,OmegaFOG] = ...
    imuFOG(accFOG,OmegaF_true);

%% 10. Synchronize FOG and CAIG

OmegaFOGatCAIG = ...
    OmegaFOG(idxCAIGinFOG,:);

%% 11. FOG - CAIG observation

deltaOmega = ...
    OmegaFOGatCAIG - OmegaCAIG;

%% 12. Analytical Zhang Eq. (16)

phiMatrix = ...
    repmat(phi.',NCAIG,1);

misalignmentTerm = ...
    cross(OmegaA_CAIG,phiMatrix,2);

expectedDeltaOmega = ...
    misalignmentTerm + biasFOG;

observationError = ...
    max(abs( ...
        deltaOmega-expectedDeltaOmega),...
        [],1);

%% 13. Misalignment sensitivity diagnostic
%
% Build stacked [omega x] matrices.
%
% This checks whether the triaxial motion excites all three
% misalignment parameters.
%
% It is NOT yet the complete six-state Kalman observability test.

Hphi = zeros(3*NCAIG,3);

for k = 1:NCAIG

    wx = OmegaA_CAIG(k,1);
    wy = OmegaA_CAIG(k,2);
    wz = OmegaA_CAIG(k,3);

    Hphi(3*k-2:3*k,:) = ...
        [ 0   -wz   wy;
          wz   0   -wx;
         -wy   wx   0 ];

end

rankHphi = rank(Hphi);

%% 14. Convert for plotting

OmegaA_deg_s = ...
    OmegaA_CAIG*180/pi;

misalignment_deg_h = ...
    misalignmentTerm*180/pi*3600;

deltaOmega_deg_h = ...
    deltaOmega*180/pi*3600;

%% 15. Display results

fprintf('\n');
fprintf('============================================\n');
fprintf('CAIG V2.3 - TRIAXIAL SWAY\n');
fprintf('============================================\n');

fprintf('\nZHANG LEVEL-2 SWAY\n');

fprintf('Roll    = %.2f deg / %.2f s\n',...
    rollAmpDeg,rollPeriod);

fprintf('Pitch   = %.2f deg / %.2f s\n',...
    pitchAmpDeg,pitchPeriod);

fprintf('Heading = %.2f deg / %.2f s\n',...
    headingAmpDeg,headingPeriod);

fprintf('\nMAXIMUM BODY ANGULAR RATE\n');

fprintf('X = %.6f deg/s\n',...
    max(abs(OmegaA_deg_s(:,1))));

fprintf('Y = %.6f deg/s\n',...
    max(abs(OmegaA_deg_s(:,2))));

fprintf('Z = %.6f deg/s\n',...
    max(abs(OmegaA_deg_s(:,3))));

fprintf('\nMAXIMUM MISALIGNMENT CONTRIBUTION\n');

fprintf('X = %.6f deg/h\n',...
    max(abs(misalignment_deg_h(:,1))));

fprintf('Y = %.6f deg/h\n',...
    max(abs(misalignment_deg_h(:,2))));

fprintf('Z = %.6f deg/h\n',...
    max(abs(misalignment_deg_h(:,3))));

fprintf('\nEQ. (16) VERIFICATION\n');

fprintf('X error = %.3e rad/s\n',...
    observationError(1));

fprintf('Y error = %.3e rad/s\n',...
    observationError(2));

fprintf('Z error = %.3e rad/s\n',...
    observationError(3));

fprintf('\nMISALIGNMENT SENSITIVITY\n');

fprintf('rank(stacked [omega x]) = %d / 3\n',...
    rankHphi);

%% 16. Plots

figure;

% ------------------------------------------------------------
% Sway angles
% ------------------------------------------------------------

subplot(4,1,1)

plot(tFOG,rad2deg(roll),'LineWidth',1.2)
hold on
plot(tFOG,rad2deg(pitch),'--','LineWidth',1.2)
plot(tFOG,rad2deg(heading),':','LineWidth',1.5)

grid on

ylabel('Angle [deg]')

legend( ...
    'Roll',...
    'Pitch',...
    'Heading',...
    'Location','best')

title('Zhang Level-2 Triaxial Sway')

% ------------------------------------------------------------
% Body angular velocity
% ------------------------------------------------------------

subplot(4,1,2)

plot(tCAIG,OmegaA_deg_s(:,1),'LineWidth',1.2)
hold on
plot(tCAIG,OmegaA_deg_s(:,2),'--','LineWidth',1.2)
plot(tCAIG,OmegaA_deg_s(:,3),':','LineWidth',1.5)

grid on

ylabel('\omega [deg/s]')

legend( ...
    '\omega_x',...
    '\omega_y',...
    '\omega_z',...
    'Location','best')

title('Body Angular Velocity at CAIG Epochs')

% ------------------------------------------------------------
% Misalignment contribution
% ------------------------------------------------------------

subplot(4,1,3)

plot(tCAIG,misalignment_deg_h(:,1),'LineWidth',1.2)
hold on
plot(tCAIG,misalignment_deg_h(:,2),'--','LineWidth',1.2)
plot(tCAIG,misalignment_deg_h(:,3),':','LineWidth',1.5)

grid on

ylabel('Misalignment [deg/h]')

legend('X','Y','Z','Location','best')

title('[\omega_A \times]\phi_a')

% ------------------------------------------------------------
% Complete observation
% ------------------------------------------------------------

subplot(4,1,4)

plot(tCAIG,deltaOmega_deg_h(:,1),'LineWidth',1.2)
hold on
plot(tCAIG,deltaOmega_deg_h(:,2),'--','LineWidth',1.2)
plot(tCAIG,deltaOmega_deg_h(:,3),':','LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('\delta\omega [deg/h]')

legend( ...
    '\delta\omega_x',...
    '\delta\omega_y',...
    '\delta\omega_z',...
    'Location','best')

title('imuSensor FOG - CAIG Observation')

%% 17. Full six-state measurement sensitivity

Hfull = zeros(3*NCAIG,6);

for k = 1:NCAIG

    wx = OmegaA_CAIG(k,1);
    wy = OmegaA_CAIG(k,2);
    wz = OmegaA_CAIG(k,3);

    omegaSkew = ...
        [ 0   -wz   wy;
          wz   0   -wx;
         -wy   wx   0 ];

    Hfull(3*k-2:3*k,:) = ...
        [omegaSkew eye(3)];

end

rankHfull = rank(Hfull);

fprintf('\nFULL SIX-STATE SENSITIVITY\n');
fprintf('rank(stacked H) = %d / 6\n',rankHfull);