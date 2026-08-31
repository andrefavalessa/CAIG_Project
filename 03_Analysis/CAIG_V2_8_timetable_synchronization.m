%% CAIG_V2_8_timetable_synchronization.m
%
% Validation of MATLAB timetable-based synchronization
% for the hybrid CAIG + FOG architecture.
%
% Main goals:
%
% 1) Represent FOG (100 Hz) and CAIG (5 Hz) as independent
%    timestamped sensor streams.
%
% 2) Replace manual indexing:
%
%       1:20:end
%
%    with MATLAB timetable tools.
%
% 3) Validate:
%
%       retime
%       synchronize
%
% 4) Demonstrate why synchronization matters when the CAIG
%    timestamps do not fall exactly on the FOG sampling grid.
%
%
% IMPORTANT:
%
% This script intentionally contains:
%
%   - no measurement noise
%   - no FOG bias
%   - no misalignment
%   - no Kalman filter
%
% The purpose is ONLY to isolate the time-management layer.
%
%
% DATA RATES:
%
%   FOG  = 100 Hz   (Zhang et al.)
%   CAIG =   5 Hz   (Zhang et al.)
%
%
% TEST CASES:
%
% A) Perfectly aligned clocks
%
% B) CAIG epochs shifted by 5 ms
%
% The 5 ms offset is only a synchronization test choice.
% It is NOT a claimed delay of the Zhang experiment.

clear;
clc;
close all;

%% ============================================================
% 1. GENERAL SETTINGS
% =============================================================

duration = 120;       % [s]

FsFOG  = 100;         % [Hz]
FsCAIG = 5;           % [Hz]

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
fprintf('CAIG V2.8 - TIMETABLE SYNCHRONIZATION\n');
fprintf('============================================\n\n');

fprintf('Duration         = %.1f s\n',duration);
fprintf('FOG sample rate  = %.1f Hz\n',FsFOG);
fprintf('CAIG sample rate = %.1f Hz\n',FsCAIG);
fprintf('FOG / CAIG ratio = %.0f\n\n',sampleRatio);

%% ============================================================
% 2. DETERMINISTIC TRUE ANGULAR MOTION
% =============================================================

% Use the same Zhang level-2 triaxial sway model already used
% in the previous project versions.
%
% Zhang gives amplitudes and periods.
% The sinusoidal waveform remains our simulation assumption.

OmegaFOG_true = ...
    generateLevel2Sway(tFOG);

OmegaCAIG_true_A = ...
    generateLevel2Sway(tCAIG);

fprintf('Maximum true angular rates\n');

fprintf('X = %.6f deg/s\n', ...
    max(abs(rad2deg(OmegaCAIG_true_A(:,1)))));

fprintf('Y = %.6f deg/s\n', ...
    max(abs(rad2deg(OmegaCAIG_true_A(:,2)))));

fprintf('Z = %.6f deg/s\n\n', ...
    max(abs(rad2deg(OmegaCAIG_true_A(:,3)))));

%% ============================================================
% 3. CREATE FOG TIMETABLE
% =============================================================

% Timetable row times must be datetime or duration.
%
% Our simulation starts at t = 0, so duration is convenient.

timeFOG = ...
    seconds(tFOG);

TT_FOG = ...
    timetable( ...
        OmegaFOG_true(:,1), ...
        OmegaFOG_true(:,2), ...
        OmegaFOG_true(:,3), ...
        ...
        'RowTimes',timeFOG, ...
        ...
        'VariableNames',{ ...
            'FOG_X', ...
            'FOG_Y', ...
            'FOG_Z'});

fprintf('FOG timetable created\n');
fprintf('Rows = %d\n',height(TT_FOG));
fprintf('Variables = %d\n\n',width(TT_FOG));

%% ============================================================
% 4. CASE A - PERFECTLY ALIGNED CAIG CLOCK
% =============================================================

fprintf('============================================\n');
fprintf('CASE A - PERFECTLY ALIGNED CLOCKS\n');
fprintf('============================================\n\n');

