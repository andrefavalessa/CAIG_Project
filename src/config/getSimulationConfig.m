function cfg = getSimulationConfig()
%GETSIMULATIONCONFIG Return the validated CAIG + FOG simulation settings.
%
% Parameter provenance is preserved from the monolithic reference:
%   Zhang et al. (2019): sample rates, FOG bias, frame misalignment,
%     level-2 sway, and the six-state monitoring model.
%   Tackmann et al. (2012): pulse separation time, atomic velocity, and
%     CAIG rotation sensitivity.
%   Steck: Rb-87 D2 wavelength.
%   EMCORE EG-1300: FOG angle random walk.
%   Project assumptions: sinusoidal sway, equivalent white CAIG output
%     noise, single-sided FOG noise, and constant true filter states.

    %% General
    cfg.duration = 120;                 % [s]
    cfg.FsFOG = 100;                    % [Hz], Zhang et al. (2019)
    cfg.FsCAIG = 5;                     % [Hz], Zhang et al. (2019)

    cfg.dtFOG = 1/cfg.FsFOG;
    cfg.dtCAIG = 1/cfg.FsCAIG;
    cfg.sampleRatio = cfg.FsFOG/cfg.FsCAIG;

    assert(cfg.duration>0,'Simulation duration must be positive.');
    assert(cfg.FsFOG>0,'FOG sample rate must be positive.');
    assert(cfg.FsCAIG>0,'CAIG sample rate must be positive.');
    assert( ...
        mod(cfg.sampleRatio,1) == 0, ...
        'FOG/CAIG rate ratio must be integer for regression check.');

    %% Zhang et al. (2019)
    cfg.phiTrueDeg = [1;2;3];
    cfg.phiTrue = deg2rad(cfg.phiTrueDeg);

    cfg.biasFOG_deg_h = 0.1;
    cfg.biasFOG = deg2rad(cfg.biasFOG_deg_h)/3600;
    cfg.biasFOGvec = cfg.biasFOG*ones(1,3);

    cfg.rollAmp = deg2rad(0.50);
    cfg.pitchAmp = deg2rad(0.20);
    cfg.headingAmp = deg2rad(0.30);
    cfg.rollPeriod = 20;
    cfg.pitchPeriod = 30;
    cfg.headingPeriod = 30;

    %% CAIG physical parameters
    cfg.T = 24.7e-3;                    % [s], Tackmann et al. (2012)
    cfg.vAtom = 2.79;                   % [m/s], Tackmann et al. (2012)
    cfg.lambda = 780.241209686e-9;      % [m], Steck Rb-87 D2
    cfg.g0 = 9.80665;                   % [m/s^2], standard gravity
    cfg.keff = 4*pi/cfg.lambda;         % [1/m]

    %% FOG noise model
    cfg.ARW_FOG_deg_sqrt_h = 0.002;     % EMCORE EG-1300
    cfg.N_FOG = ...
        deg2rad(cfg.ARW_FOG_deg_sqrt_h)/sqrt(3600);
    cfg.NoiseType = 'single-sided';     % Validated project convention
    cfg.sigmaFOG = cfg.N_FOG*sqrt(cfg.FsFOG);

    %% CAIG rate-level noise model
    cfg.N_CAIG = 6.1e-7;                % [rad/s/sqrt(Hz)], Tackmann
    cfg.sigmaCAIG = cfg.N_CAIG*sqrt(cfg.FsCAIG/2);

    %% Kalman and software-regression settings
    % Zhang initialization settings are kept distinct from the injected
    % true misalignment and FOG-bias values above.
    cfg.X0 = zeros(6,1);
    cfg.phiStd0Deg = [1;2;3];
    cfg.biasStd0DegH = [0.1;0.1;0.1];
    cfg.P0 = diag([ ...
        deg2rad(cfg.phiStd0Deg).^2; ...
        (deg2rad(cfg.biasStd0DegH)/3600).^2 ...
    ]);
    cfg.Phi = eye(6);
    cfg.Q = zeros(6);

    cfg.referencePhiDeg = [1.000694;2.005255;3.008474];
    cfg.referenceBiasDeg_h = [0.067151;0.055620;0.128074];
    cfg.regressionTolerance = 1e-4;
    cfg.noiseRelativeTolerance = 0.10;
end
