function  PlotTimeline(tlOb,thresh, stimLev, label)
% tlOb = timeline object
% thresh = array with [lower upper] thresholds. Can plot multiple
%          thresholds by adding multiple rows
% stimLev = row vector with [lower upper] stim levels
% label = text for the plot title

co = get(groot, 'defaultaxescolororder');
figure;
ts = datetime(cell2mat(arrayfun(@(x)(x.DateTime), tlOb, 'uniformoutput', 0)),'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss''Z') ;
LFP = cell2mat(arrayfun(@(x)(x.LFP), tlOb, 'uniformoutput', 0));
stim = cell2mat(arrayfun(@(x)(x.AmplitudeInMilliAmps), tlOb, 'uniformoutput', 0));
subplot(2,1,1)
hold on;
plot(ts, LFP, 'o',  'linewidth', 2);
for i = 1:size(thresh,1)
plot([ts(1), ts(end)], [thresh(i,1) thresh(i,1)], '-', 'color', co(i+1,:), 'linewidth', 2);
plot([ts(1), ts(end)], [thresh(i,2) thresh(i,2)], '-', 'color', co(i+1,:), 'linewidth', 2);
end
ylabel('Beta power');
x1 = min(ts);
x1.Hour = 08;
x1.Minute = 0;
x1.Second = 0;
x2 = x1 + caldays(1);

set(gca, 'xlim', [x1, x2]);
set(gca, 'xtick', x1:hours(4):x2);
set(gca, 'xticklabel', {' ', ' ', ' ', ' ', ' ', ' ', ' '})

title([label ' - ' num2str(x1.Month), '/' num2str(x1.Day)]);

subplot(2,1,2);
plot(ts, stim, 'o',  'linewidth', 2);
hold on; 
plot([ts(1), ts(end)], [stimLev(1), stimLev(1)], '-', 'color', co(2,:), 'linewidth', 2);
plot([ts(1), ts(end)], [stimLev(2), stimLev(2)], '-', 'color', co(2,:), 'linewidth', 2);
xlabel('Hour of day');

set(findall(gcf,'-property','FontSize'),'FontSize',25)

set(gca, 'xlim', [x1, x2]);
set(gca, 'xtick', x1:hours(4):x2);
set(gca, 'xticklabel', {'0', '4', '8', '12', '16', '20', '24'})

ylabel('Stim (mA)');

yl = get(gca, 'ylim');
set(gca, 'ylim', [0 yl(2)+0.5]);


set(gcf, 'units', 'normalized', 'position', [0 .5 .3 .5]);
