clear;
clc;
close all;

%% CAIG V2.1 - CAIG + conventional gyro using imuSensor
%
% CAIG:
%   Ideal angular-rate output based on the CAIG model already
%   validated in V1.
%
% Conventional gyro:
%   Generated using MATLAB Navigation Toolbox:
%       gyroparams
%       imuSensor
%
% Zhang et al. (2019):
%   CAIG data rate = 5 Hz
%   FOG data rate  = 100 Hz
%   CAIG bias      = negligible
%   FOG bias       = 0.1 deg/h
%
% No noise.
% No misalignment.
% No Kalman filter.

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

%% 2. Synthetic ground-truth angular motion
%
% Same test motion used in V1.
%
% These are simulation choices, not sensor parameters.

Omega0 = 1e-5;                 % [rad/s]
f = 0.1;                       % [Hz]

OmegaTrueFOG = zeros(NFOG,3);
OmegaTrueCAIG = zeros(NCAIG,3);

% Rotation around Y only

OmegaTrueFOG(:,2) = ...
    Omega0*sin(2*pi*f*tFOG);

OmegaTrueCAIG(:,2) = ...
    Omega0*sin(2*pi*f*tCAIG);

%% 3. Ideal CAIG output
%
% In Zhang's monitoring simulation, the CAIG bias is assumed
% constant and negligible.
%
% V1 already validated the internal CAIG phase model.
% Here we work with its equivalent angular-rate output.

OmegaCAIG = OmegaTrueCAIG;

%% 4. FOG bias from Zhang et al.
%
% Given in the paper:
%
%     0.1 deg/h
%
% gyroparams.ConstantBias requires rad/s.

biasFOG_deg_h = 0.1;

biasFOG_rad_s = ...
    biasFOG_deg_h*pi/180/3600;

% Same bias on the three gyro axes

biasFOG = ...
    [biasFOG_rad_s ...
     biasFOG_rad_s ...
     biasFOG_rad_s];

%% 5. Configure conventional gyro using gyroparams
%
% MATLAB Navigation Toolbox
%
% All other gyro parameters remain at their ideal defaults:
%
%   NoiseDensity      = 0
%   BiasInstability   = 0
%   RandomWalk        = 0
%   AxesMisalignment = 0
%   Resolution        = 0
%
% Therefore V2.1 isolates ONLY the constant bias effect.

paramsFOG = gyroparams;

paramsFOG.ConstantBias = biasFOG;

%% 6. Create synthetic IMU
%
% Only the gyroscope output is used in this simulation.

imuFOG = imuSensor( ...
    'SampleRate',FsFOG, ...
    'Gyroscope',paramsFOG);

%% 7. Generate conventional gyro data
%
% The imuSensor call requires acceleration and angular velocity.
%
% Linear acceleration is set to zero because this test concerns
% only the gyroscope.

accFOG = zeros(NFOG,3);

[~,OmegaFOG] = ...
    imuFOG(accFOG,OmegaTrueFOG);

%% 8. Synchronize FOG with CAIG measurement epochs
%
% FOG  = 100 Hz
% CAIG =   5 Hz
%
% Therefore:
%
%       20 FOG samples / CAIG sample

sampleRatio = FsFOG/FsCAIG;

idxCAIGinFOG = ...
    1:sampleRatio:NFOG;

OmegaFOGatCAIG = ...
    OmegaFOG(idxCAIGinFOG,:);

OmegaTrueAtCAIG = ...
    OmegaTrueFOG(idxCAIGinFOG,:);

%% 9. FOG - CAIG observation

deltaOmega = ...
    OmegaFOGatCAIG - OmegaCAIG;

%% 10. Expected result
%
% Since:
%
%   CAIG bias = 0
%   FOG bias  = constant
%   noise     = 0
%   misalignment = 0
%
% we expect:
%
%       deltaOmega = biasFOG

expectedBias = ...
    repmat(biasFOG,NCAIG,1);

biasError = ...
    max(abs(deltaOmega-expectedBias),[],1);

