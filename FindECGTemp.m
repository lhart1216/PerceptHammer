function [tTemp, tempRecent]= FindECGTemp(sig, fs, intervals, PLOT)
warning('off', 'signal:findpeaks:largeMinPeakHeight');
FLAGnomatch = 0;
N = 5;
% PR = 0.22;
% % PR = ceil(PR*fs)/fs;
% QRS = 0.16; 
% % QRS = ceil(QRS*fs)/fs;
% QT = 0.38;


PR = intervals(1);
QRS = intervals(2);
QT = intervals(3);

tECG = PR + QRS + QT;
lECG = floor(tECG*fs);

fEst = [50 110]/60;
tMin = 0.9/max(fEst);

sigTemp = sig(1:(N*fs));
sigSearch = sig((N*fs+1):end);

avgPk = [];
for offset = 0:(length(sigTemp)-fs*tECG)
    temp(offset+1,:) = sigTemp((1:floor(tECG*fs))+offset);
    mFilt = filter(temp(offset+1,end:-1:1), 1, sigSearch);
    mFiltNorm = mFilt/lECG./sqrt(filter(ones(1,lECG),1,sigSearch.^2)/lECG * sum(temp(offset+1,:).^2)/lECG);
    [pk{offset+1}, locs{offset+1}] = findpeaks(mFiltNorm, 'minpeakDistance', tMin*fs, 'MinPeakHeight', 0.4);
    %     if length(locs{offset+1}) ==1
    %         pk{offset+1} = [];
    %         locs{offset+1} = [];
    %     end
    avgPk(offset+1) = mean(pk{offset+1});
end
[m,idxm] = max(avgPk);
tempStart = sigTemp([1:(tECG*fs)]+idxm-1);
iMatchSt = locs{idxm} - lECG+1;
iMatchSt = iMatchSt(iMatchSt>0);
iTemp = (1:lECG);

if ~isempty(iMatchSt)
    
    iMatches = (repmat(iMatchSt, 1, lECG) + repmat(iTemp, length(iMatchSt),1) - 1)';
    iMatches = iMatches(~logical(sum(iMatches > length(sigSearch),2)),:);
    matches = sigSearch(iMatches);
    idx2avg = find(size(matches) ~= length(tempStart));
    pre = iMatches-floor(lECG/4);
    pre = pre(pre(:,1)>0,:);
    post = iMatches+floor(lECG/4);
    post = post(post(:,end)<length(sigSearch),:);

    if size(matches,2) >1
        tempAvg = mean(matches,idx2avg);
    else
        tempAvg = matches;
    end
    if size(pre,2)>1
        tempPre = mean(sigSearch(pre),idx2avg);
    else
        tempPre = sigSearch(pre);
    end
    if size(post,2)>1
        tempPost = mean(sigSearch(post),idx2avg);
    else
        tempPost = sigSearch(post);
    end
    
    
    %% find loc of QRS
    
    iQRS = [FindQRS(tempPre, QRS, fs), FindQRS(tempAvg, QRS, fs), FindQRS(tempPost, QRS, fs)];
    [~,idx] = min(abs(iQRS-PR/(PR+QRS+QT)*lECG));
    iQRSstart = iQRS(idx);
    offsets = [-floor(lECG/4), 0, floor(lECG/4)];
    
    % recenter the average
    iMatchSt = locs{idxm} + offsets(idx) - lECG+1 + iQRSstart - floor(PR*fs);

    iMatchSt = iMatchSt(iMatchSt>0);
    iTemp = (1:lECG);
    iMatches = repmat(iMatchSt, 1, lECG) + repmat(iTemp, length(iMatchSt),1) - 1;
    iMatches = iMatches(~logical(sum(iMatches > length(sigSearch),2)),:);
    matches = sigSearch(iMatches);
    if size(matches,2) >1
        tempRecent = mean(matches,1)';
    else
        tempRecent = matches;
    end
    
    %% Find a epoch that best matches the template for output
    mFilt = filter(tempRecent(end:-1:1), 1, sig);
    mFiltNorm = mFilt/lECG./sqrt(filter(ones(1,lECG),1,sig.^2)/lECG * sum(tempRecent.^2)/lECG);
    
    [~, iMax] = max(mFiltNorm);
    
    iStart = iMax - lECG+1;
    iTemp = iStart + [0, length(tempRecent)-1];
    tTemp = iTemp / fs;
    
else
    tempRecent = zeros(size(tempStart));
    tTemp = [NaN, NaN];
    FLAGnomatch = 1;
end




if PLOT
    hold on;
    plot((1:length(tempRecent))/fs, tempRecent, 'k');
    if ~FLAGnomatch
        plot((1:length(iTemp(1):iTemp(2)))/fs, sig(iTemp(1):iTemp(2)));
    end
    xlabel('time (s)');
    ylabel('LFP (\muV)');
    legend('estimated averaged template', 'output epoch');
end
warning('on', 'signal:findpeaks:largeMinPeakHeight');

end
