function T = FindMatchedFiltThresh(sig, fs, template, fEst)

warning('off', 'signal:findpeaks:largeMinPeakHeight');

if length(fEst) == 1
    tMin=1/fEst/2;
else
    tMin = 0.9/max(fEst);
end

%%%%%%%set up error - auto thresholding requires estimated frequency
mFilt = filter(template(end:-1:1), 1, sig);
mFiltNorm = mFilt/length(template)./sqrt(filter(ones(size(template)),1,sig.^2)/length(template) * sum(template.^2)/length(template));

Ts = 0.4:0.05:0.75;
[~,locsT] = arrayfun(@(x)(findpeaks(mFiltNorm, 'minpeakDistance', tMin*fs, 'MinPeakHeight', x)), Ts, 'uniformoutput', 0);

Fmax = cell2mat(cellfun(@(x)(max(1./(diff(x)/fs))), locsT,'uniformoutput', 0));
iT = find(Fmax < 1/tMin, 1, 'first');
T = Ts(iT);
 