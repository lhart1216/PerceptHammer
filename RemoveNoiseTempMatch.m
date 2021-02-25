function [sigClean, artRem, artLog] = RemoveNoiseTempMatch(sigOrig, fs, tSeed, fEst, tInc, search, scaled, pl)
% Takes a signal and removes uses template matching to remove noise. Noise
% needs to occur regularly. Plots a graph of the template matches which are
% numbered. Numbered template matches are also output so that user can
% reject template matches and recreate the noise subtraction if desired.
% INPUTS:
% sigOrig = signal to clean (expects column vector)
% fs = sampling rate (Hz)
% tSeed = vector with the start / stop of an example of the noise to be
%         used as a seed for template matching (seconds)
% fEst = estimated rate of noise (Hz)
% tInc = vector with the start / stop of when the noise is present in the
%        signal (seconds). Can input [0 0] if want to just use whole
%        signal
% search = boolean whether want to use the fact that the noise is regular
%          to search in between long inter-event lengths
% scaled = boolean whether want to scale templates before subtraction
% pl = boolean whether want to plot the matching
% OUTPUTS:
% sigClean = signal with noise subtracted
% artRem = the artifact vector that was subtracted from the signal
% artLog = cell array that includes the time points / artifact that was
%          subtracted

%% pulls out excerpt of signal that has the noise, as defined in tInc
if sum(tInc(1,:))==0
    sig = sigOrig;
else
    sig = zeros(size(sigOrig));
    for j = 1:size(tInc,1)
        sig(round(tInc(j,1)*fs):round(tInc(j,2)*fs)) = sigOrig(round(tInc(j,1)*fs):round(tInc(j,2)*fs));
    end
end

%% establishing template and the signal
template = sig(round(tSeed(1)*fs): round(tSeed(2)*fs));
pad = length(template);
sig = [zeros(pad,1); sig; zeros(pad,1)];

%% goes through and finds matches based on template, updating template
for j = 1:5
    locs = MatchedFilter(sig, fs, template, fEst, 0);
    iTemp = (1:(length(template)));
    iMatches = repmat(locs, 1, length(iTemp)) + repmat(iTemp, length(locs),1) - 1;
    matches = sig(iMatches);
    template = mean(matches,1)';
end

%% collects final round of matches based on the updated template
locs = MatchedFilter(sig, fs, template, fEst, search);

%% subtracts noise from signal
locs = locs - pad;
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

%% if searching, look for additional off-regular frequency occurances
if search
    newLocs = MatchedFilter([zeros(pad,1); sig - artRem; zeros(pad,1)], fs, template, [], 0);
    newLocs = newLocs - pad;
    for j = 1:length(newLocs)
        
        iFullTemp=iTemp+newLocs(j)-1;
        iInc = (iFullTemp>0) & (iFullTemp<=length(sig));
        c = 1;
        if scaled
            c=regress(sig(iFullTemp(iInc)), template(iInc));
        end
        artRem(iFullTemp(iInc)) = artRem(iFullTemp(iInc)) + template(iInc)*c;
        artLog{end+1,1}=[iFullTemp(iInc)', template(iInc)*c];
    end
    
    [locs, idx] = sort([locs; newLocs]);
    artLog = artLog(idx);
end

%% plotting
if pl
    figure;
    hold on;
    pO = PlotTempMatch(sigOrig, fs, template, locs, scaled);
    set(gca, 'xlim', [0 20]);
    sigClean = sigOrig-artRem;
    pN = plot((1:length(sigOrig))/fs, sigOrig-artRem-max(sigOrig)+min(sigOrig), 'b');
    legend([pO, pN], 'original signal', 'noise removed');
    set(findall(gcf,'-property','FontSize'),'FontSize',16)
end
end