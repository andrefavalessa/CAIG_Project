function printSimulationSummary( ...
    truth,fog,caig,caigPhysics,sync,results,validation,cfg)
%PRINTSIMULATIONSUMMARY Print grouped simulation and acceptance results.

    fprintf('============================================\n');
    fprintf('CAIG MAIN SIMULATION\n');
    fprintf('============================================\n\n');

    fprintf('CONFIGURATION\n');
    fprintf('--------------------------------------------\n');
    fprintf('Duration        = %.1f s\n',cfg.duration);
    fprintf('FOG sample rate = %.1f Hz\n',cfg.FsFOG);
    fprintf('CAIG rate       = %.1f Hz\n',cfg.FsCAIG);
    fprintf('FOG samples     = %d\n',truth.NFOG);
    fprintf('CAIG samples    = %d\n',truth.NCAIG);
    fprintf('T               = %.4f ms\n',cfg.T*1000);
    fprintf('v               = %.4f m/s\n',cfg.vAtom);
    fprintf('lambda          = %.9f nm\n',cfg.lambda*1e9);
    fprintf('k_eff           = %.6e 1/m\n\n',cfg.keff);

    fprintf('GROUND-TRUTH MAXIMUM BODY RATES\n');
    fprintf('--------------------------------------------\n');
    fprintf('X = %.6f deg/s\n', ...
        max(abs(rad2deg(truth.OmegaCAIG(:,1)))));
    fprintf('Y = %.6f deg/s\n', ...
        max(abs(rad2deg(truth.OmegaCAIG(:,2)))));
    fprintf('Z = %.6f deg/s\n\n', ...
        max(abs(rad2deg(truth.OmegaCAIG(:,3)))));

    fprintf('CAIG PHYSICS\n');
    fprintf('--------------------------------------------\n');
    fprintf('Ksingle = %.6e s\n',caigPhysics.Ksingle);
    fprintf('Kdual   = %.6e s\n',caigPhysics.Kdual);
    fprintf('Max |Omega_Y phase - truth| = %.6e rad/s\n\n', ...
        caigPhysics.maxRateError);

    fprintf('SYNTHETIC SENSOR CHECKS\n');
    fprintf('--------------------------------------------\n');
    fprintf('FOG ARW            = %.6f deg/sqrt(h)\n', ...
        cfg.ARW_FOG_deg_sqrt_h);
    fprintf('FOG NoiseType      = %s\n',cfg.NoiseType);
    fprintf('FOG NoiseDensity   = %.6e rad/s/sqrt(Hz)\n',cfg.N_FOG);
    fprintf('FOG expected sigma = %.6e rad/s\n',fog.sigmaExpected);
    fprintf('FOG empirical sigma = [%.6e %.6e %.6e] rad/s\n', ...
        fog.sigmaEmpirical(1),fog.sigmaEmpirical(2), ...
        fog.sigmaEmpirical(3));
    fprintf('CAIG sensitivity   = %.6e rad/s/sqrt(Hz)\n',cfg.N_CAIG);
    fprintf('CAIG expected sigma = %.6e rad/s\n',caig.sigmaExpected);
    fprintf('CAIG empirical sigma = [%.6e %.6e %.6e] rad/s\n', ...
        caig.sigmaEmpirical(1),caig.sigmaEmpirical(2), ...
        caig.sigmaEmpirical(3));
    fprintf('Measurement sigma  = %.6e rad/s\n',results.sigmaZ);
    fprintf('R diagonal         = %.6e (rad/s)^2\n\n',results.R(1,1));

    fprintf('SYNCHRONIZATION\n');
    fprintf('--------------------------------------------\n');
    fprintf('FOG timetable rows  = %d\n',height(sync.TT_FOG));
    fprintf('CAIG timetable rows = %d\n',height(sync.TT_CAIG));
    fprintf('Max timetable/manual difference\n');
    fprintf('X = %.6e rad/s\n',sync.maxSyncDifference(1));
    fprintf('Y = %.6e rad/s\n',sync.maxSyncDifference(2));
    fprintf('Z = %.6e rad/s\n',sync.maxSyncDifference(3));
    fprintf('Max timestamp error = %.6e s\n\n',sync.maxTimestampError);

    fprintf('============================================\n');
    fprintf('FINAL KALMAN ESTIMATES\n');
    fprintf('============================================\n\n');

    axesNames = {'X','Y','Z'};
    fprintf('MISALIGNMENT\n');
    fprintf('--------------------------------------------\n');
    for ax = 1:3
        fprintf('%s true      = %.6f deg\n', ...
            axesNames{ax},cfg.phiTrueDeg(ax));
        fprintf('%s estimated = %.6f deg\n', ...
            axesNames{ax},results.finalMisalignmentDeg(ax));
        fprintf('%s error     = %.6f deg\n\n', ...
            axesNames{ax},results.misalignmentErrorDeg(ax));
    end

    fprintf('FOG BIAS\n');
    fprintf('--------------------------------------------\n');
    for ax = 1:3
        fprintf('%s true      = %.6f deg/h\n', ...
            axesNames{ax},cfg.biasFOG_deg_h);
        fprintf('%s estimated = %.6f deg/h\n', ...
            axesNames{ax},results.finalBiasDegH(ax));
        fprintf('%s error     = %.6f deg/h\n\n', ...
            axesNames{ax},results.biasErrorDegH(ax));
    end

    fprintf('============================================\n');
    fprintf('FINAL ACCEPTANCE CHECK\n');
    fprintf('============================================\n\n');
    fprintf('CAIG phase -> rate consistency : %s\n', ...
        passFail(validation.checkPhase));
    fprintf('timetable synchronization     : %s\n', ...
        passFail(validation.checkSync));
    fprintf('FOG synthetic noise level     : %s\n', ...
        passFail(validation.checkFOGNoise));
    fprintf('CAIG synthetic noise level    : %s\n', ...
        passFail(validation.checkCAIGNoise));
    fprintf('Kalman regression             : %s\n\n', ...
        passFail(validation.checkKalmanRegression));
    fprintf('Max Kalman phi regression difference  = %.6e deg\n', ...
        validation.regressionPhiDifference);
    fprintf('Max Kalman bias regression difference = %.6e deg/h\n\n', ...
        validation.regressionBiasDifference);

    if validation.allPass
        fprintf('OVERALL RESULT: PASS\n');
    else
        fprintf('OVERALL RESULT: CHECK REQUIRED\n');
    end
end


function text = passFail(condition)
    if condition
        text = 'PASS';
    else
        text = 'CHECK';
    end
end
