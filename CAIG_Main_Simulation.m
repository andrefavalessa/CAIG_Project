%% CAIG_Main_Simulation.m
% Modular end-to-end CAIG + FOG simulation.
%
% Architecture:
%   configuration -> truth motion -> CAIG physics -> FOG -> CAIG
%   -> synchronization -> Zhang trackingKF -> validation -> reporting
%
% Scientific equations and validated numerical conventions live in the
% responsibility-specific functions. The FOG must be simulated before the
% CAIG so rng-default reproducibility matches the monolithic baseline.

clear;
clc;
close all;

rng default;

%% Make the project independent of the MATLAB current working directory
projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(projectRoot));

assert( ...
    ~isempty(which('trackingKF')), ...
    ['trackingKF was not found. ', ...
     'Sensor Fusion and Tracking Toolbox is required.']);

%% End-to-end workflow
cfg = getSimulationConfig();

truth = generateLevel2Sway(cfg);

caigPhysics = simulateCAIGPhysicsY(truth,cfg);

% Critical random execution order: FOG first, CAIG second.
fog = simulateFOG(truth,cfg);

caig = simulateCAIG(truth,cfg);

sync = synchronizeSensors(fog,caig,truth,cfg);

results = runZhangKalman(truth,sync,cfg);

validation = validateMainSimulation( ...
    truth,fog,caig,caigPhysics,sync,results,cfg);

%% Preserve the consolidated output interface from the baseline
SimulationOutput = struct;
SimulationOutput.FsFOG = cfg.FsFOG;
SimulationOutput.FsCAIG = cfg.FsCAIG;
SimulationOutput.Duration = cfg.duration;
SimulationOutput.FOG = sync.TT_FOG;
SimulationOutput.CAIG = sync.TT_CAIG;
SimulationOutput.FOG_at_CAIG = sync.TT_FOG_at_CAIG;
SimulationOutput.Estimates = results.TT_Estimates;
SimulationOutput.CAIG_Phase_Y = caigPhysics.phaseDiff;
SimulationOutput.CAIG_Probability_1 = caigPhysics.P1;
SimulationOutput.CAIG_Probability_2 = caigPhysics.P2;
SimulationOutput.R = results.R;
SimulationOutput.FinalMisalignment_deg = ...
    results.finalMisalignmentDeg;
SimulationOutput.FinalFOGBias_deg_h = results.finalBiasDegH;
SimulationOutput.AcceptancePass = validation.allPass;

printSimulationSummary( ...
    truth,fog,caig,caigPhysics,sync,results,validation,cfg);

plotSimulationResults( ...
    truth,fog,caig,caigPhysics,results,cfg);
