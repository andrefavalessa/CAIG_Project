function results = runZhangKalman(truth,sync,cfg)
%RUNZHANGKALMAN Run the validated six-state Zhang trackingKF model.

    assert( ...
        isequal(size(sync.deltaOmega),[truth.NCAIG 3]), ...
        'Zhang observations must have size truth.NCAIG-by-3.');
    assert( ...
        isequal(size(truth.OmegaCAIG),[truth.NCAIG 3]), ...
        'True CAIG angular rates must have size truth.NCAIG-by-3.');

    sigmaZ = sqrt(cfg.sigmaFOG^2+cfg.sigmaCAIG^2);
    R = sigmaZ^2*eye(3);

    omega0 = truth.OmegaCAIG(1,:).';
    H0 = [skewMatrix(omega0),eye(3)];

    KF = trackingKF( ...
        cfg.Phi,H0, ...
        'State',cfg.X0, ...
        'StateCovariance',cfg.P0, ...
        'ProcessNoise',cfg.Q, ...
        'MeasurementNoise',R);

    XhatHistory = zeros(truth.NCAIG,6);
    PdiagHistory = zeros(truth.NCAIG,6);

    for k = 1:truth.NCAIG

        % Intentional baseline choice: true simulated angular rate.
        omega = truth.OmegaCAIG(k,:).';
        Hk = [skewMatrix(omega),eye(3)];

        KF.MeasurementModel = Hk;
        predict(KF);

        z = sync.deltaOmega(k,:).';
        [Xhat,P] = correct(KF,z);

        XhatHistory(k,:) = Xhat.';
        PdiagHistory(k,:) = diag(P).';
    end

    phiEstimatedDeg = rad2deg(Xhat(1:3));
    biasEstimatedDeg_h = rad2deg(Xhat(4:6))*3600;

    phiHistoryDeg = rad2deg(XhatHistory(:,1:3));
    biasHistoryDeg_h = rad2deg(XhatHistory(:,4:6))*3600;

    TT_Estimates = timetable( ...
        phiHistoryDeg(:,1), ...
        phiHistoryDeg(:,2), ...
        phiHistoryDeg(:,3), ...
        biasHistoryDeg_h(:,1), ...
        biasHistoryDeg_h(:,2), ...
        biasHistoryDeg_h(:,3), ...
        'RowTimes',truth.timeCAIG, ...
        'VariableNames',{ ...
            'PhiX_deg','PhiY_deg','PhiZ_deg', ...
            'BiasX_deg_h','BiasY_deg_h','BiasZ_deg_h'});

    results.XhatHistory = XhatHistory;
    results.PdiagHistory = PdiagHistory;
    results.finalState = Xhat;
    results.finalCovariance = P;
    results.finalMisalignmentDeg = phiEstimatedDeg;
    results.finalBiasDegH = biasEstimatedDeg_h;
    results.misalignmentErrorDeg = phiEstimatedDeg-cfg.phiTrueDeg;
    results.biasErrorDegH = ...
        biasEstimatedDeg_h-cfg.biasFOG_deg_h*ones(3,1);
    results.phiHistoryDeg = phiHistoryDeg;
    results.biasHistoryDegH = biasHistoryDeg_h;
    results.TT_Estimates = TT_Estimates;
    results.R = R;
    results.sigmaZ = sigmaZ;
end
