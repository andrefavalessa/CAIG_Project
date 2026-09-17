% =============================================================
% CONSTANT-SPEED MONITORING BEHAVIOR
% =============================================================
%
% Purpose:
%
% Reproduce qualitatively the constant-speed behavior studied
% in Zhang et al. (2019), Section 4.1 / Figure 6.
%
% This is NOT intended to reproduce the exact numerical curves
% of Figure 6 because Zhang does not provide all simulation
% parameters, including numerical Q/R and initial geographic
% position.
%
%
% ZHANG PARAMETERS USED
% -------------------------------------------------------------
%
% Duration shown in Figure 6 = 10 min
% Heading                    = 30 deg
% Roll                       = 0 deg
% Pitch                      = 0 deg
% Vehicle speed              = 15 knots
%
% FOG bias                   = 0.1 deg/h
% Misalignment               = [1 2 3] deg
%
% Fs_FOG                     = 100 Hz
% Fs_CAIG                    = 5 Hz
%
% X0                         = zeros(6,1)
%
%
% PROJECT PARAMETERS
% -------------------------------------------------------------
%
% FOG white noise:
%   EMCORE EG-1300
%   ARW = 0.002 deg/sqrt(h)
%   NoiseType = 'single-sided'
%
% CAIG:
%   equivalent white-noise model based on Tackmann sensitivity
%
% Synchronization:
%   timetable + retime
%
%
% REPLICATION ASSUMPTIONS
% -------------------------------------------------------------
%
% Latitude = 45 deg
% Height   = 0 m
%
% WGS-84 is used to compute Earth and transport rotation.
%
%
% EXPECTED RESULT
% -------------------------------------------------------------
%
% Since the body angular-rate vector is essentially constant,
% H is constant.
%
% Therefore repeated observations do NOT provide enough
% independent excitation to identify all six states.
%
% We expect:
%
%   - stacked measurement rank = 3
%   - misalignment estimates not equal to [1 2 3] deg
%   - FOG bias estimates not equal to 0.1 deg/h
%
% This should qualitatively resemble Zhang Figure 6.

clear;
clc;
close all;

rng default;

%% ============================================================
% 1. SIMULATION SETTINGS
% =============================================================

duration = ...
    600;                 % 10 min

FsFOG = ...
    100;                 % [Hz]

FsCAIG = ...
    5;                   % [Hz]

dtFOG = ...
    1/FsFOG;

dtCAIG = ...
    1/FsCAIG;

tFOG = ...
    (0:dtFOG:duration-dtFOG).';

tCAIG = ...
    (0:dtCAIG:duration-dtCAIG).';

NFOG = ...
    length(tFOG);

NCAIG = ...
    length(tCAIG);

timeFOG = ...
    seconds(tFOG);

timeCAIG = ...
    seconds(tCAIG);

fprintf('============================================\n');
fprintf('ZHANG FIGURE 6 - CONSTANT SPEED BEHAVIOR\n');
fprintf('============================================\n\n');

fprintf('Duration        = %.1f min\n', ...
    duration/60);

fprintf('FOG rate        = %.1f Hz\n', ...
    FsFOG);

fprintf('CAIG rate       = %.1f Hz\n\n', ...
    FsCAIG);

%% ============================================================
% 2. CONSTANT VEHICLE MOTION
% =============================================================

% Zhang Section 4.1

speedKnots = ...
    15;

speed = ...
    speedKnots ...
    *0.514444;           % [m/s]

headingDeg = ...
    30;

rollDeg = ...
    0;

pitchDeg = ...
    0;

heading = ...
    deg2rad(headingDeg);

%% ============================================================
% 3. GEOGRAPHIC ASSUMPTION
% =============================================================

% Zhang does not provide the geographic position used to
% generate Figure 6.
%
% Use a representative latitude only to create a physically
% reasonable constant inertial angular-rate vector.

latitudeDeg = ...
    45;

latitude = ...
    deg2rad(latitudeDeg);

height = ...
    0;                   % [m]

fprintf('CONSTANT MOTION\n');
fprintf('--------------------------------------------\n');

fprintf('Speed       = %.3f knots = %.3f m/s\n', ...
    speedKnots, ...
    speed);

fprintf('Heading     = %.3f deg\n', ...
    headingDeg);

fprintf('Roll        = %.3f deg\n', ...
    rollDeg);

fprintf('Pitch       = %.3f deg\n', ...
    pitchDeg);

fprintf('Latitude    = %.3f deg (project assumption)\n', ...
    latitudeDeg);

fprintf('Height      = %.3f m   (project assumption)\n\n', ...
    height);

%% ============================================================
% 4. WGS-84
% =============================================================

a = ...
    6378137.0;           % semi-major axis [m]

f = ...
    1/298.257223563;

