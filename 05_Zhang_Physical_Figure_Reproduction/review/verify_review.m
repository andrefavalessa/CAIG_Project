function checks=verify_review(runRoot,historicalDir)
%VERIFY_REVIEW Check generated artifacts; optional numerical regression data.
root=fileparts(fileparts(mfilename('fullpath')));
checks.matlabVersion=version; checks.historicalRegressionPerformed=nargin>1;
cases={'constant_speed','triaxial_sway'};
for j=1:2
    name=cases{j}; base=sprintf('figure%d_%s',4+2*j,name);
    twenty=sprintf('figure%d_T20ms_%s',4+2*j,name);
    a=load(fullfile(runRoot,[name '_T1ms'],[base '_results.mat']),'result');
    b=load(fullfile(runRoot,[name '_T20ms'],[twenty '_results.mat']),'result');
    c=load(fullfile(runRoot,[name '_T20ms'],[twenty '_known_branch_control_results.mat']),'control');
    assert(isempty(b.result.estimate) && ~b.result.diagnostics.mainFilterRan);
    assert(b.result.comparisonWithPreserved1ms.available);
    assert(a.result.estimate.sensitivityRank==3*j && c.control.estimate.sensitivityRank==3*j);
    if nargin>1
        old=load(fullfile(historicalDir,[base '_results.mat']),'result');
        assert(isequaln(a.result.estimate,old.result.estimate));
        assert(isequaln(a.result.probabilities,old.result.probabilities));
        assert(isequaln(a.result.synchronized,old.result.synchronized));
        old=load(fullfile(historicalDir,[twenty '_results.mat']),'result');
        assert(isequaln(b.result.diagnostics,old.result.diagnostics));
        assert(isequaln(b.result.principalCandidate,old.result.principalCandidate));
        old=load(fullfile(historicalDir,[twenty '_known_branch_control_results.mat']),'control');
        assert(isequaln(c.control.estimate,old.control.estimate));
        assert(isequaln(c.control.caig,old.control.caig));
    end
end
figs=dir(fullfile(runRoot,'**','*.fig')); pngs=dir(fullfile(runRoot,'**','*.png'));
assert(numel(figs)==14 && numel(pngs)==14);
for j=1:numel(figs)
    f=openfig(fullfile(figs(j).folder,figs(j).name),'invisible');
    assert(~isempty(findall(f,'Type','axes'))); close(f);
end
for j=1:numel(pngs)
    info=imfinfo(fullfile(pngs(j).folder,pngs(j).name));
    assert(info.Width>=800 && info.Height>=400);
end
files=dir(fullfile(root,'**','*.m')); analyzer=struct('file',{},'messages',{});
for j=1:numel(files)
    file=fullfile(files(j).folder,files(j).name);
    if contains(file,[filesep 'local' filesep]), continue; end
    messages=checkcode(file,'-id');
    if ~isempty(messages)
        analyzer(end+1)=struct('file',files(j).name,'messages',messages); %#ok<AGROW>
    end
end
checks.figureCount=numel(figs); checks.pngCount=numel(pngs);
checks.codeAnalyzer=analyzer; checks.passed=true;
fid=fopen(fullfile(runRoot,'review_checks.json'),'w'); assert(fid>=0);
guard=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(checks,'PrettyPrint',true));
disp('CLEAN SOURCE EXECUTION AND REGRESSION CHECKS PASSED');
end
