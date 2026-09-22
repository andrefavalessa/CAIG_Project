function synced = figrepro_synchronize(fog, caig, fogSampleSigma)
%FIGREPRO_SYNCHRONIZE Explicit effective-time matching, availability-time updates.
% retime interpolates raw F-frame samples to the CAIG midpoint. A bracketing
% sample may follow the midpoint only if it arrives by measurement availability.

assert(istimetable(fog) && istimetable(caig), 'Timetables required.');
tf = seconds(fog.Properties.RowTimes);

% Match the effective CAIG epoch; apply the update only at availability.
te = caig.EffectiveSec;
ta = caig.AvailableSec;
assert(all(diff(tf) > 0) && all(diff(te) > 0) && all(diff(ta) > 0), 'Times must increase.');
assert(all(te >= tf(1) & te <= tf(end)), 'No extrapolation is allowed.');

% Interpolate raw F-frame FOG components to the effective atomic epoch.
fogMatched = retime(fog, seconds(te), 'linear');  % Visible MATLAB timestamp synchronization.

% Audit support and propagate the ACTUAL linear interpolation weights into R.
% Previous/next timestamps identify the left/right FOG support samples.
support = timetable(seconds(tf), tf, 'VariableNames', {'SupportSec'});
left = retime(support, seconds(te), 'previous');
right = retime(support, seconds(te), 'next');
tl = left.SupportSec;
tr = right.SupportSec;

% The right sample may follow te, but it must already be available at ta.
tol = 64 * eps(max(1, max(ta)));
assert(all(tr <= ta + tol), 'figrepro:FutureData', 'FOG interpolation uses unavailable data.');

% beta is the right-sample weight; coincident support leaves beta at zero.
beta = zeros(size(te));
split = tr > tl;
beta(split) = (te(split) - tl(split)) ./ (tr(split) - tl(split));

% Nonoverlapping pairs => white interpolation noise across CAIG updates.
% Shared samples would correlate observations, which this R does not model.
assert(all(tl(2:end) > tr(1:end - 1)), ...
    'figrepro:CorrelatedNoise', 'Overlapping interpolation supports require correlated R.');

% Independent FOG sample noise contributes squared interpolation weights.
sigma2 = fogSampleSigma^2 * ((1 - beta).^2 + beta.^2);

synced = timetable(seconds(ta), te, ta, tl, tr, beta, ...
    fogMatched.RateFRadPerSec, caig.RateARadPerSec, sigma2, ...
    'VariableNames', {'EffectiveSec','AvailableSec','FirstSupportSec','LastSupportSec', ...
    'RightWeight','RateFRadPerSec','RateARadPerSec','ObservationVariance'});
synced.Properties.Description = ...
    'retime linear at effective epoch; updates at availability; support checked causal';
end