timeCAIG_A = ...
    seconds(tCAIG);

TT_CAIG_A = ...
    timetable( ...
        OmegaCAIG_true_A(:,1), ...
        OmegaCAIG_true_A(:,2), ...
        OmegaCAIG_true_A(:,3), ...
        ...
        'RowTimes',timeCAIG_A, ...
        ...
        'VariableNames',{ ...
            'CAIG_X', ...
            'CAIG_Y', ...
            'CAIG_Z'});

fprintf('CAIG timetable created\n');
fprintf('Rows = %d\n\n',height(TT_CAIG_A));

%% ============================================================
% 5. RETIME FOG TO CAIG EPOCHS
% =============================================================

% Instead of:
%
%       OmegaFOG(1:20:end,:)
%
% we explicitly ask MATLAB:
%
%       "evaluate the FOG data at the CAIG timestamps"
%
% Linear interpolation is selected.
%
% In Case A, every CAIG timestamp already coincides exactly
% with a FOG timestamp, so interpolation should not actually
% change the values.

TT_FOG_at_CAIG_A = ...
    retime( ...
        TT_FOG, ...
        TT_CAIG_A.Properties.RowTimes, ...
        'linear');

FOG_at_CAIG_A = ...
    [ ...
        TT_FOG_at_CAIG_A.FOG_X, ...
        TT_FOG_at_CAIG_A.FOG_Y, ...
        TT_FOG_at_CAIG_A.FOG_Z ...
    ];

errorRetime_A = ...
    FOG_at_CAIG_A ...
    - OmegaCAIG_true_A;

maxErrorRetime_A = ...
    max(abs(errorRetime_A),[],1);

%% ============================================================
% 6. CHECK TIMESTAMPS
% =============================================================

timeError_A = ...
    TT_FOG_at_CAIG_A.Properties.RowTimes ...
    - TT_CAIG_A.Properties.RowTimes;

maxTimeError_A = ...
    max(abs(seconds(timeError_A)));

fprintf('RETIME RESULTS\n');
fprintf('--------------------------------------------\n');

fprintf('Maximum timestamp difference = %.6e s\n\n', ...
    maxTimeError_A);

fprintf('Maximum angular-rate error\n');

fprintf('X = %.6e rad/s\n', ...
    maxErrorRetime_A(1));

fprintf('Y = %.6e rad/s\n', ...
    maxErrorRetime_A(2));

fprintf('Z = %.6e rad/s\n\n', ...
    maxErrorRetime_A(3));

%% ============================================================
% 7. SYNCHRONIZE BOTH TIMETABLES
% =============================================================

% synchronize can combine the two sensor streams directly
% using the CAIG timestamps as the output time vector.

TT_SYNC_A = ...
    synchronize( ...
        TT_FOG, ...
        TT_CAIG_A, ...
        TT_CAIG_A.Properties.RowTimes, ...
        'linear');

FOG_sync_A = ...
    [ ...
        TT_SYNC_A.FOG_X, ...
        TT_SYNC_A.FOG_Y, ...
        TT_SYNC_A.FOG_Z ...
    ];

CAIG_sync_A = ...
    [ ...
        TT_SYNC_A.CAIG_X, ...
        TT_SYNC_A.CAIG_Y, ...
        TT_SYNC_A.CAIG_Z ...
    ];

errorSync_A = ...
    FOG_sync_A ...
    - CAIG_sync_A;

maxErrorSync_A = ...
    max(abs(errorSync_A),[],1);

fprintf('SYNCHRONIZE RESULTS\n');
fprintf('--------------------------------------------\n');

fprintf('Maximum FOG - CAIG difference\n');

fprintf('X = %.6e rad/s\n', ...
    maxErrorSync_A(1));

fprintf('Y = %.6e rad/s\n', ...
    maxErrorSync_A(2));

fprintf('Z = %.6e rad/s\n\n', ...
    maxErrorSync_A(3));

