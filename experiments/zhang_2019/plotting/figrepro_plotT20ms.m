function files=figrepro_plotT20ms(result,control,out)
%FIGREPRO_PLOTT20MS Main failure status, phase audit, and labeled oracle control.
cfg=result.cfg; d=result.diagnostics; stem=fullfile(out,cfg.outputStem);
names={'X','Y','Z'}; colors=[0 .36 .59;.80 .28 .13;.13 .53 .36];
caseTitle=strrep(cfg.caseName,'_',' ');
files.main={}; files.control={};
quantities={'misalignment','fog_bias'};
if isempty(result.estimate)
    % No estimate curve is fabricated when the pre-filter branch audit fails.
    for j=1:2
        fig=figure('Visible','off','Color','w','Position',[80 80 1120 640]);
        guard=onCleanup(@() close(fig));
        ax=axes(fig,'Position',[.07 .08 .86 .8],'XLim',[0 1],'YLim',[0 1]); axis(ax,'off');
        rectangle(ax,'Position',[0 0 1 1],'FaceColor','w','EdgeColor','w');
        title(ax,sprintf('T = 20 ms | %s | %s',caseTitle,strrep(quantities{j},'_',' ')), ...
            'FontSize',21,'FontName','Arial','Interpreter','none');
        text(ax,.02,.82,'NORMAL ZHANG FILTER BLOCKED','Units','normalized', ...
            'FontSize',25,'FontWeight','bold','Color',[.7 .15 .10]);
        lines={ ...
            'The physical probabilities do not validate the assumed +acos, n = 0 branch.'; ...
            sprintf('%d / %d shots have at least one loop outside [0, pi].',d.shotsWithAnyLoopOutside,d.shotCount); ...
            sprintf('Maximum |loop phase| = %.4f rad; maximum |differential| = %.4f rad.', ...
                d.maxAbsAnyLoopPhaseRad,d.maxAbsAnyDifferentialPhaseRad); ...
            'No normal state estimate was generated or supplied with true phase.'; ...
            'See the ambiguity plots and separately named KNOWN-BRANCH CONTROL.'; ...
            'The control is conditional on simulator-known signs and fringe integers.'};
        for q=1:numel(lines)
            text(ax,.02,.65-(q-1)*.105,lines{q},'Units','normalized', ...
                'FontSize',14,'FontName','Arial','Interpreter','none');
        end
        files.main=[files.main;savePair(fig,[stem '_' quantities{j}],cfg.plot.dpi)];
        clear guard
    end
else
    files.main=historyPlots(result.estimate,cfg,stem,'VALID PRINCIPAL RUN',out);
end

fig=figure('Visible','off','Color','w','Position',[60 40 1350 850]);
guard=onCleanup(@() close(fig));
tiles=tiledlayout(fig,3,2,'Padding','compact','TileSpacing','compact');
title(tiles,sprintf('T = 20 ms | %s | ambiguity before filtering',caseTitle), ...
    'FontName','Arial','FontSize',21,'FontWeight','bold');
subtitle(tiles,sprintf('First 60 s shown | %.1f%% of full-run shots violate the principal loop region | normal filter blocked', ...
    100*d.fractionShotsWithAnyLoopOutside),'FontSize',12);
