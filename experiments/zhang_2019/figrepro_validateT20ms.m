function v = figrepro_validateT20ms(cfg, shots, fog, fogSim, probabilities, latent, principal, ...
    d, control, referenceWindow)
%FIGREPRO_VALIDATET20MS Tests confined to new work; does not rerun 1 ms baseline.

% Check the phase scale, shot timing and observable interface independently.
v.phaseScaleIdentityMaxErrorRad = max(abs(latent.phaseDiffRad - ...
    cfg.caig.KdualSec * latent.omegaARadPerSec), [], 'all');
assert(v.phaseScaleIdentityMaxErrorRad < 1e-9, 'Physical differential scale mismatch.');
assert(abs(cfg.caig.KdualSec - 2 * cfg.caig.KsingleSec) < 1e-10);
assert(all(abs(shots.LastPulseSec - shots.FirstPulseSec - .040) < 1e-10));
assert(all(abs(shots.AvailableSec - shots.FirstPulseSec - .048) < 1e-10));
assert(all(probabilities.P1 >= 0 & probabilities.P1 <= 1, 'all') && ...
    all(probabilities.P2 >= 0 & probabilities.P2 <= 1, 'all'));
assert(isequal(probabilities.Properties.VariableNames, ...
    {'EffectiveSec','FirstPulseSec','LastPulseSec','AvailableSec','P1','P2'}), ...
        'Truth leaked into observations.');
v.normalFilterBlockedWhenInvalid = ~d.currentReconstructionValid && ~d.mainFilterRan;
assert(d.currentReconstructionValid || v.normalFilterBlockedWhenInvalid);
% Verify exact cosine sign/period alternatives: observations cannot certify one.
v.signAliasProbabilityResidual = max(abs((1 - cos(-latent.phaseLoop1Rad)) / ...
    2 - probabilities.P1), [], 'all');
v.fringeAliasProbabilityResidual = max(abs((1 - cos(latent.phaseLoop2Rad + 2 * pi)) / ...
    2 - probabilities.P2), [], 'all');
assert(v.signAliasProbabilityResidual < 1e-11 && v.fringeAliasProbabilityResidual < 1e-11);
assert(d.signAmbiguityEncountered && d.nonzeroTwoPiAliasRequired, ...
    'Expected the fixed 20 ms fixtures to violate sign/fringe restrictions.');
assert(~d.currentReconstructionValid, '20 ms fixture unexpectedly passed principal inversion.');

% Integration independent check: constant/linear rates have known window means.
t = seconds(fog.Properties.RowTimes);
testSignal = timetable(fog.Properties.RowTimes, [ones(size(t))*7,2+3*t], ...
    'VariableNames', {'Signal'});
integral = figrepro_windowMean(testSignal, shots, cfg.fog.sampleRateHz);
v.linearIntegralMaxError = max(abs(integral.mean - [7*ones(height(shots),1),2+3*shots.EffectiveSec]), [], 'all');
assert(v.linearIntegralMaxError < 1e-9, 'Window integral fails exact constant/linear identity.');
assert(max(abs(integral.weights - [.125 .25 .25 .25 .125])) < 1e-12);
v.fogWindowWeights = integral.weights;
v.fogWindowVarianceWeight = integral.varianceWeight;
v.maxReferenceTimestampRoundoffSec = referenceWindow.maximumTimestampResidualSec;
v.fogWindowSampleSigma = fogSim.sampleSigmaRadPerSec * sqrt(integral.varianceWeight);
v.fogNoiseEmpiricalToTheory = std(fogSim.noiseFRadPerSec) / fogSim.sampleSigmaRadPerSec;
assert(all(abs(v.fogNoiseEmpiricalToTheory - 1) < 6 / sqrt(2 * height(fog))));
% Explicit rejection at an off-grid boundary and at premature availability.
offGrid = shots(1,:);
offGrid.FirstPulseSec = offGrid.FirstPulseSec + 1e-6;
offGrid.LastPulseSec = offGrid.LastPulseSec + 1e-6;
v.offGridWindowRejected = rejects(@() figrepro_windowMean(fog, offGrid, cfg.fog.sampleRateHz), ...
    'figrepro:OffGridWindow');
early = principal(1,:);
early.AvailableSec = early.LastPulseSec - .001;
v.futureSupportRejected = rejects(@() figrepro_synchronizeT20ms(fog, early, cfg.fog), ...
    'figrepro:FutureData');
assert(v.offGridWindowRejected && v.futureSupportRejected);
v.control = struct;

