% Figure 6 style: constant speed, full probability-to-rate CAIG chain.
projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
pathGuard = onCleanup(@() path(originalPath));
addpath(projectRoot);
figure6Result = figrepro_runCase('constant_speed', projectRoot);
clear pathGuard originalPath projectRoot
