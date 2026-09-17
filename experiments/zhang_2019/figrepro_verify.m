function v = figrepro_verify(cfg,fog,fogSim,probabilities,latent,caig,synced,estimate)
%FIGREPRO_VERIFY Post-estimation physics, timing and causal-interface checks.
% Ground truth is permitted here, never in reconstruction/synchronization/KF.
v.caseName=cfg.caseName;
v.matlabVersion=version;
v.fogBackend=fogSim.backend;
v.durationSec=cfg.durationSec;
v.sampleRatesHz=[cfg.fog.sampleRateHz cfg.caig.sampleRateHz];
v.interrogationSec=cfg.caig.Tsec;
v.scaleFactorSec=cfg.caig.KdualSec;
v.probabilityRange=[min([probabilities.P1(:);probabilities.P2(:)]), ...
                    max([probabilities.P1(:);probabilities.P2(:)])];
v.loopPhaseRangeRad=[min([latent.phaseLoop1Rad(:);latent.phaseLoop2Rad(:)]), ...
                        max([latent.phaseLoop1Rad(:);latent.phaseLoop2Rad(:)])];
v.designBranchDepartureBoundRad=cfg.inverse.maximumDepartureFromMidfringeRad;
v.differentialPhysicsMaxErrorRad=max(abs( ...
    latent.phaseDiffRad-cfg.caig.KdualSec*latent.omegaARadPerSec),[],'all');
v.phaseInverseMaxErrorRad=max([max(abs(caig.PhaseLoop1RecRad-latent.phaseLoop1Rad),[],'all'), ...
    max(abs(caig.PhaseLoop2RecRad-latent.phaseLoop2Rad),[],'all')]);
v.rateReconstructionMaxErrorRadPerSec=max(abs(caig.RateARadPerSec-latent.omegaARadPerSec),[],'all');
assert(v.differentialPhysicsMaxErrorRad<1e-11 && v.phaseInverseMaxErrorRad<1e-11 && ...
    v.rateReconstructionMaxErrorRadPerSec<1e-12,'figrepro:PhysicsCheck','Physical chain identity failed.');

% Probability intervention must affect the reconstructed rate. This detects
% an accidental shortcut copying angular truth or latent differential phase.
altered=probabilities(1,:); altered.P1(1,1)=altered.P1(1,1)+1e-4;
changed=figrepro_reconstruct(altered,cfg.inverse);
v.probabilityInterventionRateChange=changed.RateARadPerSec(1,1)-caig.RateARadPerSec(1,1);
assert(abs(v.probabilityInterventionRateChange)>1e-8,'figrepro:ProbabilityBypass','Probability intervention did not reach rate.');
assert(isequal(probabilities.Properties.VariableNames, ...
    {'EffectiveSec','FirstPulseSec','LastPulseSec','AvailableSec','P1','P2'}), ...
    'figrepro:TruthLeak','Unexpected sensor-side data in the reconstruction interface.');

% A changed unavailable FOG suffix and a shortened observation sequence must
% leave every earlier update unchanged. retime is not intrinsically causal;
% its support/availability checks are exercised explicitly.
cut=min(101,height(caig));
fogAltered=fog;
future=seconds(fog.Properties.RowTimes)>caig.AvailableSec(cut)+1e-9;
fogAltered.RateFRadPerSec(future,:)=1e6;
prefixSync=figrepro_synchronize(fogAltered,caig(1:cut,:),fogSim.sampleSigmaRadPerSec);
prefixEstimate=figrepro_zhang(prefixSync,cfg.filter);
v.causalPrefixMaxStateDifference=max(abs(prefixEstimate.state-estimate.state(1:cut,:)),[],'all');
assert(v.causalPrefixMaxStateDifference==0,'figrepro:Causality','Future data changed an earlier estimate.');
tooEarly=caig(1,:); tooEarly.AvailableSec=tooEarly.LastPulseSec;
v.unavailableSupportRejected=false;
try
    figrepro_synchronize(fog,tooEarly,fogSim.sampleSigmaRadPerSec);
