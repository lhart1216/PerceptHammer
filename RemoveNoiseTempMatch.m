function [sigClean, artRem, artLog, template] = RemoveNoiseTempMatch(sigOrig, fs, template, fEst, tInc, tIgn, search, scaled, pl)
%% Developed by Lauren Hammer
% Last update: 10/5/21
% Takes a signal and removes a repetitive artifact using a modified Woody's
% adaptive filter. Allows for a forced search if desired
% INPUTS:
% sigOrig = signal to clean (expects column vector)
% fs = sampling rate (Hz)
% template = vector with waveform to be seed for template matching
%            (seconds)
% fEst = estimated occurence rate of artifact (Hz)
% tInc = vector with the start / stop of when the artifact is present in the
%        signal (seconds). Can input [0 0] if want to just use whole
%        signal
% tIgn = vector with start/stop of time frames to ignore in the signals
%        (such as if there is motion artifact to ignore). Units=seconds
% search = whether to include a forced search to find missed templates
% scaled = boolean whether want to scale templates before subtraction
% pl = boolean whether want to plot the matching
% OUTPUTS:
% sigClean = signal with artifact subtracted
% artRem = the artifact vector that was subtracted from the signal
% artLog = cell array that includes the time points / artifact that was
%          subtracted
% template = averaged Woody's filter template that was averaged and
%            subtracted

%% pulls out excerpt of signal that has the artifact, as defined in tInc
if sum(tInc(1,:))==0
    sig = sigOrig;
else
    sig = zeros(size(sigOrig));
    for j = 1:size(tInc,1)
        sig(round(tInc(j,1)*fs):round(tInc(j,2)*fs)) = sigOrig(round(tInc(j,1)*fs):round(tInc(j,2)*fs));
    end
end

%% padding signal
% adds padding to the beginning and oend of the signal to provide buffer 
% for matches of partial template 
pad = length(template);
sig = [zeros(pad,1); sig; zeros(pad,1)];

%% iteratively updates template until no new identified match locations
oldLocs = 1;
locs = 0;
while ~isempty(setdiff(oldLocs, locs))
    oldLocs = locs;
    locs = MatchedFilter(sig, fs, template, fEst);
    iTemp = (1:(length(template)));
    iMatches = repmat(locs, 1, length(iTemp)) + repmat(iTemp, length(locs),1) - 1;
    matches = sig(iMatches);
    boolIgnTemp = [];
    if sum(tIgn(1,:))==0
        for iIgn = 1:size(tIgn,1)
            boolIgnTemp(:,iIgn) = prod((((iMatches/fs)> tIgn(iIgn,1)) .* ((iMatches/fs)<tIgn(iIgn,2))),2);
        end
        boolIgn = sum(boolIgnTemp,2);
    else
        boolIgn = zeros(size(matches,1),1);
    end
    template = mean(matches(~boolIgn,:),1)';
end

%% template matching with forced search
if search
    locs = ForcedSearch(sig, fs, template, fEst, locs);
end

%% subtracts noise from signal
locs = locs - pad;
locs = locs(locs > - length(template));

sig = sig((pad+1):(end-pad));
artRem(:,1) = zeros(1,length(sig),1);

for j = 1:length(locs)
    
    iFullTemp=iTemp+locs(j)-1;
    iInc = (iFullTemp>0) & (iFullTemp<=length(sig));
    c = 1;
    if scaled
        c=regress(sig(iFullTemp(iInc)), template(iInc));
    end
    artRem(iFullTemp(iInc)) = artRem(iFullTemp(iInc)) + template(iInc)*c;
    artLog{j,1}=[iFullTemp(iInc)', template(iInc)];
end
sigClean = sigOrig-artRem;

%% plotting
if pl
    figure;
    hold on;
    pO = PlotTempMatch(sigOrig, fs, template, locs, scaled);
    ax = gca;
    set(gca, 'xlim', [0 20]);
    pN = plot((1:length(sigOrig))/fs, sigOrig-artRem-max(sigOrig)+min(sigOrig), 'b');
    legend([pO, pN], 'original signal', 'noise removed');
    set(findall(gcf,'-property','FontSize'),'FontSize',16)
    pan xon;
    axes('position', [.7 .15 .2 .2]);
    plot(template, 'k', 'linewidth', 2);
    box on;
    set(gca, 'xlim', [0 length(template)], 'xtick',[], 'ytick', [], 'xticklabel',[], 'yticklabel',[]);
end
end