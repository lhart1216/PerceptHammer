function h = PlotSigAndStim(sig, tSig, stim, tStim, stimLab)
% COMMENTING NEEDS UPDATING
% works with outpu of MatchSigAndStim
% example input: PlotSigAndStim(sig, t_td, [stim.L, stim.R], t_fd, {'Left', 'Right'});


linestyle={'-','--', ':','-.',};
co = get(groot, 'defaultaxescolororder');

hold on;
set(gca, 'colororder', [0 0 0; 0 0 0]);

yyaxis right;
for i = 1:size(stim,2)
    plot(tStim, stim(:,i), 'color', co(2,:), 'linestyle', linestyle{i}, 'linewidth', 2);
end
set(gca, 'ylim', [-1 7]);
ylabel ('Stimulation (mA)');

yyaxis left;
plot(tSig, sig, 'color', co(1,:), 'linewidth', 1.5);
ylabel ('LFP (\muV)');
xlabel('time (s)');

l = [{'LFP'}, cellfun(@(x)([x ' Stim']), stimLab, 'uniformoutput', 0)];
legend(l{:}, 'location', 'northoutside', 'orientation', 'horizontal');
set(findall(gcf,'-property','FontSize'),'FontSize',50)
set(gcf, 'units', 'normalized', 'position', [-1 0 1 1 ]);
 
box on;