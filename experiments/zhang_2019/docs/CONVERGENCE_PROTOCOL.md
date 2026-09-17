# Fixed diagnostic protocol

Registered before evaluating the review metrics (2026-09-16). No filter tuning.

Use measurement availability time. Alignment is inside tolerance only when
all three absolute errors are <= 0.05 degrees; bias requires all three errors
<= 0.02 degrees/hour. Report each group and their joint condition. The first
qualifying interval must span at least 30 seconds without an excursion.
Report its start AND confirmation time, and the start of the final uninterrupted
in-tolerance interval if it also spans 30 seconds. Missing events are null,
censored at the last available measurement (approximately 600 seconds).
Also report the last measurement available by 74.60 seconds and final errors.
These are project-defined descriptive thresholds, not Zhang's criterion.

Use the saved historical baseline. Limited downstream diagnostics keep its
CAIG measurements, timing, R, x0, P0 and Q fixed: (1) remove FOG white noise;
(2) replace the finite frame rotation with the first-order rotation, first
without noise and then with the original noise; (3) repeat the original model
with seeds 5607 through 5611. Compare paired cases to isolate one factor.
The synthetic linear/noiseless FOG cases are simulator-informed diagnostics,
not operational estimators. No parameters are selected from the outcomes.
No new baseline execution is required to evaluate historical data.
