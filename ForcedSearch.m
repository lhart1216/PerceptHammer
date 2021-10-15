function [locs] = ForcedSearch(sig, template, locs, W)
% ===================
% last edited 10/15/21 by Hammer
% ===================
% Takes template matches and finds inter-match intervals that are longer
% than expected, and then does a forced search for templates
% ===================
% Input Variables:
% sig = signal to clean (expects column vector), can handle a signal padded
%       with zeros at the beginning and end
% template = vector with waveform for matching 
% locs = indices of where matches are (beginning of template)
% W = search width -- number of indices above (or below) the estimated
%     location of an expected match location to search for greatest 
%     template match (total width searched is 2*W). A value of 10% of the
%     estimated minimum inter-match occurence works well)
% ===================
% Output Variables:
% locs = indices of where matches are (beginning of template)
% ===================
% Internal Variables:
% d = vector of inter-match differences in locs
% dAddend = vector of inter-match differences in locsAddend
% endPad = number of indices in end signal padding
% estLoc = estimation of new match at a search location
% frontPad = number of indices in front signal padding
% idx = possible location of missed match (assuming the match is within the
%       signal length)
% iPadChange = location of where padding-signal-padding transitions
% iPoss = indices within locsAddend where there is an abnormally long
%         interval after this loc, suggesting a missed match
% locsAddend = indices of template matches, indexed to the last index of 
%              the match, with added indices in the front and end to help
%              search the beignning / end of the signal for missed matches
% locsEnd = indices of template matches, indexed to the last index of the
%           match
% mFilt = matched filter for the template and the entire signal, eventually
%         nulled except for the search area for a certain missed match
% Nend = number of potential missed matches at the end of the signal
% Nfront = number of potential missed matches at the beginning of the
%          signal
% newLocs = growing of new match locations found by forced search
%           (cumulative for all search locations)
% newLocsTemp = growing list of new match locations found by forced search
%               at a single search location


warning('off', 'signal:findpeaks:largeMinPeakHeight');

% find padding amts that were added to the beginning / end of the signal
iPadChange = find(diff(sig~=0)~=0);
frontPad = iPadChange(1);
endPad = length(sig)-(iPadChange(end));

% reset locs to be indexed to the end of the template match instead of the
% beginning
locsEnd = locs + length(template)-1;

% estimates the number of matches at the beginning of the signal that were
% missed
d = diff(locsEnd);
Nfront = floor(((locsEnd(1)-frontPad)/mode(d)));
locsAddend = locsEnd;
if  Nfront > 0
    locsAddend = [locsEnd(1)-round((Nfront+1.25)*mode(d)); locsAddend];
end

% estimates the number of matches at the end of the signal that were
% missed
Nend = floor((length(sig) - endPad-locsEnd(end))/mode(d)+1);
if Nend > 0
    locsAddend = [locsAddend; locsEnd(end)+round((Nend+1.25)*mode(d))];
end

% goes through possible areas where missing a match
dAddend = diff(locsAddend);
iPoss = find(dAddend > 1.5 * mode(d));
newLocs=[];
for i = 1:length(iPoss)
    newLocsTemp = [];
    estLoc = locsAddend(iPoss(i))+ mode(d);
    while estLoc < (locsAddend(iPoss(i)+1) - length(template)*3/4)
        % goes through and searches for matches at locaitons of missed
        % matches. once it finds a potential match, search for the next
        % potential missed match at that search location is based off the
        % most recently identified match
        
        % finds the matched filter for the whole signal, makes everything
        % exept for the search area 0
        mFilt = filter(template(end:-1:1), 1, sig);
        mFilt(1:(estLoc-W)) = 0;
        mFilt((estLoc+W):end) = 0;
        
        % finds the best match locaiton within the search area
        [~,idx] = max(mFilt);
        if ((1+idx-length(template)) > 0) && (idx <= length(sig))
            newLocsTemp(end+1,:) = idx;
            estLoc = newLocsTemp(end)+mode(d);
        else
            estLoc = estLoc+mode(d);
        end
        
    end
    newLocs = [newLocs; newLocsTemp];
end

locsEnd = sort([locsEnd; newLocs]);

locs = locsEnd - length(template)+1;
warning('on', 'signal:findpeaks:largeMinPeakHeight');
end