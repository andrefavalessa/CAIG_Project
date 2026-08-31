function caigPhysics = simulateCAIGPhysicsY(truth,cfg)
%SIMULATECAIGPHYSICSY Validate the V1 Y-sensitive CAIG phase geometry.
%
% Geometry is unchanged: cloud velocities +/-X, k_eff +Z, gravity -Z.
% This physical phase layer is separate from the three-axis rate-level
% CAIG sensor model. Transition probability is not inverted to rate.

    v1 = [cfg.vAtom 0 0];
    v2 = [-cfg.vAtom 0 0];
    keffVec = [0 0 cfg.keff];
    gVec = [0 0 -cfg.g0];

    v1Matrix = repmat(v1,truth.NCAIG,1);
    v2Matrix = repmat(v2,truth.NCAIG,1);
    gMatrix = repmat(gVec,truth.NCAIG,1);

    phaseRot1 = ...
        -2*cfg.T^2 ...
        *(cross(truth.OmegaCAIG,v1Matrix,2)*keffVec.');

    phaseRot2 = ...
        -2*cfg.T^2 ...
        *(cross(truth.OmegaCAIG,v2Matrix,2)*keffVec.');

    phaseGravity = (gVec*keffVec.')*cfg.T^2;

    phaseOmegaG = ...
        -2*cfg.T^3 ...
        *(cross(truth.OmegaCAIG,gMatrix,2)*keffVec.');

    DeltaPhi0 = 0;

    phaseTotal1 = ...
        phaseGravity+phaseRot1+phaseOmegaG+DeltaPhi0;
    phaseTotal2 = ...
        phaseGravity+phaseRot2+phaseOmegaG+DeltaPhi0;

    phaseDiff = phaseTotal1-phaseTotal2;

    P1 = 0.5*(1-cos(phaseTotal1));
    P2 = 0.5*(1-cos(phaseTotal2));

    Ksingle = 2*cfg.keff*cfg.vAtom*cfg.T^2;
    Kdual = 4*cfg.keff*cfg.vAtom*cfg.T^2;

    OmegaY_fromPhase = phaseDiff/Kdual;
    phaseRateError = OmegaY_fromPhase-truth.OmegaCAIG(:,2);
    maxPhaseRateError = max(abs(phaseRateError));

    caigPhysics.phaseRot1 = phaseRot1;
    caigPhysics.phaseRot2 = phaseRot2;
    caigPhysics.phaseGravity = phaseGravity;
    caigPhysics.phaseOmegaG = phaseOmegaG;
    caigPhysics.phaseTotal1 = phaseTotal1;
    caigPhysics.phaseTotal2 = phaseTotal2;
    caigPhysics.phaseDiff = phaseDiff;
    caigPhysics.P1 = P1;
    caigPhysics.P2 = P2;
    caigPhysics.Ksingle = Ksingle;
    caigPhysics.Kdual = Kdual;
    caigPhysics.OmegaY_fromPhase = OmegaY_fromPhase;
    caigPhysics.phaseRateError = phaseRateError;
    caigPhysics.maxRateError = maxPhaseRateError;
end