e2 = ...
    f*(2-f);

sinLat = ...
    sin(latitude);

RN = ...
    a ...
    /sqrt( ...
        1-e2*sinLat^2);

RM = ...
    a*(1-e2) ...
    /( ...
        1-e2*sinLat^2 ...
      )^(3/2);

%% ============================================================
% 5. EARTH ROTATION
% =============================================================

omegaEarth = ...
    7.292115e-5;         % [rad/s]

% Earth rotation expressed in NED frame

omega_ie_n = ...
    [ ...
        omegaEarth*cos(latitude);
        0;
        -omegaEarth*sin(latitude)
    ];

%% ============================================================
% 6. CONSTANT TRANSPORT RATE
% =============================================================

% Heading measured clockwise from North.
%
% 30 deg:
%
% velocity has North and East components.

vN = ...
    speed*cos(heading);

vE = ...
    speed*sin(heading);

% Navigation-frame transport rate in NED coordinates

omega_en_n = ...
    [ ...
        vE/(RN+height);
        ...
        -vN/(RM+height);
        ...
        -vE*tan(latitude)/(RN+height)
    ];

%% ============================================================
% 7. NAVIGATION FRAME -> BODY FRAME
% =============================================================

% Roll = pitch = 0.
%
% Therefore only heading rotation is needed.

C_n_b = ...
    [ ...
         cos(heading),  sin(heading), 0;
        -sin(heading),  cos(heading), 0;
         0,             0,            1
    ];

% Body angular rate relative inertial frame:
%
% omega_ib^b =
%
% C_n^b (omega_ie^n + omega_en^n)

omegaConstB = ...
    C_n_b ...
    *(omega_ie_n + omega_en_n);

fprintf('CONSTANT BODY ANGULAR RATE\n');
fprintf('--------------------------------------------\n');

fprintf('omega_x = %.6e rad/s = %.6f deg/h\n', ...
    omegaConstB(1), ...
    rad2deg(omegaConstB(1))*3600);

fprintf('omega_y = %.6e rad/s = %.6f deg/h\n', ...
    omegaConstB(2), ...
    rad2deg(omegaConstB(2))*3600);

fprintf('omega_z = %.6e rad/s = %.6f deg/h\n\n', ...
    omegaConstB(3), ...
    rad2deg(omegaConstB(3))*3600);

%% ============================================================
% 8. CONSTANT ANGULAR-RATE TIME SERIES
% =============================================================

OmegaA_FOG = ...
    repmat( ...
        omegaConstB.', ...
        NFOG, ...
        1);

OmegaA_CAIG = ...
    repmat( ...
        omegaConstB.', ...
        NCAIG, ...
        1);

%% ============================================================
% 9. TRUE MISALIGNMENT
% =============================================================

% Zhang simulation values

phiTrueDeg = ...
    [1;2;3];

phiTrue = ...
    deg2rad(phiTrueDeg);

C_A_F = ...
    eye(3) ...
    -skewMatrix(phiTrue);

% True angular rate in FOG frame

OmegaF_true = ...
    ( ...
        C_A_F ...
        *OmegaA_FOG.' ...
    ).';

%% ============================================================
% 10. TRUE FOG BIAS
% =============================================================

biasFOG_deg_h = ...
    0.1;

biasFOG = ...
    deg2rad(biasFOG_deg_h) ...
    /3600;

biasFOGvec = ...
    biasFOG ...
    *ones(1,3);

%% ============================================================
% 11. FOG NOISE MODEL
% =============================================================

% EMCORE EG-1300 project baseline

ARW_FOG_deg_sqrt_h = ...
    0.002;

N_FOG = ...
    deg2rad(ARW_FOG_deg_sqrt_h) ...
    /sqrt(3600);

sigmaFOG = ...
    N_FOG ...
    *sqrt(FsFOG);

fprintf('FOG NOISE\n');
fprintf('--------------------------------------------\n');

fprintf('ARW        = %.6f deg/sqrt(h)\n', ...
    ARW_FOG_deg_sqrt_h);

fprintf('sigma_FOG  = %.6e rad/s\n\n', ...
    sigmaFOG);

%% ============================================================
% 12. GENERATE FOG DATA
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
% 13. CAIG NOISE MODEL
% =============================================================

N_CAIG = ...
    6.1e-7;              % [rad/s/sqrt(Hz)]

sigmaCAIG = ...
    N_CAIG ...
    *sqrt(FsCAIG/2);

fprintf('CAIG NOISE\n');
fprintf('--------------------------------------------\n');

fprintf('sigma_CAIG = %.6e rad/s\n\n', ...
    sigmaCAIG);

%% ============================================================
% 14. GENERATE CAIG DATA
% =============================================================

caigNoise = ...
    sigmaCAIG ...
    *randn(NCAIG,3);

