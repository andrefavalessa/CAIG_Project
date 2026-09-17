function files = figrepro_plot(estimate,cfg,outputDir)
%FIGREPRO_PLOT Unsmooth causal histories; physical reference only for display.
isSway=strcmp(cfg.caseName,'triaxial_sway');
if isSway, prefix='figure8_triaxial_sway'; titleText='Triaxial sway | level 2';
else, prefix='figure6_constant_speed'; titleText='Constant speed | weak excitation'; end
colors=[.00 .36 .59;.80 .28 .13;.13 .53 .36];
axisNames={'x','y','z'};
t=[0;estimate.availableSec]/60;
state=[estimate.initialState.';estimate.state];
truth=[cfg.simulation.misalignmentRad;cfg.simulation.biasFRadPerSec.'];
files=cell(4,1);
for quantity=1:2
    fig=figure('Visible',cfg.plot.visible,'Color','w','Position',[80 50 1120 790]);
    figureGuard=onCleanup(@() close(fig));
    tiles=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
    if quantity==1
        indices=1:3; factor=180/pi; unit='deg'; name='misalignment'; label='Misalignment';
    else
        indices=4:6; factor=180/pi*3600; unit='deg/h'; name='fog_bias'; label='FOG bias';
    end
    title(tiles,[titleText ' | ' label],'FontName','Arial','FontSize',19,'FontWeight','bold');
    subtitle(tiles,sprintf(['Physical phase -> P_1, P_2 -> reconstructed rate | ' ...
        'T = %.1f ms, ideal CAIG readout | sensitivity rank %d/6'], ...
        1e3*cfg.caig.Tsec,estimate.sensitivityRank), ...
        'FontSize',11,'Interpreter','tex');
    for axisIndex=1:3
        ax=nexttile(tiles); idx=indices(axisIndex);
        line1=plot(ax,t,state(:,idx)*factor,'Color',colors(axisIndex,:),'LineWidth',1.35);
        hold(ax,'on');
        line2=yline(ax,truth(idx)*factor,'--','Color',[.26 .28 .32],'LineWidth',1.1);
        grid(ax,'on'); ax.GridAlpha=.12; ax.Box='off';
        ax.FontName='Arial'; ax.FontSize=12; ax.TickDir='out';
        ylabel(ax,sprintf('%s_%s (%s)',label,axisNames{axisIndex},unit),'Interpreter','none');
        xlim(ax,[0 cfg.durationSec/60]);
        if quantity==1
            ylim(ax,[min(-.15,min(state(:,idx)*factor)-.15),max(truth(idx)*factor+.2,max(state(:,idx)*factor)+.15)]);
        else
            limits=[min(state(:,idx)*factor),max(max(state(:,idx)*factor),truth(idx)*factor)];
            padding=.10*max(diff(limits),.05);
            ylim(ax,limits+[-padding padding]);
        end
        if axisIndex==1
            sharedLegend=legend(ax,[line1 line2],{'Causal estimate','Injected reference (display only)'}, ...
                'Orientation','horizontal','Box','off','FontSize',10);
            sharedLegend.Layout.Tile='south';
        end
        if axisIndex==3, xlabel(ax,'Measurement availability time (min)'); end
    end
    stem=fullfile(outputDir,[prefix '_' name]);
    exportgraphics(fig,[stem '.png'],'Resolution',cfg.plot.dpi);
    savefig(fig,[stem '.fig']);
    files(2*quantity-1:2*quantity)={[stem '.png'];[stem '.fig']};
    clear figureGuard
end
end
