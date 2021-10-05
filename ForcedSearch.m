function [locs] = ForcedSearch(sig, fs, template, fEst, search)
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

% find buffer amts
ibuffchange = find(diff(sig~=0)~=0);
frontBuff0 = ibuffchange(1);
endBuff0 = length(sig)-(ibuffchange(end));


mFilt = filter(template(end:-1:1), 1, sig);
% mFilt = mFilt/length(template)./sqrt(filter(ones(size(template)),1,sig.^2)/length(template) * sum(template.^2)/length(template));

buff =  round(fs/min(fEst)*.1);

if length(fEst) == 1
    tMin=1/fEst/2;
else
    tMin = 0.9/max(fEst);
end
[b,ib] = sort(abs(mFilt), 'descend');
[~, locs] = findpeaks(mFilt, 'minpeakDistance', tMin*fs, 'MinPeakHeight', b(round(length(ib)*.025)));

% if trying to search between long inter-match times to find additional matches
if search
    d = diff(locs);
    Nfront = floor(((locs(1)-frontBuff0)/mode(d)-1));
        Nfront = floor(((locs(1)-frontBuff0)/mode(d)));

    locsAddend = locs;
    if  Nfront > 0
        locsAddend = [locs(1)-round((Nfront+1.25)*mode(d)); locsAddend];
    end
    Nend = floor((length(sig) - endBuff0-locs(end))/mode(d));
    Nend = floor((length(sig) - endBuff0-locs(end))/mode(d)+1);

    if Nend > 0
        locsAddend = [locsAddend; locs(end)+round((Nend+1.25)*mode(d))];
    end
    
    dAddend = diff(locsAddend);
    iPoss = find(dAddend > 1.5 * mode(d));
    newLocs=[];
    
    % goes through possible areas where missing a match
    for i = 1:length(iPoss)
        % finds the expected number of additional matches, and searches
        % for this number of matches and +/- 1 matches in the interval
        newLocsTemp = [];
        delt = mode(d);
        plotted_newLocsTemp = zeros(size(sig));
        % finding the Nvar-1 number of matches
        estLoc = locsAddend(iPoss(i))+ delt;
        
        while estLoc < (locsAddend(iPoss(i)+1) - length(template)*3/4)
            mFiltEx = mFilt;
            mFiltEx(1:(estLoc-buff)) = 0;
            mFiltEx((estLoc+buff):end) = 0;
            [~,idx] = max(mFiltEx);
            if ((1+idx-length(template)) > 0) && (idx <= length(sig))
                newLocsTemp(end+1,:) = idx;
                plotted_newLocsTemp((1:length(template))+idx-length(template)) = template;
                estLoc = newLocsTemp(end)+delt;
            else
                estLoc = estLoc+delt;
            end

        end
        % % % % %
% % % % %         N = round((locsAddend(iPoss(i)+1)-locsAddend(iPoss(i)))/mode(d));        
% % % % %         newLocsTemp = [];
% % % % %         delt = round((locsAddend(iPoss(i)+1)-locsAddend(iPoss(i)))/N);
% % % % %         plotted_newLocsTemp = zeros(size(sig));
% % % % %         % finding the Nvar-1 number of matches
% % % % %         for j = 1:(N-1)
% % % % %             if j == 1
% % % % %                 estLoc = locsAddend(iPoss(i))+ delt;
% % % % %             else
% % % % %                 estLoc = newLocsTemp(end)+delt;
% % % % %             end
% % % % %             mFiltEx = mFilt;
% % % % %             mFiltEx(1:(estLoc-buff)) = 0;
% % % % %             mFiltEx((estLoc+buff):end) = 0;
% % % % %    
% % % % %             [~,idx] = max(mFiltEx);
% % % % %             newLocsTemp(end+1,:) = idx;
% % % % %             plotted_newLocsTemp((1:length(template))+idx-length(template)) = template;
% % % % %             
% % % % %             
% % % % %                 
% % % % %         end
        newLocs = [newLocs; newLocsTemp];
    end
    
    locs = sort([locs; newLocs]);
    
%     
%     % checks front and end of sig and looks for partial matches where
%     % would expect
%     
%     iEnd = locs(1) - mode(d) + buff/4;
%     sizeBeginSig =sum(sig(1:iEnd)~=0);
%     if sizeBeginSig / length(template) > .33
%         tempEnd = template((length(template)-sizeBeginSig+1):length(template));
%         iStart = iEnd - length(tempEnd) - buff/2 + 1;
%         excerpt = zeros(size(sig));
%         excerpt(iStart:iEnd) = sig(iStart:iEnd)-mean(sig(iStart:iEnd));
%         mFilt = filter(tempEnd(end:-1:1) - mean(tempEnd), 1, excerpt);
%         [M,idx] = max(mFilt);
%         locs = sort([locs; idx]);
%         
%     end
%     
%     iStart = locs(end) + mode(d) -length(template)+1 - buff/4;
%     sizeEndSig = sum(sig(iStart:end)~=0);
%     if sizeEndSig / length(template) > .33
%         tempBeg = template(1:(sizeEndSig+1));
%         iEnd = iStart + length(tempBeg) + buff/2 - 1;
%         excerpt = zeros(size(sig));
%         excerpt(iStart:iEnd) = sig(iStart:iEnd)-mean(sig(iStart:iEnd));
%         mFilt = filter(tempBeg(end:-1:1) - mean(tempBeg), 1, excerpt);
%         [M,idx] = max(mFilt);
%         locs = sort([locs; idx+length(template)-length(tempBeg)]);
%     end
    
end

locs = locs - length(template)+1;
warning('on', 'signal:findpeaks:largeMinPeakHeight');
end