OmegaCAIG = ...
    OmegaA_CAIG ...
    +caigNoise;

%% ============================================================
% 15. CREATE TIMETABLES
% =============================================================

TT_FOG = ...
    timetable( ...
        OmegaFOG(:,1), ...
        OmegaFOG(:,2), ...
        OmegaFOG(:,3), ...
        ...
        'RowTimes', ...
        timeFOG, ...
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
        'RowTimes', ...
        timeCAIG, ...
        ...
        'VariableNames',{ ...
            'OmegaX', ...
            'OmegaY', ...
            'OmegaZ'});

%% ============================================================
% 16. SYNCHRONIZE FOG TO CAIG EPOCHS
% =============================================================

TT_FOG_at_CAIG = ...
    retime( ...
        TT_FOG, ...
        TT_CAIG.Properties.RowTimes, ...
        'linear');

OmegaFOG_at_CAIG = ...
    [ ...
        TT_FOG_at_CAIG.OmegaX, ...
        TT_FOG_at_CAIG.OmegaY, ...
        TT_FOG_at_CAIG.OmegaZ
    ];

%% ============================================================
% 17. OBSERVATION
% =============================================================

% Zhang:
%
% deltaOmega = FOG - CAIG

deltaOmega = ...
    OmegaFOG_at_CAIG ...
    -OmegaCAIG;

%% ============================================================
% 18. MEASUREMENT COVARIANCE
% =============================================================

sigmaZ = ...
    sqrt( ...
        sigmaFOG^2 ...
        +sigmaCAIG^2);

R = ...
    sigmaZ^2 ...
    *eye(3);

fprintf('MEASUREMENT COVARIANCE\n');
fprintf('--------------------------------------------\n');

fprintf('sigma_Z    = %.6e rad/s\n', ...
    sigmaZ);

fprintf('R diagonal = %.6e (rad/s)^2\n\n', ...
    R(1,1));

%% ============================================================
% 19. KALMAN INITIAL CONDITIONS
% =============================================================

X0 = ...
    zeros(6,1);

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

Q = ...
    zeros(6);

I6 = ...
    eye(6);

%% ============================================================
% 20. CONSTANT H MATRIX
% =============================================================

Hconst = ...
    [ ...
        skewMatrix(omegaConstB), ...
        eye(3)
    ];

fprintf('MEASUREMENT-SENSITIVITY CHECK\n');
fprintf('--------------------------------------------\n');

fprintf('rank(H constant) = %d / 6\n', ...
    rank(Hconst));

% Two or more repeated identical matrices do not add
% independent information.

HstackTest = ...
    [ ...
        Hconst;
        Hconst;
        Hconst
    ];

fprintf('rank(stacked constant H) = %d / 6\n\n', ...
    rank(HstackTest));

%% ============================================================
% 21. KALMAN STORAGE
% =============================================================

XhatHistory = ...
    zeros(NCAIG,6);

PdiagHistory = ...
    zeros(NCAIG,6);

%% ============================================================
% 22. RUN KALMAN FILTER
% =============================================================

Xhat = ...
    X0;

P = ...
    P0;

for k = 1:NCAIG

    %% Prediction

    Xpred = ...
        Phi*Xhat;

    Ppred = ...
        Phi*P*Phi.' ...
        +Q;

    %% Measurement matrix

    % Constant-speed / constant-attitude case:
    %
    % angular-rate vector remains constant.

    H = ...
        Hconst;

    %% Measurement

    z = ...
        deltaOmega(k,:).';

    %% Innovation

    innovation = ...
        z ...
        -H*Xpred;

    %% Innovation covariance

    S = ...
        H*Ppred*H.' ...
        +R;

    %% Kalman gain

    K = ...
        Ppred*H.'/S;

    %% Update

    Xhat = ...
        Xpred ...
        +K*innovation;

    %% Joseph covariance update

    P = ...
        (I6-K*H) ...
        *Ppred ...
        *(I6-K*H).' ...
        ...
        +K*R*K.';

    %% Store

    XhatHistory(k,:) = ...
        Xhat.';

    PdiagHistory(k,:) = ...
        diag(P).';

end

%% ============================================================
% 23. CONVERT ESTIMATES
% =============================================================

phiHistoryDeg = ...
    rad2deg( ...
        XhatHistory(:,1:3));

biasHistoryDeg_h = ...
    rad2deg( ...
        XhatHistory(:,4:6)) ...
    *3600;

phiFinalDeg = ...
    phiHistoryDeg(end,:);

biasFinalDeg_h = ...
    biasHistoryDeg_h(end,:);

%% ============================================================
% 24. PRINT FINAL RESULTS
% =============================================================

fprintf('============================================\n');
fprintf('FINAL CONSTANT-SPEED ESTIMATES\n');
fprintf('============================================\n\n');

