function omegaARadPerSec = figrepro_motion(timeSec,caseName,s)
%FIGREPRO_MOTION Angular rates in the CAIG A frame (row vectors).
% Simulation-only interface; never used by reconstruction or the filter.
t = timeSec(:);
if strcmp(caseName,'constant_speed')
    % Legacy local NED/constant-position approximation at 15 kn, heading 30 deg.
    % Freeze latitude/transport rate: not a propagated navigation trajectory.
    lat=s.latitudeRad; h=s.heightM; heading=s.headingRad;
    e2=s.earthFlattening*(2-s.earthFlattening);
    rn=s.earthSemiMajorM/sqrt(1-e2*sin(lat)^2);
    rm=s.earthSemiMajorM*(1-e2)/(1-e2*sin(lat)^2)^(3/2);
    vN=s.speedMPerSec*cos(heading); vE=s.speedMPerSec*sin(heading);
    omegaIN_N=[s.earthRateRadPerSec*cos(lat);0;-s.earthRateRadPerSec*sin(lat)] + ...
        [vE/(rn+h);-vN/(rm+h);-vE*tan(lat)/(rn+h)];
    C_A_from_N=[cos(heading) sin(heading) 0;-sin(heading) cos(heading) 0;0 0 1];
    omegaARadPerSec=repmat((C_A_from_N*omegaIN_N).',numel(t),1);
else
    % Existing level-2 waveform: exact 3-2-1 Euler-rate to body-rate mapping.
    % Isolated prescribed rotation; no Earth/transport rate added in this case.
    a=s.swayAmplitudeRad; w=2*pi./s.swayPeriodSec;
    roll=a(1)*sin(w(1)*t); pitch=a(2)*sin(w(2)*t);
    rollDot=a(1)*w(1)*cos(w(1)*t);
    pitchDot=a(2)*w(2)*cos(w(2)*t); headingDot=a(3)*w(3)*cos(w(3)*t);
    omegaARadPerSec=[rollDot-headingDot.*sin(pitch), ...
        pitchDot.*cos(roll)+headingDot.*sin(roll).*cos(pitch), ...
        -pitchDot.*sin(roll)+headingDot.*cos(roll).*cos(pitch)];
end
end
