function caig = simulateCAIG(truth,cfg)
%SIMULATECAIG Generate the three-axis CAIG rate-level realization.
%
% This is the validated V2 abstraction:
%   Omega_CAIG = Omega_true + white noise.
% CAIG bias remains negligible. The Tackmann sensitivity is interpreted as
% equivalent white angular-rate output noise, a project assumption.

    caigNoise = ...
        cfg.sigmaCAIG*randn(truth.NCAIG,3);

    OmegaCAIG = truth.OmegaCAIG+caigNoise;

    sigmaCAIG_emp = ...
        std(OmegaCAIG-truth.OmegaCAIG,0,1);

    caig.true = truth.OmegaCAIG;
    caig.measured = OmegaCAIG;
    caig.noise = caigNoise;
    caig.sigmaExpected = cfg.sigmaCAIG;
    caig.sigmaEmpirical = sigmaCAIG_emp;
end
