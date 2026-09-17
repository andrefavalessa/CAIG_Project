function report=run_convergence_review(baselineDir,outputDir)
%RUN_CONVERGENCE_REVIEW Explicit input directory; see fixed protocol in docs.
root=fileparts(fileparts(mfilename('fullpath')));
old=path; guard=onCleanup(@() path(old));
addpath(root,fullfile(root,'sensors'),fullfile(root,'synchronization'),fullfile(root,'estimation'));
if nargin<2, outputDir=[]; end
outputDir=figrepro_outputDirectory(root,'convergence_review',outputDir);
report.protocol='docs/CONVERGENCE_PROTOCOL.md; 0.05 deg, 0.02 deg/h, all axes, 30 s';
report.matlabVersion=version;
names={'constant_speed','triaxial_sway'};
for c=1:2
    file=sprintf('figure%d_%s_results.mat',4+2*c,names{c});
    inputFile=fullfile(baselineDir,file);
    if ~isfile(inputFile)
        inputFile=fullfile(baselineDir,[names{c} '_T1ms'],file);
    end
    saved=load(inputFile,'result');
    r=saved.result; cfg=r.cfg;
    report.historical.(names{c})=metrics(r.estimate,cfg);
    if c==1, continue; end
    a=r.fogSimulation.omegaARadPerSec;
    p=cfg.simulation.misalignmentRad;
    S=[0 -p(3) p(2);p(3) 0 -p(1);-p(2) p(1) 0];
    exact=r.fogSimulation.omegaFRadPerSec+cfg.simulation.biasFRadPerSec;
    linear=a*(eye(3)-S).'+cfg.simulation.biasFRadPerSec;
    noise=r.fogSimulation.noiseFRadPerSec;
    inputs={exact,linear,linear+noise};
    labels={'exact_no_noise','linear_no_noise','linear_original_noise'};
    histories=struct('historical',r.estimate);
    for j=1:numel(inputs)
        f=r.fog; f.RateFRadPerSec=inputs{j};
        sy=figrepro_synchronize(f,r.caig,r.fogSimulation.sampleSigmaRadPerSec);
        est=figrepro_zhang(sy,cfg.filter);
        report.diagnostics.(labels{j})=metrics(est,cfg);
        histories.(labels{j})=est;
    end
    for seed=5607:5611
        fm=cfg.fog; fm.seed=seed;
        [f,fs]=figrepro_fog(seconds(r.fog.Properties.RowTimes),a,fm,cfg.simulation);
        sy=figrepro_synchronize(f,r.caig,fs.sampleSigmaRadPerSec);
        est=figrepro_zhang(sy,cfg.filter);
        label=sprintf('seed_%d',seed);
        report.diagnostics.(label)=metrics(est,cfg);
        histories.(label)=est;
    end
    report.noise.sampleSigmaRadSec=r.fogSimulation.sampleSigmaRadPerSec;
    report.noise.Rrange=[min(r.synchronized.ObservationVariance),max(r.synchronized.ObservationVariance)];
    report.noise.usedFogSamples=numel(unique([r.synchronized.FirstSupportSec;r.synchronized.LastSupportSec]));
    report.noise.totalFogSamples=height(r.fog);
    report.noise.effectiveSamplesPerUpdate=1/mean((1-r.synchronized.RightWeight).^2+r.synchronized.RightWeight.^2);
    report.noise.maxFiniteMinusLinearRateRadSec=max(abs(exact-linear),[],1);
    report.noise.maxFiniteMinusLinearRateDegHour=rad2deg(report.noise.maxFiniteMinusLinearRateRadSec)*3600;
    fig=figure('Visible','off','Color','w','Position',[100 100 1150 700]);
    tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
    shown=[r.estimate.state;histories.linear_no_noise.state];
    alignLimits=limits(rad2deg(shown(:,1:3)));
    biasLimits=limits(rad2deg(shown(:,4:6))*3600);
    for axis=1:3
        nexttile(axis); hold on;
        plot(r.estimate.availableSec,rad2deg(r.estimate.state(:,axis)),'LineWidth',1);
        plot(r.estimate.availableSec,rad2deg(histories.linear_no_noise.state(:,axis)),'LineWidth',1);
        yline(rad2deg(p(axis)),'k--'); grid on;
        title(sprintf('%c alignment',87+axis)); xlabel('Time (s)'); ylabel('deg');
        ylim(alignLimits);
        if axis==1, legend('Historical 1 ms','Linear/noiseless diagnostic','Injected','Location','southeast'); end
        nexttile(axis+3); hold on;
        plot(r.estimate.availableSec,rad2deg(r.estimate.state(:,axis+3))*3600,'LineWidth',1);
        plot(r.estimate.availableSec,rad2deg(histories.linear_no_noise.state(:,axis+3))*3600,'LineWidth',1);
        yline(.1,'k--'); grid on; ylim(biasLimits);
        title(sprintf('%c FOG bias',87+axis)); xlabel('Time (s)'); ylabel('deg/h');
    end
    exportgraphics(fig,fullfile(outputDir,'sway_convergence.png'),'Resolution',160);
    savefig(fig,fullfile(outputDir,'sway_convergence.fig')); close(fig);
    save(fullfile(outputDir,'diagnostic_histories.mat'),'histories','cfg','-v7');
end
fid=fopen(fullfile(outputDir,'convergence.json'),'w'); assert(fid>=0);
fileGuard=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(report,'PrettyPrint',true));
end

function m=metrics(est,cfg)
t=est.availableSec;
e=[rad2deg(est.state(:,1:3))-rad2deg(cfg.simulation.misalignmentRad).', ...
   rad2deg(est.state(:,4:6))*3600-rad2deg(cfg.simulation.biasFRadPerSec)*3600];
a=all(abs(e(:,1:3))<=.05,2); b=all(abs(e(:,4:6))<=.02,2);
m.alignment=event(a,t); m.bias=event(b,t); m.joint=event(a&b,t);
i=find(t<=74.60,1,'last'); m.sampleTimeBy74_60=t(i);
m.errorsBy74_60=e(i,:); m.finalErrors=e(end,:);
m.finalState=[rad2deg(est.state(end,1:3)),rad2deg(est.state(end,4:6))*3600];
m.lastAvailabilitySec=t(end);
end

function e=event(inside,t)
e.firstStartSec=NaN; e.confirmedSec=NaN; e.finalSustainedStartSec=NaN;
edges=diff([false;inside(:);false]); starts=find(edges==1); stops=find(edges==-1)-1;
tol=64*eps(max(t)); % Timestamp roundoff only; does not relax error thresholds.
qual=find(t(stops)-t(starts)>=30-tol,1);
if ~isempty(qual)
    first=starts(qual); e.firstStartSec=t(first);
    e.confirmedSec=t(find(t>=t(first)+30-tol,1));
end
if ~isempty(stops) && stops(end)==numel(t) && t(end)-t(starts(end))>=30-tol
    e.finalSustainedStartSec=t(starts(end));
end
end

function lim=limits(values)
lim=[min(values,[],'all'),max(values,[],'all')];
pad=.04*max(diff(lim),eps); lim=lim+[-pad pad];
end
