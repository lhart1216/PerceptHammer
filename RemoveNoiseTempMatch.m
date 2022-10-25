function [sigClean, artRem, artLog, template] = RemoveNoiseTempMatch(sigOrig, fs, tempSeed, fEst, tInc, tIgn, search, scaled, pl)
% ===================
% last edited 10/5/21 by Hammer
% ===================
% Takes a signal and removes a repetitive artifact using a modified Woody's
% adaptive filter. Allows for a forced search if desired.
% ===================
% Input Variables:
% sigOrig = signal to clean (expects column vector)
% fs = sampling rate (Hz)
% tempSeed = vector with waveform to be seed for template matching
%            (seconds)
% fEst = estimated occurence rate of artifact (Hz). Can be either a scalar
%        (what actual estimate is) or a vector that is a typical range
%        (e.g. for ECG, [60-100]/60)  
% tInc = vector with the start / stop of when the artifact is present in the
%        signal (seconds). Can input [0 0] if want to just use whole
%        signal 
% tIgn = vector with start/stop of time frames to ignore in the signals
%        (such as if there is motion artifact to ignore). Units=seconds
% search = whether to include a forced search to find missed templates
% scaled = boolean whether want to scale templates before subtraction
% pl = boolean whether want to plot the matching
% ===================
% Output Variables:
% sigClean = signal with artifact subtracted
% artRem = the artifact vector that was subtracted from the signal
% artLog = cell array that includes the time points / artifact that was
%          subtracted
% template = averaged Woody's filter template that was averaged and
%            subtracted
% ===================
% Internal Variables:
% boolIgn = boolean vector length of # of matches, on whether should ignore
%           a match from analysis based on whether its present within tIgn
% c = multiplicative scaling constant if you are subtracting scaled version
%     of template (scaled = 1)
% iFullTemp = indices relating to a full template match when planning to
%             subtract from the raw signal
% iInc = indices realting to a partial tempalte match (trimmed if the
%        template extends before / after the signal length
% iMatches = indices in sigPad where template matches are present (includes
%            both the initial index and the length of the template)
% matches = array of template matches waveforms in sigPad (organized by 
%           rows)
% iTemp = vector of indices from 1:length(template)
% locs = indices of template match locations
% oldLocs = last loop's iteration of template match location indices
% pad = size of padding with zeros at the beginning / end of the signal
% pC = handle for plot object for the cleaned signal
% pO = handle for plot object for the raw/original signal
% sigEx = excerpt of sigOrig based on tInc
% sigPad = sigEx padded with zeros in the beginning and end

%% pulls out excerpt of signal that has the artifact, as defined in tInc
if sum(tInc(1,:))==0
    sigEx = sigOrig;
else
    sigEx = zeros(size(sigOrig));
    for j = 1:size(tInc,1)
        sigEx(round(tInc(j,1)*fs):round(tInc(j,2)*fs)) = sigOrig(round(tInc(j,1)*fs):round(tInc(j,2)*fs));
    end
end

%% padding signal
% adds padding to the beginning and end of the signal to provide buffer 
% for matches of partial template 
pad = length(tempSeed);
sigPad = [zeros(pad,1); sigEx; zeros(pad,1)];

%% iteratively updates template until no new identified match locations
oldLocs = 1;
locs = 0;
template = tempSeed;
while ~isempty(setdiff(oldLocs, locs))
    oldLocs = locs;
    locs = MatchedFilter(sigPad, fs, template, fEst, 0.975);
    iTemp = (1:(length(template)));
    iMatches = repmat(locs, 1, length(iTemp)) + repmat(iTemp, length(locs),1) - 1;
    matches = sigPad(iMatches);
    
    % goes through and ignores matches within tIgn
    boolIgn = zeros(size(matches));
    for iIgn = 1:size(tIgn,1)
        boolIgn(:,iIgn) = prod((((iMatches/fs)> tIgn(iIgn,1)) .* ((iMatches/fs)<tIgn(iIgn,2))),2);
    end
    % updates template by averaging matches
    template = mean(matches(~sum(boolIgn,2),:),1)';
end

%% template matching with forced search
if search
    locs = ForcedSearch(sigPad, template, locs, round(fs/min(fEst)*.1));
end

%% subtracts artifact from signal
locs = locs - pad;
locs = locs(locs > - length(template));

artRem(:,1) = zeros(1,length(sigOrig),1);
for j = 1:length(locs)
    iFullTemp=iTemp+locs(j)-1;
    iInc = (iFullTemp>0) & (iFullTemp<=length(sigOrig));
    c = 1;
    if scaled
        c=regress(sigOrig(iFullTemp(iInc)), template(iInc));
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
    pC = plot((1:length(sigOrig))/fs, sigOrig-artRem-max(sigOrig)+min(sigOrig), 'b');
    legend([pO, pC], 'original signal', 'noise removed');
    set(findall(gcf,'-property','FontSize'),'FontSize',16)
    pan xon;
    axes('position', [.7 .15 .2 .2]);
    plot(template, 'k', 'linewidth', 2);
    box on;
    set(gca, 'xlim', [0 length(template)], 'xtick',[], 'ytick', [], 'xticklabel',[], 'yticklabel',[]);
end
end
