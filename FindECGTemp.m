function tTemp = FindECGTemp(sig, fs, PLOT)
warning('off', 'signal:findpeaks:largeMinPeakHeight');

N = 5;
PR = 0.25;
% PR = ceil(PR*fs)/fs;
QRS = 0.15;
% QRS = ceil(QRS*fs)/fs;
QT = 0.4;
% QT = ceil(QT*fs)/fs;

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
iMatchSt = locs{idxm-1} - lECG+1;
iMatchSt = iMatchSt(iMatchSt>0);
iTemp = (1:lECG);
iMatches = repmat(iMatchSt, 1, lECG) + repmat(iTemp, length(iMatchSt),1) - 1;
iMatches = iMatches(~logical(sum(iMatches > length(sigSearch),2)),:);
matches = sigSearch(iMatches);
idx2avg = find(size(matches) ~= length(tempStart));
tempAvg = mean(matches,idx2avg)';


%% find loc of QRS
[~, iM] = findpeaks(tempAvg, 'minpeakprominence', range(tempAvg)/6);
[~, im] = findpeaks(-tempAvg, 'minpeakprominence', range(tempAvg)/6);
i0=find(((tempAvg >= 0) & (circshift(tempAvg,-1) < 0)) | ((tempAvg <= 0) & (circshift(tempAvg,-1) > 0)));

pks = [];

% if max first
iM2m = iM(logical(cell2mat(arrayfun(@(x)(sum((im > x) & (im < x+QRS*fs/2))), iM, 'uniformoutput', 0))));
inextm = cell2mat(arrayfun(@(x)(min(im(im > x)-x) + x), iM2m, 'uniformoutput', 0));
if ~isempty(inextm)
    boolZeroCrossInside=cell2mat(arrayfun(@(x,y)(sum((i0 >= x)&(i0 <= y))), iM2m, inextm, 'uniformoutput', 0))==1;
else
    boolZeroCrossInside = iM2m;
end
pks = [pks; [iM2m(boolZeroCrossInside), inextm(boolZeroCrossInside)]];

% if min first
im2M = im(logical(cell2mat(arrayfun(@(x)(sum((iM > x) & (iM < x+QRS*fs/2))), im, 'uniformoutput', 0))));
inextM = cell2mat(arrayfun(@(x)(min(iM(iM > x)-x) + x), im2M, 'uniformoutput', 0));
if ~isempty(inextM)
    boolZeroCrossInside=cell2mat(arrayfun(@(x,y)(sum((i0 >= x)&(i0 <= y))), im2M, inextM, 'uniformoutput', 0))==1;
else
    boolZeroCrossInside = im2M;
end
pks = [pks; [im2M(boolZeroCrossInside), inextM(boolZeroCrossInside)]];

[~, iMaxProm] = max(abs(tempAvg(pks(:,2))-tempAvg(pks(:,1))));

iQRSstart = pks(iMaxProm,1);

% recenter the average
iMatchSt = locs{idxm-1} - lECG+1 + iQRSstart - floor(PR*fs);
iMatchSt = iMatchSt(iMatchSt>0);
iTemp = (1:lECG);
iMatches = repmat(iMatchSt, 1, lECG) + repmat(iTemp, length(iMatchSt),1) - 1;
iMatches = iMatches(~logical(sum(iMatches > length(sigSearch),2)),:);
matches = sigSearch(iMatches);
tempRecent = mean(matches,1)';


%% Find a epoch that best matches the template for output
mFilt = filter(tempRecent(end:-1:1), 1, sig);
mFiltNorm = mFilt/lECG./sqrt(filter(ones(1,lECG),1,sig.^2)/lECG * sum(tempRecent.^2)/lECG);

[~, iMax] = max(mFiltNorm);

iStart = iMax - lECG+1;
iTemp = iStart + [0, length(tempRecent)-1];
tTemp = iTemp / fs;

%%

if PLOT
    figure;
    hold on;
    plot((1:length(iTemp(1):iTemp(2)))/fs, tempRecent, 'k');
    plot((1:length(iTemp(1):iTemp(2)))/fs, sig(iTemp(1):iTemp(2)));
    xlabel('time (s)');
    ylabel('LFP (\muV)');
    legend('estimated averaged template', 'output epoch');
end
warning('on', 'signal:findpeaks:largeMinPeakHeight');
