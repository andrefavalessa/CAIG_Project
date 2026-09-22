function caig = figrepro_reconstruct(probabilities, settings)
%FIGREPRO_RECONSTRUCT Measurement-only principal inversion, adapted from V3.
% A single cosine gives +/-alpha+2*pi*n. Here +alpha,n=0 is a declared,
% design-bounded operating assumption for BOTH loops, not a solved bootstrap.
% No FOG, phase truth, angular truth, branch labels or injected state enters.

assert(isequal(settings.assumedLoopIntervalRad, [0 pi]), 'Unsupported inverse branch.');

% Invert each measured transition probability before forming a difference.
phase1 = principal(probabilities.P1, settings.probabilityTolerance);
phase2 = principal(probabilities.P2, settings.probabilityTolerance);
phaseDiff = phase1 - phase2;  % Difference AFTER probability inversion.
omegaA = phaseDiff / settings.KdualSec;  % A-frame rate reconstructed from phase.

caig = probabilities(:, {'EffectiveSec','FirstPulseSec','LastPulseSec','AvailableSec'});
caig.PhaseLoop1RecRad = phase1;
caig.PhaseLoop2RecRad = phase2;
caig.PhaseDiffRecRad = phaseDiff;
caig.RateARadPerSec = omegaA;
end

function alpha = principal(P, tol)
% Tolerance permits floating-point roundoff, not arbitrary detector clipping.
assert(all(isfinite(P) & P >= -tol & P <= 1 + tol, 'all'), ...
    'figrepro:Probability', 'Invalid transition probability.');
P = min(1, max(0, P));  % Roundoff only; not a detector-noise/clipping model.

% Half-angle forms evaluate the positive principal phase in [0, pi].
% They do not determine a global sign or fringe integer from probability.
alpha = zeros(size(P));
low = P <= .5;
alpha(low) = 2 * asin(sqrt(P(low)));
alpha(~low) = pi - 2 * asin(sqrt(1 - P(~low)));
end
