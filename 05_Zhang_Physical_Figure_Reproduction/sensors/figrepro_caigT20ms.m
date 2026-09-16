function [measurement,latent]=figrepro_caigT20ms(shots,omegaA,p)
%FIGREPRO_CAIGT20MS Same Zhang vector chain; branches are diagnosed, not assumed.
% omegaA is the independent reference's 2T rectangular average in frame A.
% Substitution of this mean is a reduced dynamic extension of the constant-
% input model, not a claimed exact atom-interferometer sensitivity response.
n=height(shots); T=p.Tsec;
assert(all(vecnorm(omegaA,2,2)<=p.rateNormBoundRadPerSec));
latent.omegaARadPerSec=omegaA;
latent.rotationLoop1Rad=zeros(n,3); latent.rotationLoop2Rad=zeros(n,3);
latent.gravityRad=zeros(n,3); latent.rotationGravityRad=zeros(n,3);
latent.sharedPulseRad=zeros(n,3);
for axisIndex=1:3
    k=p.kPerM*p.kDirectionsA(axisIndex,:);
    v1=p.atomSpeedMPerSec*p.v1DirectionsA(axisIndex,:); v2=-v1;
    latent.rotationLoop1Rad(:,axisIndex)=-2*T^2*(cross(omegaA,repmat(v1,n,1),2)*k.');
    latent.rotationLoop2Rad(:,axisIndex)=-2*T^2*(cross(omegaA,repmat(v2,n,1),2)*k.');
    latent.gravityRad(:,axisIndex)=dot(k,p.gravityA)*T^2;
    latent.rotationGravityRad(:,axisIndex)=-2*T^3* ...
        (cross(omegaA,repmat(p.gravityA,n,1),2)*k.');
    latent.sharedPulseRad(:,axisIndex)=p.sharedPulsePhaseRad(axisIndex);
end
latent.commonRad=latent.gravityRad+latent.rotationGravityRad+latent.sharedPulseRad;
latent.phaseLoop1Rad=latent.commonRad+latent.rotationLoop1Rad+p.loopOffsetRad(1);
latent.phaseLoop2Rad=latent.commonRad+latent.rotationLoop2Rad+p.loopOffsetRad(2);
latent.phaseDiffRad=latent.phaseLoop1Rad-latent.phaseLoop2Rad;
assert(p.phaseNoiseStdRad==0,'Only ideal readout is implemented.');
measurement=shots;
measurement.P1=(1-cos(latent.phaseLoop1Rad))/2;
measurement.P2=(1-cos(latent.phaseLoop2Rad))/2;
% No branch restriction, clipping of phase, or phase-to-rate shortcut here.
end
