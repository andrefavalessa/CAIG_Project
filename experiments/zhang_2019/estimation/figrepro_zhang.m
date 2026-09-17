function estimate = figrepro_zhang(synced,settings)
%FIGREPRO_ZHANG Zhang six-state, constant-state Kalman model (Joseph form).
% State = [phi_A (rad); bias_F (rad/s)]. Measurements only; no truth interface.
% z = raw F components - reconstructed A components. These axes are near
% parallel, so this cross-frame component comparison uses Zhang's first-order
% model, not subtraction asserted to be an exact vector in a single frame.
% H=[skew(omega_A_rec),I]. Neither bias nor alignment is pre-corrected.
n=height(synced); x=settings.initialState; P=diag(settings.priorStd.^2);
estimate.state=zeros(n,6); estimate.std=zeros(n,6);
estimate.innovation=zeros(n,3); estimate.covariance=zeros(6,6,n);
estimate.information=zeros(6); estimate.Hstack=zeros(3*n,6);
for j=1:n
    x=settings.F*x; P=settings.F*P*settings.F.'+settings.Q;
    a=synced.RateARadPerSec(j,:);
    S=[0 -a(3) a(2);a(3) 0 -a(1);-a(2) a(1) 0];
    H=[S eye(3)];
    z=(synced.RateFRadPerSec(j,:)-a).';
    R=synced.ObservationVariance(j)*eye(3); % Ideal CAIG, actual FOG retime weights.
    innovation=z-H*x;
    K=(P*H.')/(H*P*H.'+R);
    x=x+K*innovation;
    J=eye(6)-K*H;
    P=J*P*J.'+K*R*K.'; P=(P+P.')/2;
    estimate.state(j,:)=x.';
    estimate.std(j,:)=sqrt(max(0,diag(P))).';
    estimate.innovation(j,:)=innovation.';
    estimate.covariance(:,:,j)=P;
    estimate.Hstack(3*j-2:3*j,:)=H;
    estimate.information=estimate.information+H.'*(R\H);
end
estimate.availableSec=synced.AvailableSec;
estimate.initialState=settings.initialState;
estimate.initialStd=settings.priorStd;
% Scale columns by prior units to avoid calling rad and rad/s equal scales.
scaledH=estimate.Hstack*diag(settings.priorStd);
estimate.sensitivitySingularValues=svd(scaledH,0);
estimate.sensitivityRank=sum(estimate.sensitivitySingularValues > ...
    1e-8*estimate.sensitivitySingularValues(1));
estimate.sensitivityNullspace=null(scaledH,1e-8*estimate.sensitivitySingularValues(1));
estimate.model='First-order Zhang H; exact finite sensor rotation gives a second-order model discrepancy.';
end