use=result.probabilities.EffectiveSec<=60;
t=result.probabilities.EffectiveSec(use);
for axisIndex=1:3
    ax=nexttile(tiles);
    plot(ax,t,result.latentCAIG.phaseLoop1Rad(use,axisIndex),'Color',[0 .36 .59],'LineWidth',1.05);
    hold(ax,'on');
    plot(ax,t,result.latentCAIG.phaseLoop2Rad(use,axisIndex),'Color',[.85 .36 .1],'LineWidth',1.05);
    yline(ax,0,':','Color',[.25 .25 .25]); yline(ax,pi,':','Color',[.25 .25 .25]);
    title(ax,[names{axisIndex} ' axis | separate physical loops'],'FontSize',13);
    ylabel(ax,'Loop phase (rad)'); style(ax); xlim(ax,[0 60]);
    phases=[result.latentCAIG.phaseLoop1Rad(use,axisIndex); ...
        result.latentCAIG.phaseLoop2Rad(use,axisIndex);0;pi];
    phaseSpan=max(max(phases)-min(phases),1);
    ylim(ax,[min(phases)-.08*phaseSpan,max(phases)+.08*phaseSpan]);
    if axisIndex==1
        legend(ax,{'Loop 1','Loop 2','Principal bounds'},'Location','southoutside', ...
            'Orientation','horizontal','Box','off');
    end
    if axisIndex==3, xlabel(ax,'Effective time (s)'); end
    ax=nexttile(tiles);
    plot(ax,t,result.latentCAIG.omegaARadPerSec(use,axisIndex)*1e3, ...
        'Color',colors(axisIndex,:),'LineWidth',1.2); hold(ax,'on');
    plot(ax,t,result.principalCandidate.RateARadPerSec(use,axisIndex)*1e3, ...
        '--','Color',[.65 .1 .18],'LineWidth',1.05);
    title(ax,[names{axisIndex} ' axis | principal candidate, full triad rejected'],'FontSize',12);
    ylabel(ax,'A-frame rate (mrad/s)'); style(ax); xlim(ax,[0 60]);
    rates=[result.latentCAIG.omegaARadPerSec(use,axisIndex); ...
        result.principalCandidate.RateARadPerSec(use,axisIndex)]*1e3;
    span=max(max(rates)-min(rates),.01);
    ylim(ax,[min(rates)-.08*span,max(rates)+.08*span]);
    if strcmp(cfg.caseName,'constant_speed'), ytickformat(ax,'%.4f');
    else, ytickformat(ax,'%.2f'); end
    if axisIndex==1
        legend(ax,{'Physical reference (audit only)','Principal candidate'}, ...
            'Location','southoutside','Orientation','horizontal','Box','off');
    end
    if axisIndex==3, xlabel(ax,'Effective time (s)'); end
end
files.ambiguity=savePair(fig,[stem '_ambiguity'],cfg.plot.dpi);
clear guard
if ~isempty(control)
    files.control=historyPlots(control.estimate,cfg,[stem '_known_branch_control'], ...
        'KNOWN-BRANCH CONTROL',out);
end
end

function files=historyPlots(e,cfg,stem,label,~)
colors=[0 .36 .59;.80 .28 .13;.13 .53 .36]; names={'X','Y','Z'};
t=[0;e.availableSec]/60; state=[e.initialState.';e.state];
reference=[cfg.simulation.misalignmentRad;cfg.simulation.biasFRadPerSec.'];
files=cell(4,1);
for quantity=1:2
    fig=figure('Visible','off','Color','w','Position',[80 50 1120 790]);
    guard=onCleanup(@() close(fig));
    tiles=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
    if quantity==1
        indices=1:3; factor=180/pi; unit='deg'; name='misalignment'; labelQuantity='Misalignment';
    else
        indices=4:6; factor=180/pi*3600; unit='deg/h'; name='fog_bias'; labelQuantity='FOG bias';
    end
    title(tiles,sprintf('%s | %s',label,strrep(cfg.caseName,'_',' ')), ...
        'FontName','Arial','FontSize',21,'FontWeight','bold');
    subtitle(tiles,sprintf('T = 20 ms | %s | simulator-known sign/fringes required | sensitivity rank %d/6', ...
        labelQuantity,e.sensitivityRank),'FontSize',12);
    for axisIndex=1:3
        ax=nexttile(tiles); idx=indices(axisIndex);
        l1=plot(ax,t,state(:,idx)*factor,'Color',colors(axisIndex,:),'LineWidth',1.25);
        hold(ax,'on'); l2=yline(ax,reference(idx)*factor,'--','Color',[.3 .3 .3],'LineWidth',1.1);
        style(ax); ylabel(ax,sprintf('%s %s (%s)',labelQuantity,names{axisIndex},unit));
        xlim(ax,[0 cfg.durationSec/60]);
        values=[state(:,idx);reference(idx)]*factor;
        span=max(max(values)-min(values),.05); ylim(ax,[min(values)-.07*span,max(values)+.07*span]);
        if axisIndex==1
            lg=legend(ax,[l1 l2],{'Conditional control estimate','Injected reference (display only)'}, ...
                'Orientation','horizontal','Box','off','FontSize',10);
            lg.Layout.Tile='south';
        end
        if axisIndex==3, xlabel(ax,'Measurement availability time (min)'); end
    end
    files(2*quantity-1:2*quantity)=savePair(fig,[stem '_' name],cfg.plot.dpi);
    clear guard
end
end

function style(ax)
grid(ax,'on'); ax.GridAlpha=.12; ax.Box='off'; ax.FontName='Arial';
ax.FontSize=11; ax.TickDir='out';
end

function files=savePair(fig,stem,dpi)
exportgraphics(fig,[stem '.png'],'Resolution',dpi);
savefig(fig,[stem '.fig']);
files={[stem '.png'];[stem '.fig']};
end
