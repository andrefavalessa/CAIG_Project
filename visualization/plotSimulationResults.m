function plotSimulationResults( ...
    truth,fog,caig,caigPhysics,results,cfg)
%PLOTSIMULATIONRESULTS Plot the four validated result groups.
%
% Plotting performs no calculations used by the estimator.

    %% Synthetic FOG and CAIG angular-rate outputs
    figure;

    subplot(3,1,1);
    plot(truth.tFOG,rad2deg(fog.measured(:,1)),'LineWidth',0.8);
    hold on;
    plot(truth.tCAIG,rad2deg(caig.measured(:,1)),'.');
    ylabel('\omega_x [deg/s]');
    title('Synthetic FOG and CAIG Angular-Rate Data');
    legend('FOG 100 Hz','CAIG 5 Hz');
    grid on;

    subplot(3,1,2);
    plot(truth.tFOG,rad2deg(fog.measured(:,2)),'LineWidth',0.8);
    hold on;
    plot(truth.tCAIG,rad2deg(caig.measured(:,2)),'.');
    ylabel('\omega_y [deg/s]');
    grid on;

    subplot(3,1,3);
    plot(truth.tFOG,rad2deg(fog.measured(:,3)),'LineWidth',0.8);
    hold on;
    plot(truth.tCAIG,rad2deg(caig.measured(:,3)),'.');
    xlabel('Time [s]');
    ylabel('\omega_z [deg/s]');
    grid on;

    %% CAIG physical differential phase and recovered Omega_Y
    figure;

    subplot(2,1,1);
    plot(truth.tCAIG,caigPhysics.phaseDiff,'LineWidth',1.2);
    xlabel('Time [s]');
    ylabel('\Delta\Phi_{diff} [rad]');
    title('Validated Dual-Interferometer CAIG Phase - Y Sensitive Axis');
    grid on;

    subplot(2,1,2);
    plot(truth.tCAIG,rad2deg(caigPhysics.OmegaY_fromPhase), ...
        'LineWidth',1.2);
    hold on;
    plot(truth.tCAIG,rad2deg(truth.OmegaCAIG(:,2)),'--');
    xlabel('Time [s]');
    ylabel('\omega_y [deg/s]');
    legend('Recovered from CAIG phase','Ground truth');
    grid on;

    %% Misalignment estimates
    figure;

    subplot(3,1,1);
    plot(truth.tCAIG,results.phiHistoryDeg(:,1),'LineWidth',1.2);
    hold on;
    yline(cfg.phiTrueDeg(1),'--');
    ylabel('\phi_x [deg]');
    title('Estimated CAIG/FOG Frame Misalignment');
    grid on;

    subplot(3,1,2);
    plot(truth.tCAIG,results.phiHistoryDeg(:,2),'LineWidth',1.2);
    hold on;
    yline(cfg.phiTrueDeg(2),'--');
    ylabel('\phi_y [deg]');
    grid on;

    subplot(3,1,3);
    plot(truth.tCAIG,results.phiHistoryDeg(:,3),'LineWidth',1.2);
    hold on;
    yline(cfg.phiTrueDeg(3),'--');
    xlabel('Time [s]');
    ylabel('\phi_z [deg]');
    grid on;

    %% FOG bias estimates
    figure;

    subplot(3,1,1);
    plot(truth.tCAIG,results.biasHistoryDegH(:,1),'LineWidth',1.2);
    hold on;
    yline(cfg.biasFOG_deg_h,'--');
    ylabel('\epsilon_{Fx} [deg/h]');
    title('Estimated FOG Bias');
    grid on;

    subplot(3,1,2);
    plot(truth.tCAIG,results.biasHistoryDegH(:,2),'LineWidth',1.2);
    hold on;
    yline(cfg.biasFOG_deg_h,'--');
    ylabel('\epsilon_{Fy} [deg/h]');
    grid on;

    subplot(3,1,3);
    plot(truth.tCAIG,results.biasHistoryDegH(:,3),'LineWidth',1.2);
    hold on;
    yline(cfg.biasFOG_deg_h,'--');
    xlabel('Time [s]');
    ylabel('\epsilon_{Fz} [deg/h]');
    grid on;
end
