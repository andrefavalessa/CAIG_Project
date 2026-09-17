% Figure 8 style: level-2 triaxial sway, full probability-to-rate CAIG chain.
projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
pathGuard = onCleanup(@() path(originalPath));
addpath(projectRoot);
figure8Result = figrepro_runCase('triaxial_sway', projectRoot);
clear pathGuard originalPath projectRoot