% The following checks apply to the explicitly truth-assisted control only.
if ~isempty(control)
    c = control.caig;
    e = control.estimate;
    s = control.synchronized;
    v.control.label = control.label;
    v.control.acquisitionSucceeded = false;  % Oracle is not available to the instrument.
    v.control.rateMaxErrorRadPerSec = max(abs(c.RateARadPerSec - latent.omegaARadPerSec), [], 1);
    v.control.loopPhaseMaxErrorRad = max([max(abs(c.PhaseLoop1RecRad-latent.phaseLoop1Rad),[],'all'), ...
        max(abs(c.PhaseLoop2RecRad-latent.phaseLoop2Rad),[],'all')]);
    assert(max(v.control.rateMaxErrorRadPerSec) < 1e-12 && v.control.loopPhaseMaxErrorRad < 1e-8);
    % A probability perturbation with oracle labels fixed still changes output.
    altered = probabilities(1,:);
    altered.P1(1, 1) = altered.P1(1, 1) + 1e-5;
    labels = control.externalBranchLabels;
    names = {'sign1','sign2','fringe1','fringe2'};
    for j = 1:numel(names),
        labels.(names{j}) = labels.(names{j})(1,:);
    end
    changed = figrepro_knownBranchControl(altered, cfg.inverse, labels);
    v.control.probabilityInterventionRateChange = changed.RateARadPerSec(1, 1) - c.RateARadPerSec(1, 1);
    assert(abs(v.control.probabilityInterventionRateChange) > 1e-11, 'Control bypassed probabilities.');
    cut = 101;
    fogAltered = fog;
    future = t > c.AvailableSec(cut) + 1e-9;
    fogAltered.RateFRadPerSec(future,:) = 1e6;
    prefix = figrepro_synchronizeT20ms(fogAltered, c(1:cut,:), cfg.fog);
    prefixEstimate = figrepro_zhang(prefix, cfg.filter);
    v.control.causalPrefixMaxStateDifference = max(abs(prefixEstimate.state - e.state(1:cut,:)), ...
        [], 'all');
    assert(v.control.causalPrefixMaxStateDifference == 0, ...
        'Future samples changed past control estimates.');
    % Replacing later probabilities with arbitrary valid observations likewise
    % cannot affect earlier probability inversion with fixed oracle labels.
    changedP = probabilities;
    changedP.P1(cut + 1:end,:) = .4;
    changedP.P2(cut + 1:end,:) = .6;
    recon = figrepro_knownBranchControl(changedP, cfg.inverse, control.externalBranchLabels);
    v.control.probabilityPrefixDifference = max(abs(recon.RateARadPerSec(1:cut, ...
        :) - c.RateARadPerSec(1:cut,:)), [], 'all');
    assert(v.control.probabilityPrefixDifference == 0);
    v.control.minimumCovarianceEigenvalue = inf;
    for j = 1:size(e.covariance, 3)
        P = e.covariance(:,:, j);
        assert(norm(P - P.', 'fro') < 1e-16);
        v.control.minimumCovarianceEigenvalue = min(v.control.minimumCovarianceEigenvalue, min(eig(P)));
    end
    assert(v.control.minimumCovarianceEigenvalue >= -1e-18 && all(isfinite(e.state), 'all'));
    v.control.sensitivityRank = e.sensitivityRank;

    v.control.finalMisalignmentDeg = rad2deg(e.state(end, 1:3));
    v.control.finalBiasDegH = rad2deg(e.state(end, 4:6)) * 3600;
    v.control.finalMisalignmentErrorDeg = ...
        v.control.finalMisalignmentDeg - rad2deg(cfg.simulation.misalignmentRad).';
    v.control.finalBiasErrorDegH = ...
        v.control.finalBiasDegH - rad2deg(cfg.simulation.biasFRadPerSec) * 3600;
    v.control.maximumSupportPastAvailabilitySec = max(s.LastSupportSec - s.AvailableSec);
    v.control.lastMinuteMeanMisalignmentDeg = rad2deg(mean(e.state(e.availableSec > 540, 1:3), 1));
    v.control.lastMinuteMeanBiasDegH = rad2deg(mean(e.state(e.availableSec > 540, 4:6), 1)) * 3600;
    if strcmp(cfg.caseName, 'constant_speed')
        assert(e.sensitivityRank == 3);
        U = e.sensitivityNullspace;
        D = diag(1 ./ cfg.filter.priorStd);
        v.control.nullspacePriorCovarianceChange = norm(U.' * D * e.covariance(:,:, end) * D * ...
            U - eye(3), 'fro');
        assert(v.control.nullspacePriorCovarianceChange < 1e-7);
        v.control.qualitativeInterpretation = ...
            'Figure 6 style: rank 3/6; prior-dependent state plateaus, even with oracle branch labels.';
    else
        assert(e.sensitivityRank == 6);
        v.control.qualitativeInterpretation = ...
            'Figure 8 style control: rank 6/6; richer excitation. State errors retain model/noise effects; oracle branch labels are required.';
    end
    v.control.validationPassed = true;
end
v.allChecksPassed = true;
end

function yes = rejects(f, identifier)
yes = false;
try
    f();
catch issue
    if strcmp(issue.identifier, identifier),
        yes = true;
    else,
        rethrow(issue);
    end
end
end
