clear;
clc;
close all;

%% CAIG V2.7 - Synchronization Test
%
% PURPOSE:
%
% Study the effect of a time-label mismatch between:
%
%   FOG  = 100 Hz
%   CAIG =   5 Hz
%
% Two synchronization methods are compared:
%
% 1) Index matching:
%       take every 20th FOG sample
%
% 2) Timestamp interpolation:
%       interpolate FOG data at the actual CAIG timestamps
%
% IMPORTANT:
%
% Zhang et al. state that FOG and CAIG outputs must be
% synchronized by data processing, but do not specify the
% exact synchronization algorithm.
%
% Therefore, linear interpolation is a simulation choice.
%
% No noise.
% No bias.
% No misalignment.
% No Kalman filter.
%
% This isolates ONLY synchronization error.

%% 1. Simulation parameters

duration = 120;        % [s]

FsFOG  = 100;          % [Hz], Zhang
FsCAIG = 5;            % [Hz], Zhang

tFOG = ...
    (0:1/FsFOG:duration-1/FsFOG).';

tCAIG_nominal = ...
    (0:1/FsCAIG:duration-1/FsCAIG).';

NFOG  = length(tFOG);
NCAIG = length(tCAIG_nominal);

sampleRatio = ...
    FsFOG/FsCAIG;

idxCAIGinFOG = ...
    1:sampleRatio:NFOG;

%% 2. Zhang level-2 sway parameters

rollAmpDeg    = 0.50;
pitchAmpDeg   = 0.20;
headingAmpDeg = 0.30;

rollPeriod    = 20.00;   % [s]
pitchPeriod   = 30.00;   % [s]
headingPeriod = 30.00;   % [s]

rollAmp    = deg2rad(rollAmpDeg);
pitchAmp   = deg2rad(pitchAmpDeg);
headingAmp = deg2rad(headingAmpDeg);

%% 3. Generate FOG-rate ground truth at 100 Hz
%
% Same triaxial sway model used in V2.3-V2.6.

OmegaFOG = bodyRateFromSway( ...
    tFOG, ...
    rollAmp, ...
    pitchAmp, ...
    headingAmp, ...
    rollPeriod, ...
    pitchPeriod, ...
    headingPeriod);

%% ========================================================================
% PART A - PERFECTLY SYNCHRONIZED CASE
% ========================================================================

%% 4. CAIG ground truth at nominal timestamps

OmegaCAIG_aligned = bodyRateFromSway( ...
    tCAIG_nominal, ...
    rollAmp, ...
    pitchAmp, ...
    headingAmp, ...
    rollPeriod, ...
    pitchPeriod, ...
    headingPeriod);

%% 5. Method 1 - Index matching

OmegaFOG_index = ...
    OmegaFOG(idxCAIGinFOG,:);

%% 6. Method 2 - Timestamp interpolation

OmegaFOG_interp = ...
    interp1( ...
    tFOG, ...
    OmegaFOG, ...
    tCAIG_nominal, ...
    'linear');

%% 7. Errors for perfect synchronization

errorIndexAligned = ...
    OmegaFOG_index - OmegaCAIG_aligned;

errorInterpAligned = ...
    OmegaFOG_interp - OmegaCAIG_aligned;

maxIndexAligned = ...
    max(abs(errorIndexAligned),[],1);

maxInterpAligned = ...
    max(abs(errorInterpAligned),[],1);

%% ========================================================================
% PART B - ARTIFICIAL TIME-LABEL OFFSET
% ========================================================================

%% 8. Test several clock offsets
%
% These values are SIMULATION CHOICES.
%
% They are not given by Zhang.

delay_ms = ...
    [0 2 5 10 20 50];

delay_s = ...
    delay_ms*1e-3;

nDelays = ...
    length(delay_s);

%% 9. Storage

maxIndexError = ...
    zeros(nDelays,3);

maxInterpError = ...
    zeros(nDelays,3);

rmsIndexError = ...
    zeros(nDelays,3);

rmsInterpError = ...
    zeros(nDelays,3);

%% 10. Delay loop

