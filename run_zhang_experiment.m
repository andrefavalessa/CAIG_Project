function manifest=run_zhang_experiment(outputDirectory)
%RUN_ZHANG_EXPERIMENT Run the independent Zhang cases from any working folder.
% No shared src/ or archived version is added to this experiment's path.
root=fileparts(mfilename('fullpath'));
originalPath=path;
pathGuard=onCleanup(@() path(originalPath));
addpath(fullfile(root,'experiments','zhang_2019'));
if nargin<1
    manifest=reproduce_all;
else
    manifest=reproduce_all(outputDirectory);
end
end
