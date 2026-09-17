function manifest=reproduce_all(outputRoot)
%REPRODUCE_ALL Four cases in new directories, with explicit baseline inputs.
root=fileparts(mfilename('fullpath'));
if nargin<1, outputRoot=[]; end
out=figrepro_outputDirectory(root,'all',outputRoot);
cases={'constant_speed','triaxial_sway'};
for j=1:2
    name=cases{j}; baselineDir=fullfile(out,[name '_T1ms']);
    figrepro_runCase(name,root,baselineDir);
    baselineFile=fullfile(baselineDir,sprintf('figure%d_%s_results.mat',4+2*j,name));
    figrepro_runT20ms(name,root,fullfile(out,[name '_T20ms']),baselineFile);
end
manifest.outputRoot=out;
manifest.matlabVersion=version;
save(fullfile(out,'run_manifest.mat'),'manifest');
fprintf('All outputs: %s\n',out);
end