fprintf('TRUE MISALIGNMENT\n');

fprintf('[%.6f %.6f %.6f] deg\n\n', ...
    phiTrueDeg(1), ...
    phiTrueDeg(2), ...
    phiTrueDeg(3));

fprintf('ESTIMATED MISALIGNMENT AFTER 10 min\n');

fprintf('[%.6f %.6f %.6f] deg\n\n', ...
    phiFinalDeg(1), ...
    phiFinalDeg(2), ...
    phiFinalDeg(3));


fprintf('TRUE FOG BIAS\n');

fprintf('[%.6f %.6f %.6f] deg/h\n\n', ...
    biasFOG_deg_h, ...
    biasFOG_deg_h, ...
    biasFOG_deg_h);

fprintf('ESTIMATED FOG BIAS AFTER 10 min\n');

fprintf('[%.6f %.6f %.6f] deg/h\n\n', ...
    biasFinalDeg_h(1), ...
    biasFinalDeg_h(2), ...
    biasFinalDeg_h(3));

fprintf('EXPECTED QUALITATIVE RESULT:\n');
fprintf('Estimates should NOT recover all six true states.\n');
fprintf('This is the behavior of an insufficiently excited system.\n\n');

%% ============================================================
% 25. FIGURE 6 STYLE PLOT
% =============================================================

timeMin = ...
    tCAIG/60;

showTruth = ...
    true;

figure;

tl = ...
    tiledlayout( ...
        3,2, ...
        'TileSpacing','compact', ...
        'Padding','compact');

%% ------------------------------------------------------------
% Phi X
% ------------------------------------------------------------

nexttile(1);

plot( ...
    timeMin, ...
    phiHistoryDeg(:,1), ...
    'LineWidth',1.1);

hold on;

if showTruth

    yline( ...
        phiTrueDeg(1), ...
        '--', ...
        'True');

end

xlim([0 duration/60]);

ylabel('\phi_x [deg]');
title('X-axis');
grid on;

%% ------------------------------------------------------------
% Bias X
% ------------------------------------------------------------

nexttile(2);

plot( ...
    timeMin, ...
    biasHistoryDeg_h(:,1), ...
    'LineWidth',1.1);

hold on;

if showTruth

    yline( ...
        biasFOG_deg_h, ...
        '--', ...
        'True');

end

xlim([0 duration/60]);

ylabel('\epsilon_{Fx} [deg/h]');
title('X-axis');
grid on;

%% ------------------------------------------------------------
% Phi Y
% ------------------------------------------------------------

nexttile(3);

plot( ...
    timeMin, ...
    phiHistoryDeg(:,2), ...
    'LineWidth',1.1);

hold on;

if showTruth

    yline( ...
        phiTrueDeg(2), ...
        '--', ...
        'True');

end

xlim([0 duration/60]);

ylabel('\phi_y [deg]');
title('Y-axis');
grid on;

%% ------------------------------------------------------------
% Bias Y
% ------------------------------------------------------------

nexttile(4);

plot( ...
    timeMin, ...
    biasHistoryDeg_h(:,2), ...
    'LineWidth',1.1);

hold on;

if showTruth

    yline( ...
        biasFOG_deg_h, ...
        '--', ...
        'True');

end

xlim([0 duration/60]);

ylabel('\epsilon_{Fy} [deg/h]');
title('Y-axis');
grid on;

%% ------------------------------------------------------------
% Phi Z
% ------------------------------------------------------------

nexttile(5);

plot( ...
    timeMin, ...
    phiHistoryDeg(:,3), ...
    'LineWidth',1.1);

hold on;

if showTruth

    yline( ...
        phiTrueDeg(3), ...
        '--', ...
        'True');

end

xlim([0 duration/60]);

xlabel('Time [min]');
ylabel('\phi_z [deg]');
title('Z-axis');
grid on;

%% ------------------------------------------------------------
% Bias Z
% ------------------------------------------------------------

nexttile(6);

plot( ...
    timeMin, ...
    biasHistoryDeg_h(:,3), ...
    'LineWidth',1.1);

hold on;

if showTruth

    yline( ...
        biasFOG_deg_h, ...
        '--', ...
        'True');

end

xlim([0 duration/60]);

xlabel('Time [min]');
ylabel('\epsilon_{Fz} [deg/h]');
title('Z-axis');
grid on;

title( ...
    tl, ...
    'Constant-Speed CAIG/FOG Monitoring Behavior');

%% ============================================================
% LOCAL FUNCTION
% =============================================================

function S = skewMatrix(v)

    v = ...
        v(:);

    S = ...
        [ ...
             0,     -v(3),   v(2);
             v(3),   0,     -v(1);
            -v(2),   v(1),   0
        ];

end