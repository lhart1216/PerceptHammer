function [locs] = MatchedFilter(sig, fs, template, fEst, search)
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
% locs = index numbers of the

warning('off', 'signal:findpeaks:largeMinPeakHeight');
    T = 0.75; % R2 threshold for being a match (not search matches)

mFilt = filter(template(end:-1:1), 1, sig);
mFiltNorm = mFilt/length(template)./sqrt(filter(ones(size(template)),1,sig.^2)/length(template) * sum(template.^2)/length(template));


if ~isempty(fEst) % if want to use an expecte frequency to cap
    buff =  round(fs/fEst*.2);
    [~, locs] = findpeaks(mFiltNorm, 'minpeakDistance', 1/fEst/2*fs, 'MinPeakHeight', T);
    
    % if trying to search between long inter-match times to find additional matches
    if search
        d = diff(locs);
        iPoss = find(d > 1.5 * median(d));
        newLocs=[];
        
        % goes through possible areas where missing a match
        for i = 1:length(iPoss)
            % finds the expected number of additional matches, and searches
            % for this number of matches and +/- 1 matches in the interval
            N = round((locs(iPoss(i)+1)-locs(iPoss(i)))/median(d));
            Nvar = N+(-1:1);
            for iNvar = 1:length(Nvar)
                newLocsTemp{iNvar} = [];
                delt = round((locs(iPoss(i)+1)-locs(iPoss(i)))/Nvar(iNvar));
                plotted_newLocsTemp(iNvar,:) = zeros(size(sig));
                % finding the Nvar-1 number of matches
                for j = 1:(Nvar(iNvar)-1)
                    iEnd = locs(iPoss(i))+ delt*j + buff;
                    iStart = iEnd - length(template) - 2*buff + 1;
                    excerpt = zeros(size(sig));
                    excerpt(iStart:iEnd) = sig(iStart:iEnd)-mean(sig(iStart:iEnd));
                    mFilt = filter(template(end:-1:1) - mean(template), 1, excerpt);
                    mFiltNormTemp = mFilt/length(template)./sqrt(filter(ones(size(template)),1,excerpt.^2)/length(template) * sum(template.^2)/length(template));
                    mFiltNorm = zeros(size(mFilt));
                    mFiltNorm((iStart+length(template)-1):iEnd) = mFiltNormTemp((iStart+length(template)-1):iEnd);
                    [~,idx] = max(mFiltNorm);
                    newLocsTemp{iNvar}(end+1,:) = idx;
                    plotted_newLocsTemp(iNvar,(1:length(template))+idx-length(template)) = template;
                end
            end
            % forces there to choose at least one template
            boolNotEmpty = cell2mat(cellfun(@(x)(~isempty(x)), newLocsTemp, 'uniformoutput', 0));
            plotted_newLocsTemp = plotted_newLocsTemp(boolNotEmpty,:);
            newLocsTemp = newLocsTemp(boolNotEmpty);
            [~,iBestMatch] = min(sum(abs(plotted_newLocsTemp - repmat(sig',length(newLocsTemp),1)),2));
            newLocs = [newLocs; newLocsTemp{iBestMatch}];
        end
        locs = sort([locs; newLocs]);
        
        
        % checks front and end of sig and looks for partial matches where
        % would expect
        tempEnd = template((ceil(length(template)/2)):length(template));
        iEnd = locs(1) - median(d) + buff;
        iStart = iEnd - length(tempEnd) - 2*buff + 1;
        if iStart > 0 && sum(sig(iStart:iEnd)==0)/(iEnd-iStart+1) < .75
            excerpt = zeros(size(sig));
            excerpt(iStart:iEnd) = sig(iStart:iEnd)-mean(sig(iStart:iEnd));
            mFilt = filter(tempEnd(end:-1:1) - mean(tempEnd), 1, excerpt);
            mFiltNorm = mFilt/length(tempEnd)./sqrt(filter(ones(size(tempEnd)),1,excerpt.^2)/length(tempEnd) * sum(tempEnd.^2)/length(tempEnd));
            mFiltNorm(isnan(mFiltNorm))=0;
            [~,idx] = max(mFiltNorm);
            locs = sort([locs; idx]);
        end        
        
        % finds last, loc, searches for the first half of template around
        tempBeg = template(1:int8(floor(length(template)/2)));
        iEnd = locs(end) - median(d) + buff;
        iStart = iEnd - length(tempBeg) - 2*buff + 1;
        if iEnd <= length(sig) && sum(sig(iStart:iEnd)==0)/(iEnd-iStart+1) < .75
            excerpt = zeros(size(sig));
            excerpt(iStart:iEnd) = sig(iStart:iEnd)-mean(sig(iStart:iEnd));
            mFilt = filter(tempBeg(end:-1:1) - mean(tempBeg), 1, excerpt);
            mFiltNorm = mFilt/length(tempBeg)./sqrt(filter(ones(size(tempBeg)),1,excerpt.^2)/length(tempBeg) * sum(tempBeg.^2)/length(tempBeg));
            mFiltNorm(isnan(mFiltNorm))=0;
            [~,idx] = max(mFiltNorm);
            locs = sort([locs; idx + length(template) - length(tempBeg)]);
        end
      
    end
else % if don't want limits on how often can have match
    [~, locs] = findpeaks(mFiltNorm, 'minpeakDistance', length(template), 'MinPeakHeight', T);
end
locs = locs - length(template)+1;
warning('on', 'signal:findpeaks:largeMinPeakHeight');
end