function fog = simulateFOG(truth,cfg)
%SIMULATEFOG Generate the FOG realization using gyroparams and imuSensor.
%
% The Zhang frame-to-frame misalignment is applied explicitly. It is not
% gyroparams.AxesMisalignment. This function must execute before
% simulateCAIG so the rng-default realization remains unchanged.

    C_A_F = eye(3)-skewMatrix(cfg.phiTrue);

    OmegaF_true = ...
        (C_A_F*truth.OmegaFOG.').';

    paramsFOG = gyroparams( ...
        'ConstantBias',cfg.biasFOGvec, ...
        'NoiseDensity',cfg.N_FOG*ones(1,3), ...
        'NoiseType',cfg.NoiseType);

    imuFOG = imuSensor( ...
        'accel-gyro', ...
        'SampleRate',cfg.FsFOG, ...
        'Gyroscope',paramsFOG);

    % Zero acceleration is supplied only because the object is accel-gyro.
    accelDummy = zeros(truth.NFOG,3);

    [~,OmegaFOG] = imuFOG(accelDummy,OmegaF_true);

    fogDeterministic = ...
        OmegaF_true+repmat(cfg.biasFOGvec,truth.NFOG,1);

    fogNoiseMeasured = OmegaFOG-fogDeterministic;
    sigmaFOG_emp = std(fogNoiseMeasured,0,1);

    fog.true = OmegaF_true;
    fog.measured = OmegaFOG;
    fog.deterministic = fogDeterministic;
    fog.noiseMeasured = fogNoiseMeasured;
    fog.sigmaExpected = cfg.sigmaFOG;
    fog.sigmaEmpirical = sigmaFOG_emp;
    fog.biasRadS = cfg.biasFOG;
    fog.biasVectorRadS = cfg.biasFOGvec;
    fog.C_A_F = C_A_F;
end
