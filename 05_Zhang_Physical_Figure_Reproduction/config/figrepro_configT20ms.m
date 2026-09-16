function cfg=figrepro_configT20ms(caseName)
%FIGREPRO_CONFIGT20MS Additive configuration; leaves the 1 ms source untouched.
cfg=figrepro_config(caseName); % Read-only reuse of documented FOG/motion/prior.
cfg.caig.Tsec=.020;           % User-requested second interrogation time.
T=cfg.caig.Tsec; k=cfg.caig.kPerM; v=cfg.caig.atomSpeedMPerSec;
cfg.caig.interrogationDurationSec=2*T;
cfg.caig.KsingleSec=2*k*v*T^2;
cfg.caig.KdualSec=4*k*v*T^2;
% Retain the same static known-gravity cancellation, recomputed at the new T.
% No time-dependent phase steering or new fringe acquisition is introduced.
cfg.caig.sharedPulsePhaseRad=cfg.caig.controlledCommonPhaseRad - ...
    k*(cfg.caig.kDirectionsA*cfg.caig.gravityA.')*T^2;
cfg.inverse.KdualSec=cfg.caig.KdualSec;
cfg.inverse.maximumDepartureFromMidfringeRad= ...
    2*k*(v*T^2+norm(cfg.caig.gravityA)*T^3)*cfg.caig.rateNormBoundRadPerSec;
cfg.inverse.designEnvelopeGuaranteed=cfg.inverse.maximumDepartureFromMidfringeRad<pi/2;
% IMPORTANT: false is a diagnosis, not a disabled promise of valid inversion.
% The main runner independently audits the generated phases before any KF.
cfg.window.referenceSampleRateHz=1000; % Numerical reference, not a sensor cadence.
cfg.window.model='Normalized rectangular 2T average; reduced quasi-static Zhang input, not an atom sensitivity function';
cfg.control.enabled=true; % Simulator-known signs/fringes, CONTROL ONLY if main fails.
cfg.caig.availableOffsetSec=2*T+cfg.caig.readoutSec; % 40+8=48 ms.
assert(cfg.caig.availableOffsetSec<1/cfg.caig.sampleRateHz,'Shot exceeds cycle.');
cfg.outputStem=sprintf('figure%d_T20ms_%s',6+2*strcmp(caseName,'triaxial_sway'),caseName);
end
