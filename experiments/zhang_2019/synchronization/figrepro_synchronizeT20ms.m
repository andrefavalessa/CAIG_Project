function synced = figrepro_synchronizeT20ms(fog, caig, model)
%FIGREPRO_SYNCHRONIZET20MS Match raw F components over the same CAIG 2T window.

integral = figrepro_windowMean(fog, caig, model.sampleRateHz);

% Propagate independent FOG sample noise through the matched window weights.
sigma = model.noiseDensity * sqrt(model.sampleRateHz);  % Preserved single-sided convention.
sigma2 = repmat(sigma^2 * integral.varianceWeight, height(caig), 1);

% Reused samples would correlate updates, beyond the modeled observation R.
assert(all(integral.supportSec(2:end, 1) > integral.supportSec(1:end - 1, end)), ...
    'Overlapping shot supports require a correlated noise covariance.');

% Updates occur at readout availability, after all window support has arrived.
synced = timetable(seconds(caig.AvailableSec), caig.EffectiveSec, caig.AvailableSec, ...
    caig.FirstPulseSec, caig.LastPulseSec, integral.supportSec(:, 1), integral.supportSec(:, end), ...
    integral.mean, caig.RateARadPerSec, sigma2, ...
    'VariableNames', {'EffectiveSec','AvailableSec','FirstPulseSec','LastPulseSec', ...
    'FirstSupportSec','LastSupportSec','RateFRadPerSec','RateARadPerSec','ObservationVariance'});
synced.Properties.UserData = integral;
synced.Properties.Description = ...
    'Explicit retime + 2T rectangular FOG integral; update at availability; no pre-correction';
end