%% ============================================================
% 8. CHECK RETIME VS SYNCHRONIZE
% =============================================================

% Both methods should give the same FOG values at CAIG epochs.

methodDifference_A = ...
    FOG_at_CAIG_A ...
    - FOG_sync_A;

maxMethodDifference_A = ...
    max(abs(methodDifference_A),[],1);

fprintf('RETIME vs SYNCHRONIZE\n');
fprintf('--------------------------------------------\n');

fprintf('X difference = %.6e rad/s\n', ...
    maxMethodDifference_A(1));

fprintf('Y difference = %.6e rad/s\n', ...
    maxMethodDifference_A(2));

fprintf('Z difference = %.6e rad/s\n\n', ...
    maxMethodDifference_A(3));

%% ============================================================
% 9. COMPARE WITH OLD MANUAL INDEXING
% =============================================================

idxManual = ...
    1:sampleRatio:NFOG;

OmegaFOG_manual = ...
    OmegaFOG_true(idxManual,:);

errorManual_A = ...
    OmegaFOG_manual ...
    - OmegaCAIG_true_A;

maxErrorManual_A = ...
    max(abs(errorManual_A),[],1);

fprintf('OLD MANUAL INDEXING - ALIGNED CASE\n');
fprintf('--------------------------------------------\n');

fprintf('X error = %.6e rad/s\n', ...
    maxErrorManual_A(1));

fprintf('Y error = %.6e rad/s\n', ...
    maxErrorManual_A(2));

fprintf('Z error = %.6e rad/s\n\n', ...
    maxErrorManual_A(3));

%% ============================================================
% 10. CASE B - INDEPENDENT CAIG TIMESTAMPS
% =============================================================

fprintf('============================================\n');
fprintf('CASE B - CAIG CLOCK OFFSET\n');
fprintf('============================================\n\n');

% Artificial test offset:
%
%       5 ms
%
% This deliberately places each CAIG epoch halfway between
% adjacent 100-Hz FOG samples.
%
% FOG period:
%
%       10 ms
%
% so a 5-ms shift is a useful interpolation test.

timeOffset = ...
    0.005;        % [s]

tCAIG_B = ...
    tCAIG ...
    + timeOffset;

fprintf('Artificial CAIG clock offset = %.3f ms\n\n', ...
    timeOffset*1000);

%% ============================================================
% 11. TRUE CAIG VALUES AT ITS ACTUAL EPOCHS
% =============================================================

% This is important:
%
% The CAIG measurement values are generated at the shifted
% timestamps themselves.
%
% Therefore this is NOT intentionally mis-tagged data.
%
% We are representing two valid sensors whose sampling epochs
% are simply different.

OmegaCAIG_true_B = ...
    generateLevel2Sway(tCAIG_B);

timeCAIG_B = ...
    seconds(tCAIG_B);

TT_CAIG_B = ...
    timetable( ...
        OmegaCAIG_true_B(:,1), ...
        OmegaCAIG_true_B(:,2), ...
        OmegaCAIG_true_B(:,3), ...
        ...
        'RowTimes',timeCAIG_B, ...
        ...
        'VariableNames',{ ...
            'CAIG_X', ...
            'CAIG_Y', ...
            'CAIG_Z'});

%% ============================================================
% 12. CORRECT METHOD - RETIME FOG TO CAIG CLOCK
% =============================================================

TT_FOG_at_CAIG_B = ...
    retime( ...
        TT_FOG, ...
        TT_CAIG_B.Properties.RowTimes, ...
        'linear');

FOG_at_CAIG_B = ...
    [ ...
        TT_FOG_at_CAIG_B.FOG_X, ...
        TT_FOG_at_CAIG_B.FOG_Y, ...
        TT_FOG_at_CAIG_B.FOG_Z ...
    ];

% Compare interpolated FOG values with the exact analytical
% angular rate evaluated at the CAIG epochs.

errorRetime_B = ...
    FOG_at_CAIG_B ...
    - OmegaCAIG_true_B;

