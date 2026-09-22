function [measurement,latent] = figrepro_caig(shots, omegaA, p)
%FIGREPRO_CAIG Zhang Eqs. (6)-(10), three virtual dual-loop geometries.
% All vectors are in A. Quasi-static inputs are evaluated at the shot midpoint.
% This is NOT an exact time-varying atom trajectory or sensitivity integral.

n = height(shots);
T = p.Tsec;

% Project-design operating envelope used to certify the 1 ms branch.
assert(all(vecnorm(omegaA, 2, 2) <= p.rateNormBoundRadPerSec), ...
    'figrepro:MotionEnvelope', 'Truth generator exceeds the declared operating envelope.');

% Keep simulated physics separate from the observable transition probabilities.
latent.omegaARadPerSec = omegaA;
latent.rotationLoop1Rad = zeros(n, 3);
latent.rotationLoop2Rad = zeros(n, 3);
latent.gravityRad = zeros(n, 3);
latent.rotationGravityRad = zeros(n, 3);
latent.sharedPulseRad = zeros(n, 3);

for axisIndex = 1:3
    % Effective Raman wave vector for this virtual sensing axis.
    k = p.kPerM * p.kDirectionsA(axisIndex,:);

    % Equal and opposite atomic velocities define the two trajectories.
    v1 = p.atomSpeedMPerSec * p.v1DirectionsA(axisIndex,:);
    v2 = -v1;

    % Coriolis/Sagnac rotation phase from Zhang Eq. (6).
    % Reversing atomic velocity reverses the rotation contribution.
    latent.rotationLoop1Rad(:, axisIndex) = ...
        -2 * T^2 * (cross(omegaA, repmat(v1, n, 1), 2) * k.');
    latent.rotationLoop2Rad(:, axisIndex) = ...
        -2 * T^2 * (cross(omegaA, repmat(v2, n, 1), 2) * k.');

    % Gravity and rotation-gravity terms are common to both loops.
    latent.gravityRad(:, axisIndex) = dot(k, p.gravityA) * T^2;
    latent.rotationGravityRad(:, axisIndex) = -2 * T^3 * ...
        (cross(omegaA, repmat(p.gravityA, n, 1), 2) * k.');

    % Configured ideal static compensation, not a physical feedback servo.
    latent.sharedPulseRad(:, axisIndex) = p.sharedPulsePhaseRad(axisIndex);
end

latent.commonRad = ...
    latent.gravityRad + latent.rotationGravityRad + latent.sharedPulseRad;

% Compute and retain two totals independently. No differential phase replaces them.
latent.phaseLoop1Rad = ...
    latent.commonRad + latent.rotationLoop1Rad + p.loopOffsetRad(1);
latent.phaseLoop2Rad = ...
    latent.commonRad + latent.rotationLoop2Rad + p.loopOffsetRad(2);

% Differential phase is retained for validation only, not passed to the inverse.
latent.phaseDiffRad = latent.phaseLoop1Rad - latent.phaseLoop2Rad;

% Assert the independently declared operating assumption, never repair branches.
% The baseline inverse is only certified for phases inside (0, pi).
assert(all(latent.phaseLoop1Rad > 0 & latent.phaseLoop1Rad < pi, 'all') && ...
    all(latent.phaseLoop2Rad > 0 & latent.phaseLoop2Rad < pi, 'all'), ...
    'figrepro:BranchViolation', 'A generated loop left the declared principal branch.');

% Finite atom count and phase/detection noise are not modeled here.
assert(p.phaseNoiseStdRad == 0, 'figrepro:Readout', 'Only explicitly ideal detection is implemented.');

% Zhang's actual individual-loop probabilities. No rate-level noise/output shortcut.
P1 = (1 - cos(latent.phaseLoop1Rad)) / 2;
P2 = (1 - cos(latent.phaseLoop2Rad)) / 2;

% Observable output contains timing and P1/P2; latent stays separate.
measurement = shots;
measurement.P1 = P1;
measurement.P2 = P2;
% The measurement contains timing and probabilities only; latent is validation-only.
end