for d = 1:nDelays

    delay = ...
        delay_s(d);

    % ------------------------------------------------------------
    % Actual CAIG timestamps
    %
    % Example:
    %
    % nominal = 10.000 s
    % actual  = 10.010 s
    %
    % when delay = 10 ms
    % ------------------------------------------------------------

    tCAIG_actual = ...
        tCAIG_nominal + delay;

    %% Actual CAIG measurement
    %
    % Computed analytically at the shifted timestamps.

    OmegaCAIG_actual = bodyRateFromSway( ...
        tCAIG_actual, ...
        rollAmp, ...
        pitchAmp, ...
        headingAmp, ...
        rollPeriod, ...
        pitchPeriod, ...
        headingPeriod);

    %% Method 1 - Naive index matching
    %
    % This method ignores the clock offset.
    %
    % It assumes that the CAIG measurement occurred at
    % tCAIG_nominal.

    OmegaFOG_naive = ...
        OmegaFOG(idxCAIGinFOG,:);

    %% Method 2 - Timestamp-aware interpolation
    %
    % Use the ACTUAL CAIG timestamps.

    OmegaFOG_timestamp = ...
        interp1( ...
        tFOG, ...
        OmegaFOG, ...
        tCAIG_actual, ...
        'linear');

    %% Synchronization errors

    errorIndex = ...
        OmegaFOG_naive ...
        - OmegaCAIG_actual;

    errorInterp = ...
        OmegaFOG_timestamp ...
        - OmegaCAIG_actual;

    %% Maximum error

    maxIndexError(d,:) = ...
        max(abs(errorIndex),[],1);

    maxInterpError(d,:) = ...
        max(abs(errorInterp),[],1);

    %% RMS error

    rmsIndexError(d,:) = ...
        sqrt(mean(errorIndex.^2,1));

    rmsInterpError(d,:) = ...
        sqrt(mean(errorInterp.^2,1));

end

%% 11. Convert synchronization errors to deg/h
%
% This unit makes comparison with the 0.1 deg/h FOG bias
% used by Zhang easier.

maxIndex_deg_h = ...
    maxIndexError*180/pi*3600;

maxInterp_deg_h = ...
    maxInterpError*180/pi*3600;

rmsIndex_deg_h = ...
    rmsIndexError*180/pi*3600;

rmsInterp_deg_h = ...
    rmsInterpError*180/pi*3600;

%% 12. Display perfect-synchronization test

fprintf('\n');
fprintf('============================================\n');
fprintf('CAIG V2.7 - SYNCHRONIZATION TEST\n');
fprintf('============================================\n');

fprintf('\nPERFECTLY ALIGNED TIMESTAMPS\n');

fprintf('\nIndex matching maximum error [rad/s]\n');

fprintf('X = %.3e\n',maxIndexAligned(1));
fprintf('Y = %.3e\n',maxIndexAligned(2));
fprintf('Z = %.3e\n',maxIndexAligned(3));

fprintf('\nTimestamp interpolation maximum error [rad/s]\n');

fprintf('X = %.3e\n',maxInterpAligned(1));
fprintf('Y = %.3e\n',maxInterpAligned(2));
fprintf('Z = %.3e\n',maxInterpAligned(3));

%% 13. Display delay study

fprintf('\n');
fprintf('============================================\n');
fprintf('TIME-LABEL OFFSET STUDY\n');
fprintf('============================================\n');

for d = 1:nDelays

    fprintf('\nDelay = %.1f ms\n',delay_ms(d));

    fprintf('Naive index MAX error [deg/h]\n');

    fprintf('X = %.6f\n',maxIndex_deg_h(d,1));
    fprintf('Y = %.6f\n',maxIndex_deg_h(d,2));
    fprintf('Z = %.6f\n',maxIndex_deg_h(d,3));

    fprintf('Timestamp interpolation MAX error [deg/h]\n');

    fprintf('X = %.6e\n',maxInterp_deg_h(d,1));
    fprintf('Y = %.6e\n',maxInterp_deg_h(d,2));
    fprintf('Z = %.6e\n',maxInterp_deg_h(d,3));

end

%% 14. Summary table - maximum error