maxErrorRetime_B = ...
    max(abs(errorRetime_B),[],1);

fprintf('CORRECT TIMESTAMP-BASED RETIME\n');
fprintf('--------------------------------------------\n');

fprintf('Maximum interpolation error\n');

fprintf('X = %.6e rad/s\n', ...
    maxErrorRetime_B(1));

fprintf('Y = %.6e rad/s\n', ...
    maxErrorRetime_B(2));

fprintf('Z = %.6e rad/s\n\n', ...
    maxErrorRetime_B(3));

fprintf('Equivalent in deg/h\n');

fprintf('X = %.6e deg/h\n', ...
    rad2deg(maxErrorRetime_B(1))*3600);

fprintf('Y = %.6e deg/h\n', ...
    rad2deg(maxErrorRetime_B(2))*3600);

fprintf('Z = %.6e deg/h\n\n', ...
    rad2deg(maxErrorRetime_B(3))*3600);

%% ============================================================
% 13. SYNCHRONIZE TO CAIG TIMESTAMPS
% =============================================================

TT_SYNC_B = ...
    synchronize( ...
        TT_FOG, ...
        TT_CAIG_B, ...
        TT_CAIG_B.Properties.RowTimes, ...
        'linear');

FOG_sync_B = ...
    [ ...
        TT_SYNC_B.FOG_X, ...
        TT_SYNC_B.FOG_Y, ...
        TT_SYNC_B.FOG_Z ...
    ];

CAIG_sync_B = ...
    [ ...
        TT_SYNC_B.CAIG_X, ...
        TT_SYNC_B.CAIG_Y, ...
        TT_SYNC_B.CAIG_Z ...
    ];

errorSync_B = ...
    FOG_sync_B ...
    - CAIG_sync_B;

maxErrorSync_B = ...
    max(abs(errorSync_B),[],1);

fprintf('SYNCHRONIZE AT SHIFTED CAIG EPOCHS\n');
fprintf('--------------------------------------------\n');

fprintf('Maximum FOG - CAIG difference\n');

fprintf('X = %.6e rad/s\n', ...
    maxErrorSync_B(1));

fprintf('Y = %.6e rad/s\n', ...
    maxErrorSync_B(2));

fprintf('Z = %.6e rad/s\n\n', ...
    maxErrorSync_B(3));

%% ============================================================
% 14. CHECK RETIME VS SYNCHRONIZE AGAIN
% =============================================================

methodDifference_B = ...
    FOG_at_CAIG_B ...
    - FOG_sync_B;

maxMethodDifference_B = ...
    max(abs(methodDifference_B),[],1);

fprintf('RETIME vs SYNCHRONIZE - OFFSET CASE\n');
fprintf('--------------------------------------------\n');

fprintf('X difference = %.6e rad/s\n', ...
    maxMethodDifference_B(1));

fprintf('Y difference = %.6e rad/s\n', ...
    maxMethodDifference_B(2));

fprintf('Z difference = %.6e rad/s\n\n', ...
    maxMethodDifference_B(3));

%% ============================================================
% 15. WRONG APPROACH - IGNORE THE TIMESTAMP OFFSET
% =============================================================

% Now reproduce the weakness of:
%
%       1:20:end
%
% If the CAIG epochs are shifted by 5 ms but we blindly select
% every 20th FOG sample starting at t = 0, we compare:
%
%       FOG(t)
%
% against
%
%       CAIG(t + 5 ms)
%
% Those measurements do not represent the same physical epoch.

OmegaFOG_naive_B = ...
    OmegaFOG_true(idxManual,:);

errorNaive_B = ...
    OmegaFOG_naive_B ...
    - OmegaCAIG_true_B;

maxErrorNaive_B = ...
    max(abs(errorNaive_B),[],1);

fprintf('NAIVE 1:20:end WITH 5-ms OFFSET\n');
fprintf('--------------------------------------------\n');

