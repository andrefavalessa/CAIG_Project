% T=20 ms: diagnose principal inversion BEFORE permitting a Zhang-filter run.
projectRoot=fileparts(mfilename('fullpath'));
originalPath=path;
pathGuard=onCleanup(@() path(originalPath));
addpath(projectRoot);
figure6T20msResult=figrepro_runT20ms('constant_speed',projectRoot);
clear pathGuard originalPath projectRoot