catch issue
    if strcmp(issue.identifier,'figrepro:FutureData'), v.unavailableSupportRejected=true;
    else, rethrow(issue); end
end
assert(v.unavailableSupportRejected,'figrepro:Causality','Unavailable interpolation support was accepted.');
v.synchronizationRan=true;
v.maximumSupportPastAvailabilitySec=max(synced.LastSupportSec-synced.AvailableSec);
v.interpolationRightWeightRange=[min(synced.RightWeight) max(synced.RightWeight)];
v.fogSampleSigmaTheory=fogSim.sampleSigmaRadPerSec;
v.fogSampleSigmaEmpirical=std(fogSim.noiseFRadPerSec,0,1);
ratio=v.fogSampleSigmaEmpirical/v.fogSampleSigmaTheory;
assert(all(abs(ratio-1)<6/sqrt(2*height(fog))), ...
    'figrepro:NoiseConvention','Observed imuSensor noise conflicts with the single-sided convention.');
v.observationSigmaRange=sqrt([min(synced.ObservationVariance),max(synced.ObservationVariance)]);
v.minimumCovarianceEigenvalue=inf;
for j=1:size(estimate.covariance,3)
    P=estimate.covariance(:,:,j);
    assert(norm(P-P.','fro')<1e-16,'Asymmetric filter covariance.');
    v.minimumCovarianceEigenvalue=min(v.minimumCovarianceEigenvalue,min(eig(P)));
end
assert(v.minimumCovarianceEigenvalue>=-1e-18 && all(isfinite(estimate.state),'all'),'Invalid filter state/covariance.');
v.sensitivityRank=estimate.sensitivityRank;
v.scaledSensitivitySingularValues=estimate.sensitivitySingularValues.';
v.finalMisalignmentDeg=rad2deg(estimate.state(end,1:3));
v.finalBiasDegH=rad2deg(estimate.state(end,4:6))*3600;
v.injectedMisalignmentDeg=rad2deg(cfg.simulation.misalignmentRad).';
v.injectedBiasDegH=rad2deg(cfg.simulation.biasFRadPerSec)*3600;
v.finalMisalignmentErrorDeg=v.finalMisalignmentDeg-v.injectedMisalignmentDeg;
v.finalBiasErrorDegH=v.finalBiasDegH-v.injectedBiasDegH;
late=estimate.availableSec>=cfg.durationSec-60;
v.lastMinuteMeanMisalignmentDeg=rad2deg(mean(estimate.state(late,1:3),1));
v.lastMinuteMeanBiasDegH=rad2deg(mean(estimate.state(late,4:6),1))*3600;
if strcmp(cfg.caseName,'constant_speed')
    assert(v.sensitivityRank==3,'Expected constant-motion sensitivity rank 3.');
    U=estimate.sensitivityNullspace;
    D=diag(1./cfg.filter.priorStd);
    normalizedP=D*estimate.covariance(:,:,end)*D;
    v.nullspacePriorCovarianceChange=norm(U.'*normalizedP*U-eye(3),'fro');
    assert(v.nullspacePriorCovarianceChange<1e-7,'Unobservable directions falsely gained information.');
    v.qualitativeInterpretation='Figure 6 style weak observability: only three state combinations are identifiable; individual plateaus depend on the prior.';
else
    assert(v.sensitivityRank==6,'Expected sway sensitivity rank 6.');
    v.qualitativeInterpretation='Figure 8 style rich excitation: all six sensitivity directions present; inspect saved estimates for convergence and residual model/noise error.';
end
v.limitations={'1 ms known principal-branch operation, not nominal 24.7 ms fringe acquisition', ...
    'Ideal CAIG probability readout; no short-T sensitivity claim', ...
    'Three virtual axes and quasi-static midpoint phase', ...
    'First-order Zhang estimator versus finite sensor-frame rotation', ...
    'One seeded realization; fixed bias, not stochastic drift'};
v.allChecksPassed=true;
end
