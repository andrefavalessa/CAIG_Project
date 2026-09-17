function caig=figrepro_knownBranchControl(probabilities,inverse,externalLabels)
%FIGREPRO_KNOWNBRANCHCONTROL Conditional probability inversion, NOT acquisition.
% The harness provides explicitly simulator-derived signs/fringe integers.
% This oracle is NOT available to a practical estimator or the main run.
% No continuous phase or angular truth enters this function or the KF.
caig=figrepro_reconstruct(probabilities,inverse); % Preserved probability-only alpha.
assert(all(abs(externalLabels.sign1)==1,'all') && all(abs(externalLabels.sign2)==1,'all'));
assert(all(externalLabels.fringe1==round(externalLabels.fringe1),'all') && ...
       all(externalLabels.fringe2==round(externalLabels.fringe2),'all'));
caig.PhaseLoop1RecRad=externalLabels.sign1.*caig.PhaseLoop1RecRad+2*pi*externalLabels.fringe1;
caig.PhaseLoop2RecRad=externalLabels.sign2.*caig.PhaseLoop2RecRad+2*pi*externalLabels.fringe2;
caig.PhaseDiffRecRad=caig.PhaseLoop1RecRad-caig.PhaseLoop2RecRad;
caig.RateARadPerSec=caig.PhaseDiffRecRad/inverse.KdualSec;
caig.Properties.Description='KNOWN-BRANCH CONTROL ONLY: requires unavailable simulator-provided discrete branch information';
end