fprintf('Maximum synchronization-induced error\n');

fprintf('X = %.6e rad/s\n', ...
    maxErrorNaive_B(1));

fprintf('Y = %.6e rad/s\n', ...
    maxErrorNaive_B(2));

fprintf('Z = %.6e rad/s\n\n', ...
    maxErrorNaive_B(3));

fprintf('Equivalent in deg/h\n');

fprintf('X = %.6f deg/h\n', ...
    rad2deg(maxErrorNaive_B(1))*3600);

fprintf('Y = %.6f deg/h\n', ...
    rad2deg(maxErrorNaive_B(2))*3600);

fprintf('Z = %.6f deg/h\n\n', ...
    rad2deg(maxErrorNaive_B(3))*3600);

%% ============================================================
% 16. ERROR REDUCTION
% =============================================================

reductionFactor = ...
    maxErrorNaive_B ...
    ./ maxErrorRetime_B;

fprintf('ERROR REDUCTION USING TIMESTAMP SYNCHRONIZATION\n');
fprintf('--------------------------------------------\n');

fprintf('X = %.3e times smaller\n', ...
    reductionFactor(1));

fprintf('Y = %.3e times smaller\n', ...
    reductionFactor(2));

fprintf('Z = %.3e times smaller\n\n', ...
    reductionFactor(3));

%% ============================================================
% 17. SUMMARY
% =============================================================

fprintf('============================================\n');
fprintf('SUMMARY\n');
fprintf('============================================\n\n');

fprintf('CASE A - aligned clocks\n');

fprintf('retime max error [rad/s] = ');
fprintf('%.3e %.3e %.3e\n', ...
    maxErrorRetime_A);

fprintf('synchronize max error [rad/s] = ');
fprintf('%.3e %.3e %.3e\n\n', ...
    maxErrorSync_A);


fprintf('CASE B - 5 ms independent clock offset\n');

fprintf('timestamp-based retime error [rad/s] = ');
fprintf('%.3e %.3e %.3e\n', ...
    maxErrorRetime_B);

fprintf('naive indexing error [rad/s] = ');
fprintf('%.3e %.3e %.3e\n\n', ...
    maxErrorNaive_B);

%% ============================================================
% 18. PLOT - CASE B SYNCHRONIZATION ERROR
% =============================================================

errorRetimeDegH = ...
    rad2deg(errorRetime_B)*3600;

errorNaiveDegH = ...
    rad2deg(errorNaive_B)*3600;

figure;

subplot(3,1,1);

plot( ...
    tCAIG_B, ...
    errorNaiveDegH(:,1), ...
    'LineWidth',1.1);

hold on;

plot( ...
    tCAIG_B, ...
    errorRetimeDegH(:,1), ...
    'LineWidth',1.1);

xlabel('Time [s]');
ylabel('Error X [deg/h]');
title('Timestamp Synchronization: Naive Indexing vs retime');
legend('Naive indexing','timetable + retime');
grid on;


subplot(3,1,2);

plot( ...
    tCAIG_B, ...
    errorNaiveDegH(:,2), ...
    'LineWidth',1.1);

hold on;

plot( ...
    tCAIG_B, ...
    errorRetimeDegH(:,2), ...
    'LineWidth',1.1);

xlabel('Time [s]');
ylabel('Error Y [deg/h]');
legend('Naive indexing','timetable + retime');
grid on;


subplot(3,1,3);

plot( ...
    tCAIG_B, ...
    errorNaiveDegH(:,3), ...
    'LineWidth',1.1);

hold on;

plot( ...
    tCAIG_B, ...
    errorRetimeDegH(:,3), ...
    'LineWidth',1.1);

xlabel('Time [s]');
ylabel('Error Z [deg/h]');
legend('Naive indexing','timetable + retime');
grid on;

%% ============================================================
% LOCAL FUNCTION
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

    % Sinusoidal attitudes are a project simulation assumption.

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

    % 3-2-1 Euler-angle rates -> body rates

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