
function [iQRS1st, iQRS2nd] = FindQRS (tempAvg, QRS, fs)


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
    
    if ~isempty(pks)
        [~, iMaxProm] = max(abs(tempAvg(pks(:,2))-tempAvg(pks(:,1))));
        iQRS1st = pks(iMaxProm,1);  
        iQRS2nd = pks(iMaxProm,2);  
    else
        iQRS1st = NaN;
        iQRS2nd = NaN;
    end



end