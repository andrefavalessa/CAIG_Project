function [d,controlLabels]=figrepro_T20msDiagnostics(latent,principal,cfg)
%FIGREPRO_T20MSDIAGNOSTICS Simulation-side audit BEFORE any filter is invoked.
% Labels below are inaccessible observations in practice. They are exported
% solely for a clearly separated known-branch control, never the main inverse.
L1=latent.phaseLoop1Rad; L2=latent.phaseLoop2Rad;
outside1=L1<0 | L1>pi; outside2=L2<0 | L2>pi;
wrapped1=atan2(sin(L1),cos(L1)); wrapped2=atan2(sin(L2),cos(L2));
controlLabels.sign1=ones(size(L1)); controlLabels.sign1(wrapped1<0)=-1;
controlLabels.sign2=ones(size(L2)); controlLabels.sign2(wrapped2<0)=-1;
controlLabels.fringe1=round((L1-wrapped1)/(2*pi));
controlLabels.fringe2=round((L2-wrapped2)/(2*pi));
controlLabels.provenance='SIMULATOR ORACLE: signs and integer fringes derived from latent phases; control only';
d.caseName=cfg.caseName;
d.shotCount=size(L1,1); d.scalarLoopPhaseCount=2*numel(L1);
d.KsingleSec=cfg.caig.KsingleSec; d.KdualSec=cfg.caig.KdualSec;
d.interrogationDurationSec=2*cfg.caig.Tsec;
d.fogIntegrationWindowSec=2*cfg.caig.Tsec;
d.measurementAvailabilityOffsetSec=cfg.caig.availableOffsetSec;
d.maxAbsLoop1PhaseRad=max(abs(L1),[],1);
d.maxAbsLoop2PhaseRad=max(abs(L2),[],1);
d.maxAbsAnyLoopPhaseRad=max(abs([L1 L2]),[],'all');
d.maxAbsDifferentialPhaseRad=max(abs(latent.phaseDiffRad),[],1);
d.maxAbsAnyDifferentialPhaseRad=max(abs(latent.phaseDiffRad),[],'all');
d.maxAbsRotationGravityRad=max(abs(latent.rotationGravityRad),[],1);
d.outsidePrincipalCountLoop1=sum(outside1,1);
d.outsidePrincipalCountLoop2=sum(outside2,1);
d.outsidePrincipalFractionLoop1=mean(outside1,1);
d.outsidePrincipalFractionLoop2=mean(outside2,1);
d.outsidePrincipalCountByAxisPair=sum(outside1|outside2,1);
d.outsidePrincipalFractionByAxisPair=mean(outside1|outside2,1);
d.shotsWithAnyLoopOutside=sum(any(outside1|outside2,2));
d.fractionShotsWithAnyLoopOutside=d.shotsWithAnyLoopOutside/d.shotCount;
d.fractionScalarLoopPhasesOutside=mean([outside1(:);outside2(:)]);
d.negativeSignRequiredCountLoop1=sum(controlLabels.sign1<0,1);
d.negativeSignRequiredCountLoop2=sum(controlLabels.sign2<0,1);
d.nonzeroFringeRequiredCountLoop1=sum(controlLabels.fringe1~=0,1);
d.nonzeroFringeRequiredCountLoop2=sum(controlLabels.fringe2~=0,1);
signRequired=controlLabels.sign1<0 | controlLabels.sign2<0;
fringeRequired=controlLabels.fringe1~=0 | controlLabels.fringe2~=0;
d.shotsRequiringNegativeSignByAxis=sum(signRequired,1);
d.fractionShotsRequiringNegativeSignByAxis=mean(signRequired,1);
d.shotsRequiringNonzeroFringeByAxis=sum(fringeRequired,1);
d.fractionShotsRequiringNonzeroFringeByAxis=mean(fringeRequired,1);
d.fractionShotsRequiringAnyNegativeSign=mean(any(signRequired,2));
d.fractionShotsRequiringAnyNonzeroFringe=mean(any(fringeRequired,2));
d.fractionShotsRequiringSignOrFringe=mean(any(signRequired|fringeRequired,2));
d.fractionShotsWithAnyLoopMagnitudeAboveTwoPi=mean(any(abs(L1)>2*pi | abs(L2)>2*pi,2));
d.fringeIntegerRangeLoop1=[min(controlLabels.fringe1,[],1);max(controlLabels.fringe1,[],1)];
d.fringeIntegerRangeLoop2=[min(controlLabels.fringe2,[],1);max(controlLabels.fringe2,[],1)];
d.signAmbiguityEncountered=any([controlLabels.sign1(:);controlLabels.sign2(:)]<0);
d.nonzeroTwoPiAliasRequired=any([controlLabels.fringe1(:);controlLabels.fringe2(:)]~=0);
d.physicalLoopMagnitudeExceedsTwoPi=any(abs([L1(:);L2(:)])>2*pi);
d.cosineHasUnboundedSignAndFringeFamilies=true; % Even at 1 ms; then the design bounded them.
d.designEnvelopeGuaranteed=cfg.inverse.designEnvelopeGuaranteed;
d.designBranchDepartureBoundRad=cfg.inverse.maximumDepartureFromMidfringeRad;
d.principalRateBoundRadPerSec=pi/cfg.caig.KdualSec;
err=principal.RateARadPerSec-latent.omegaARadPerSec;
d.principalRateRmseRadPerSec=sqrt(mean(err.^2,1));
d.principalRateMaxAbsErrorRadPerSec=max(abs(err),[],1);
d.principalMaxAbsOutputRateRadPerSec=max(abs(principal.RateARadPerSec),[],1);
d.physicalMaxAbsRateRadPerSec=max(abs(latent.omegaARadPerSec),[],1);
d.currentReconstructionValid=d.shotsWithAnyLoopOutside==0 && max(abs(err),[],'all')<1e-12;
d.mainFilterRan=false;
d.failureCause='';
if ~d.currentReconstructionValid
    d.failureCause='Principal +acos,n=0 branch restriction is violated before the Zhang filter; folded candidate rates are diagnostic only.';
end
d.branchDiagnosticConvention='Phi=s*alpha+2*pi*n with wrapped angle in [-pi,pi]. Nonzero n can occur for pi<Phi<2*pi; it is not the same as |Phi|>2*pi.';
end
