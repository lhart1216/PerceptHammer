function [pSig, pTemps] = PlotTempMatch(sig, fs, template, locs, scaled)
% Plots the template matches on top of the initial signal
% INPUT
% sig = signal (expects column vector)
% fs = sampling rate
% template = template that was matched
% locs = index where match is
% scaled = boolean for whether want to scale the matched template
% OUTPUT
% pSig = handle for the raw signal plot
% pTemps = array of handles for the template plots

iTemp = (1:(length(template)));

hold on;
pSig = plot((1:length(sig))/fs, sig, 'k');
col = get(gca,'colororder');
for j = 1:length(locs)
    iCol = mod(j-1, size(col,1))+1;
    iFullTemp=iTemp+locs(j)-1;
    iInc = (iFullTemp>0) & (iFullTemp <= length(sig));
    c = 1;
    if scaled
        c=regress(sig(iFullTemp(iInc)), template(iInc));
    end
    pTemps(j)=plot(iFullTemp(iInc)/fs, template(iInc), 'linewidth', 2, 'color',col(iCol,:) );
    text(locs(j)/fs, min(template) - 0.1*range(template) , num2str(j), 'color', col(iCol,:));
end
xlabel('time (s)');
ylabel('LFP (uV)');
end