%% 11. Check sample-time synchronization

timeSyncError = ...
    max(abs(tFOG(idxCAIGinFOG)-tCAIG));

%% 12. Display results

fprintf('\n');
fprintf('============================================\n');
fprintf('CAIG V2.1 - imuSensor + CAIG\n');
fprintf('============================================\n');

fprintf('\nDATA RATES\n');

fprintf('CAIG = %.1f Hz\n',FsCAIG);
fprintf('FOG  = %.1f Hz\n',FsFOG);

fprintf('\nMATLAB FOG MODEL\n');

fprintf('Model: imuSensor + gyroparams\n');

fprintf('\nFOG BIAS\n');

fprintf('Bias = %.6f deg/h\n',...
    biasFOG_deg_h);

fprintf('Bias = %.6e rad/s\n',...
    biasFOG_rad_s);

fprintf('\nSAMPLING\n');

fprintf('FOG samples  = %d\n',NFOG);
fprintf('CAIG samples = %d\n',NCAIG);

fprintf('FOG samples per CAIG sample = %d\n',...
    sampleRatio);

fprintf('Maximum synchronization error = %.3e s\n',...
    timeSyncError);

fprintf('\nNUMERICAL VERIFICATION\n');

fprintf('X-axis bias error = %.3e rad/s\n',...
    biasError(1));

fprintf('Y-axis bias error = %.3e rad/s\n',...
    biasError(2));

fprintf('Z-axis bias error = %.3e rad/s\n',...
    biasError(3));

%% 13. Plots

figure;

%% Ground truth and sensor outputs

subplot(3,1,1)

plot( ...
    tFOG,...
    OmegaTrueFOG(:,2),...
    'LineWidth',1.5)

hold on

plot( ...
    tFOG,...
    OmegaFOG(:,2),...
    '--',...
    'LineWidth',1.2)

plot( ...
    tCAIG,...
    OmegaCAIG(:,2),...
    'o',...
    'MarkerSize',4)

grid on

xlabel('Time [s]')
ylabel('\omega_y [rad/s]')

legend( ...
    'Ground truth',...
    'imuSensor FOG - 100 Hz',...
    'CAIG - 5 Hz',...
    'Location','best')

title('Ground Truth, imuSensor FOG and CAIG')

%% Sensor errors

subplot(3,1,2)

FOGerror = ...
    OmegaFOG - OmegaTrueFOG;

CAIGerror = ...
    OmegaCAIG - OmegaTrueCAIG;

FOGerror_deg_h = ...
    FOGerror*180/pi*3600;

CAIGerror_deg_h = ...
    CAIGerror*180/pi*3600;

plot( ...
    tFOG,...
    FOGerror_deg_h(:,2),...
    'LineWidth',1.5)

hold on

plot( ...
    tCAIG,...
    CAIGerror_deg_h(:,2),...
    'o',...
    'MarkerSize',4)

grid on

xlabel('Time [s]')
ylabel('Error [deg/h]')

legend( ...
    'imuSensor FOG error',...
    'CAIG error',...
    'Location','best')

title('Sensor Measurement Error')

%% FOG - CAIG difference

subplot(3,1,3)

deltaOmega_deg_h = ...
    deltaOmega*180/pi*3600;

plot( ...
    tCAIG,...
    deltaOmega_deg_h(:,1),...
    'LineWidth',1.2)

hold on

plot( ...
    tCAIG,...
    deltaOmega_deg_h(:,2),...
    '--',...
    'LineWidth',1.2)

plot( ...
    tCAIG,...
    deltaOmega_deg_h(:,3),...
    ':',...
    'LineWidth',1.5)

grid on

ylim([0.095 0.105])

xlabel('Time [s]')
ylabel('\delta\omega [deg/h]')

legend( ...
    '\delta\omega_x',...
    '\delta\omega_y',...
    '\delta\omega_z',...
    'Location','best')

title('imuSensor FOG - CAIG at CAIG Epochs')