function [locs] = MatchedFilter(sig, fs, template, fEst)
%%% COMMENTING NEEDS UPDATING

% Takes a signal and used a matched filter to find locations where noise
% exists. Also has option if the noise occurs regularly, to identify
% segments of time where there are missing matches and searches for
% best-fit
% INPUTS:
% sig = signal (expects column vector)
% fs = sampling rate (Hz)
% template = the template of noise used to find the matches (expects column vector)
% fEst = estimated rate of noise (Hz) (helps set a threshold on how
%        frequently can find a match)
% search = boolean whether want to use the fact that the noise is regular
%          to search in between long inter-event lengths
% OUTPUTS:
% locs = index numbers of the matches

warning('off', 'signal:findpeaks:largeMinPeakHeight');

mFilt = filter(template(end:-1:1), 1, sig);

if length(fEst) == 1
    tMin=1/fEst/2;
else
    tMin = 0.9/max(fEst);
end
[b,ib] = sort(abs(mFilt), 'descend');
[~, locs] = findpeaks(mFilt, 'minpeakDistance', tMin*fs, 'MinPeakHeight', b(round(length(ib)*.025)));

locs = locs - length(template)+1;
warning('on', 'signal:findpeaks:largeMinPeakHeight');
end