function [locs] = MatchedFilter(sig, fs, template, fEst, P)
% ===================
% last edited 10/15/21 by Hammer
% ===================
% Takes a signal and finds locaiton of artifact using a matched filter
% ===================
% Input Variables:
% sig = signal to clean (expects column vector)
% fs = sampling rate (Hz)
% template = vector with waveform for matching 
% fEst = estimated occurence rate of artifact (Hz). Can be either a scalar
%        (what actual estimate is) or a vector that is a typical range
%        (e.g. for ECG, 60-100) 
% P = percentile for thresholding matches (97.5th percentile works well,
%     but can make more / less sensitive by adjusting). 
% ===================
% Output Variables:
% locs = indices of where matches are (beginning of template)
% ===================
% Internal Variables:
% b = sorted values of mFilt (used to find percentile)
% ib = indices of sorted values of mFilt (used to find percentile)
% locsEnd = locations indexed at the end of the template match (default
%           output of the matched filter)
% mFilt = matched filter output
% tMin = minimum interval between matches depending on fEst (sec) 

warning('off', 'signal:findpeaks:largeMinPeakHeight');

% if P is entered as percent instead of fraction, switches to fraction
if P>1
    P = P/100;
end

% running matched filter
mFilt = filter(template(end:-1:1), 1, sig);

% find minimum time interval between matches depending on fEst
if length(fEst) == 1
    tMin=1/fEst/2;
else
    tMin = 0.9/max(fEst);
end

% finds matches that are at least tMin apart and exceed a threshold of
% 97.5th percentile
[b,ib] = sort(abs(mFilt), 'descend');
[~, locsEnd] = findpeaks(mFilt, 'minpeakDistance', tMin*fs, 'MinPeakHeight', b(round(length(ib)*(1-P))));

% matched filter output is 
locs = locsEnd - length(template)+1;
warning('on', 'signal:findpeaks:largeMinPeakHeight');
end