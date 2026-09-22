function out = figrepro_windowMean(measurement, shots, sampleRateHz)
%FIGREPRO_WINDOWMEAN Timestamp-checked trapezoidal integral over each 2T shot.
% Input has one numeric N-by-D timetable variable. Endpoints must coincide
% with its uniform sample grid; true off-grid windows are rejected. retime
% selects by timestamps, with only 64-ulp coincidence reconciliation.

% Uniform sampling and aligned windows are required by this quadrature rule.
assert(istimetable(measurement) && width(measurement) == 1 && istimetable(shots));
tf = seconds(measurement.Properties.RowTimes);
assert(all(diff(tf) > 0) && all(abs(diff(tf) - 1 / sampleRateHz) < 1e-10));
duration = shots.LastPulseSec - shots.FirstPulseSec;
assert(all(abs(duration - duration(1)) < 1e-10) && duration(1) > 0);
intervals = round(duration(1) * sampleRateHz);
assert(intervals >= 1 && abs(intervals / sampleRateHz - duration(1)) < 1e-10);

offsets = (0:intervals) / sampleRateHz;
query = shots.FirstPulseSec + offsets;  % Rows=shots, columns=integration nodes.
tol = 64 * eps(max(1, max([tf;shots.AvailableSec])));
assert(all(query(:) >= tf(1) - tol & query(:) <= tf(end) + tol), 'No extrapolation.');

% Sort into chronology explicitly rather than assuming source array offsets.
queryVector = reshape(query.', [], 1);
assert(all(diff(queryVector) > 0), 'Shot windows overlap or repeat source epochs.');
matched = retime(measurement, seconds(queryVector), 'nearest');
stamp = timetable(measurement.Properties.RowTimes, tf, 'VariableNames', {'Sec'});
matchedStamp = retime(stamp, seconds(queryVector), 'nearest');
support = reshape(matchedStamp.Sec, numel(offsets), []).';
residual = abs(support - query);

% Nearest matching reconciles roundoff only; genuine off-grid nodes are rejected.
assert(all(residual <= tol, 'all'), 'figrepro:OffGridWindow', ...
    'A window endpoint/node is genuinely off-grid.');
assert(all(support(:, end) <= shots.AvailableSec + tol), ...
    'figrepro:FutureData', 'Integration needs samples unavailable at the update.');

% Normalized trapezoidal weights represent the rectangular 2T window mean.
weights = ones(1, numel(offsets)) / intervals;
weights([1 end]) = weights([1 end]) / 2;  % Integral divided by 2T.

data = matched{:,1};
out.mean = zeros(height(shots), size(data, 2));
for axisIndex = 1:size(data, 2)
    values = reshape(data(:, axisIndex), numel(offsets), []).';
    out.mean(:, axisIndex) = values * weights.';
end

out.weights = weights;
out.supportSec = support;
out.maximumTimestampResidualSec = max(residual, [], 'all');
out.windowDurationSec = duration;
% Independent white sample noise propagates through squared weights.
out.varianceWeight = sum(weights.^2);
out.model = 'Trapezoidal time integral / window duration on timestamp-matched samples';
end
