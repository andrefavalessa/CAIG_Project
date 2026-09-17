% T=20 ms: diagnose principal inversion BEFORE permitting a Zhang-filter run.
projectRoot=fileparts(mfilename('fullpath'));
originalPath=path;
pathGuard=onCleanup(@() path(originalPath));
addpath(projectRoot);
figure8T20msResult=figrepro_runT20ms('triaxial_sway',projectRoot);
clear pathGuard originalPath projectRoot