SynchronizationTable = table( ...
    delay_ms.', ...
    maxIndex_deg_h(:,1), ...
    maxIndex_deg_h(:,2), ...
    maxIndex_deg_h(:,3), ...
    maxInterp_deg_h(:,1), ...
    maxInterp_deg_h(:,2), ...
    maxInterp_deg_h(:,3), ...
    'VariableNames',{ ...
    'Delay_ms', ...
    'IndexMax_X_deg_h', ...
    'IndexMax_Y_deg_h', ...
    'IndexMax_Z_deg_h', ...
    'InterpMax_X_deg_h', ...
    'InterpMax_Y_deg_h', ...
    'InterpMax_Z_deg_h'});

fprintf('\n');
fprintf('============================================\n');
fprintf('SYNCHRONIZATION SUMMARY\n');
fprintf('============================================\n');

disp(SynchronizationTable)

%% 15. Plot maximum synchronization error

figure;

plot( ...
    delay_ms, ...
    maxIndex_deg_h(:,1), ...
    '-o', ...
    'LineWidth',1.5)

hold on

plot( ...
    delay_ms, ...
    maxIndex_deg_h(:,2), ...
    '-s', ...
    'LineWidth',1.5)

plot( ...
    delay_ms, ...
    maxIndex_deg_h(:,3), ...
    '-^', ...
    'LineWidth',1.5)

yline(0.1,'--');

grid on

xlabel('Time-label offset [ms]')
ylabel('Maximum synchronization error [deg/h]')

legend( ...
    'X', ...
    'Y', ...
    'Z', ...
    '0.1 deg/h FOG bias', ...
    'Location','best')

title('Naive Index Synchronization Error')

%% 16. Plot RMS synchronization error

figure;

plot( ...
    delay_ms, ...
    rmsIndex_deg_h(:,1), ...
    '-o', ...
    'LineWidth',1.5)

hold on

plot( ...
    delay_ms, ...
    rmsIndex_deg_h(:,2), ...
    '-s', ...
    'LineWidth',1.5)

plot( ...
    delay_ms, ...
    rmsIndex_deg_h(:,3), ...
    '-^', ...
    'LineWidth',1.5)

yline(0.1,'--');

grid on

xlabel('Time-label offset [ms]')
ylabel('RMS synchronization error [deg/h]')

legend( ...
    'X', ...
    'Y', ...
    'Z', ...
    '0.1 deg/h FOG bias', ...
    'Location','best')

title('RMS Error Caused by Time-Label Mismatch')

%% 17. Compare naive and interpolation for X-axis

figure;

semilogy( ...
    delay_ms, ...
    maxIndex_deg_h(:,1), ...
    '-o', ...
    'LineWidth',1.5)

hold on

semilogy( ...
    delay_ms, ...
    maxInterp_deg_h(:,1), ...
    '-s', ...
    'LineWidth',1.5)

grid on

xlabel('Time-label offset [ms]')
ylabel('Maximum X error [deg/h]')

legend( ...
    'Index matching', ...
    'Timestamp interpolation', ...
    'Location','best')

title('Synchronization Method Comparison - X Axis')

%% ========================================================================
% LOCAL FUNCTION
% ========================================================================

function Omega = bodyRateFromSway( ...
    t, ...
    rollAmp, ...
    pitchAmp, ...
    headingAmp, ...
    rollPeriod, ...
    pitchPeriod, ...
    headingPeriod)

    %% Attitude angles

    roll = ...
        rollAmp*sin(2*pi*t/rollPeriod);

    pitch = ...
        pitchAmp*sin(2*pi*t/pitchPeriod);

    %% Euler-angle rates

    rollDot = ...
        rollAmp*(2*pi/rollPeriod).* ...
        cos(2*pi*t/rollPeriod);

    pitchDot = ...
        pitchAmp*(2*pi/pitchPeriod).* ...
        cos(2*pi*t/pitchPeriod);

    headingDot = ...
        headingAmp*(2*pi/headingPeriod).* ...
        cos(2*pi*t/headingPeriod);

    %% 3-2-1 Euler rates -> body angular velocity

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