function [sig, t_td, fs_td, stim, t_fd, fs_fd, perSpec] = MatchSigAndStim(bsTD, bsFD, IGNORE_DROP_PACK)
% COMMENTING NEEDS UPDATING
% example input = MatchSigAndStim(data.BrainSenseTimeDomain(2), data.BrainSenseLfp(2));
% need to make sure for your input that the index for the TD matches up
% with the index for the FD

fs_td = bsTD.SampleRateInHz;
if ~isempty(bsFD)
    fs_fd = bsFD.SampleRateInHz;
else
    fs_fd = fs_td;
end

% get time domain
tdTicksStr = bsTD.TicksInMses;
tdTicks = cell2mat(cellfun(@(x)(str2num(x)),split(tdTicksStr, ','), 'uniformoutput', 0));
tdPackStr = bsTD.GlobalPacketSizes;
tdPack = cell2mat(cellfun(@(x)(str2num(x)),split(tdPackStr, ','), 'uniformoutput', 0));

D_td = mode(diff(tdTicks)); % ms
tdTicksAdjT = (tdTicks - tdTicks(1) + D_td)/1000;
tdTicksAdjI = tdTicksAdjT / D_td * 1000;
  
  
if IGNORE_DROP_PACK
    sig = bsTD.TimeDomainData;
    t_td = (1:length(sig))'/fs_td;
else
    % see if need to adjust if some time stamps had more than expected data
    % points per packet
    expPackSize = D_td*fs_td/1000;
    boolNotExpSize = ~(tdPack == floor(expPackSize)) & ~(tdPack == ceil(expPackSize));
    iStart = find(diff([0; boolNotExpSize])==1);
    iEnd = find(diff(boolNotExpSize)==-1);
    for i = 1:length(iStart)
        dat2distr = sum(tdPack(iStart(i):iEnd(i)));
        Npacks2distr = round(dat2distr/expPackSize);
        NextraTick = Npacks2distr- (iEnd(i)-iStart(i) + 1);

        % see if the abnormal packets all add up to a multiple of the expected
        % packet size, that could be redistributed. If not, then there are
        % fractions of packets missing.
        if expPackSize == floor(expPackSize) % expected packet is a whole number
            if (dat2distr / expPackSize) ~= floor(dat2distr / expPackSize)
                error('Unable to match because a fraction of a packet is missing');
            end
        else % expected packet is a fraction -- need to alternate
            if (dat2distr / expPackSize) ~= floor(dat2distr / expPackSize) & ...
                    ((dat2distr + floor(expPackSize))/ expPackSize) ~= floor((dat2distr + floor(expPackSize))/ expPackSize) & ...
                    ((dat2distr + ceil(expPackSize))/ expPackSize) ~= floor((dat2distr + ceil(expPackSize))/ expPackSize)
                error('Unable to match because a fraction of a packet is missing');
            end
        end
        if iStart(i) == 1% if in the beginning
            tdTicksAdjI = [1:NextraTick; (tdTicksAdjI+NextraTick)];
            boolNotExpSize = [zeros(NextraTick,1); boolNotExpSize];
            iStart((i+1):end) = iStart((i+1):end) + NextraTick;
            iEnd((i+1):end) = iEnd((i+1):end) + NextraTick;
            if expPackSize == floor(expPackSize) % expected packet is a whole number
                tdPack = [repmat(expPackSize, Npacks2distr,1);  tdPack((iEnd(i)+1):end)];
            else % expected packet is a fraction -- need to alternate
                tdPack = [repmat(floor(expPackSize), Npacks2distr,1);  tdPack((iEnd(i)+1):end)];
                if (tdPack(iEnd(i)+1) == floor(expPackSize)) & ((Npacks2distr/2)~=floor(Npacks2distr/2)) | ...
                        (tdPack(iEnd(i)+1) == ceil(expPackSize)) & ((Npacks2distr/2)==floor(Npacks2distr/2))
                    tdPack(1:2:Npacks2distr) = tdPack(1:2:Npacks2distr) + 1;
                else
                    tdPack(2:2:Npacks2distr) = tdPack(2:2:Npacks2distr) + 1;
                end
            end
        else % if in the middle
            
            tdTicksAdjI = [tdTicksAdjI(1:(iStart(i)-1)); tdTicksAdjI(iEnd(i)) + (-(Npacks2distr-1):0)'; tdTicksAdjI((iEnd(i)+1):end)];
            boolNotExpSize = [boolNotExpSize(1:(iStart(i)-1)); zeros(Npacks2distr,1); boolNotExpSize((iEnd(i)+1):end)];
            iStart((i+1):end) = iStart((i+1):end) + NextraTick;
            iEnd((i+1):end) = iEnd((i+1):end) + NextraTick;
            if expPackSize == floor(expPackSize) % expected packet is a whole number
                tdPack = [tdPack(1:(iStart(i)-1)); repmat(expPackSize,Npacks2distr+1,1); tdPack((iEnd(i)+1):end)];
            else % expected packet is a fraction -- need to alternate
                addIn = repmat(floor(expPackSize),Npacks2distr,1);
                if (tdPack(iEnd(i)+1) == floor(expPackSize)) & ((Npacks2distr/2)~=floor(Npacks2distr/2)) | ...
                        (tdPack(iEnd(i)+1) == ceil(expPackSize)) & ((Npacks2distr/2)==floor(Npacks2distr/2))
                    addIn(1:2:end) = addIn(1:2:end) + 1;
                else
                    addIn(2:2:end) = addIn(2:2:end) + 1;
                end
                tdPack = [tdPack(1:(iStart(i)-1)); addIn; tdPack((iEnd(i)+1):end)];

            end

        end
    end
   
    %% now goes through and lines up based on missing packets
    NpackExpect = max(tdTicksAdjI);
    
    if expPackSize == floor(expPackSize) || ((NpackExpect/2) == floor(NpackExpect/2))
        Nsamp = NpackExpect * expPackSize;
    else
        Nsamp = (NpackExpect-1) * expPackSize + tdPack(end);
        
    end
    T_td = Nsamp/fs_td;
    t_td = ((1/fs_td):(1/fs_td):T_td)';
    sig = NaN(size(t_td));
    

    if (expPackSize) == floor(expPackSize) % number of samples per packet expected to be an integer
        sizePackExpect = (expPackSize) * ones(NpackExpect,1);
    else % number of samples per packet is not an integer -- plan to alternate # of samples per packet
        sizePackExpect = floor(expPackSize) * ones(NpackExpect,1);
        if tdPack(1) > floor(expPackSize) % starts with larger
            sizePackExpect(1:2:end) = floor(expPackSize)+1;
        else % starts with smaller
            sizePackExpect(2:2:end) = floor(expPackSize)+1;
        end
    end
    cumPackSize = [cumsum(sizePackExpect); 0];
    cumPackSizeShift = circshift(cumPackSize,1);
    indPerExpPack = arrayfun(@(x,y)(y+1:x)', cumPackSize(1:end-1), cumPackSizeShift(1:end-1), 'uniformoutput', 0);
    
    iSampInc = cell2mat(indPerExpPack(int16(tdTicksAdjI)));
    sig(iSampInc) = bsTD.TimeDomainData;
    
end


if sum(abs(diff(diff(tdTicks))))
    warning('off', 'verbose');
    warning('off', 'backtrace');
    warning('Packet loss for time-domain');
    spacing = diff(tdTicks)/ mode(diff(tdTicks));
    iDrop = find(spacing ~= 1);
    Ndrop = spacing(iDrop)-1;
    %     arrayfun(@(x,y)(warning(['Dropped ' num2str(x) ' packet(s) between [' num2str(tdTicks(y)) ', ' num2str(tdTicks(y+1)) ']'])), Ndrop, iDrop, 'uniformoutput', 0)
    arrayfun(@(x,y)(warning(['Dropped ' num2str(x) ' packet(s) with timestamps between [' num2str(tdTicks(y)) ', ' num2str(tdTicks(y+1)-D_td) '] (inclusive) ' ...
        '-- between times ' num2str(tdTicksAdjT(y)) 's and ' num2str(tdTicksAdjT(y+1)-D_td/1000) 's'])), Ndrop, iDrop, 'uniformoutput', 0)
    warning('on', 'verbose');
    warning('on', 'backtrace');
end


% get frequency domain

if ~isempty(bsFD)
    fdTicks = cell2mat(arrayfun(@(x)(x.TicksInMs),bsFD.LfpData, 'uniformoutput', 0));
    D_fd = mode(diff(fdTicks)); % ms
    fdTicksAdj = (fdTicks - fdTicks(1) + D_fd)/1000;
    
    if IGNORE_DROP_PACK
        if isfield(bsFD.LfpData(1),'Left')
            stim.L = cell2mat(arrayfun(@(x)(x.Left.mA), bsFD.LfpData, 'uniformoutput', 0));
            perSpec.L = cell2mat(arrayfun(@(x)(x.Left.LFP), bsFD.LfpData, 'uniformoutput', 0));
        else
            stim.L = [];
            perSpec.L = [];
        end
        if isfield(bsFD.LfpData(1),'Right')
            stim.R = cell2mat(arrayfun(@(x)(x.Right.mA), bsFD.LfpData, 'uniformoutput', 0));
            perSpec.R = cell2mat(arrayfun(@(x)(x.Right.LFP), bsFD.LfpData, 'uniformoutput', 0));
            
        else
            stim.R = [];
            perSpec.R = [];
        end
        t_fd = (1:length(stim.L))'/fs_fd + (fdTicks(1)-tdTicks(1))/1000;
        
    else
        
        
        T_fd = (fdTicks(end) - fdTicks(1) + D_fd)/1000;
        t_fd = ((1/fs_fd):(1/fs_fd):T_fd)';
        stim.L = NaN(size(t_fd));
        stim.R = NaN(size(t_fd));
        perSpec.L = NaN(size(t_fd));
        perSpec.R = NaN(size(t_fd));
        
        if isfield(bsFD.LfpData(1),'Left')
            
            tdTicksAdjI = ((fdTicks - fdTicks(1))/D_fd+1);
            iSampInc = cell2mat(arrayfun(@(x)((x*D_fd/1000*fs_fd+((-D_fd/1000*fs_fd+1):1:0))'), tdTicksAdjI, 'uniformoutput', 0));
            stim.L(iSampInc) = cell2mat(arrayfun(@(x)(x.Left.mA), bsFD.LfpData, 'uniformoutput', 0));
            perSpec.L(iSampInc) = cell2mat(arrayfun(@(x)(x.Left.LFP), bsFD.LfpData, 'uniformoutput', 0));
            
        else
            stim.L = [];
            perSpec.L = [];
        end
        if isfield(bsFD.LfpData(1),'Right')
            tdTicksAdjI = ((fdTicks - fdTicks(1))/D_fd+1);
            iSampInc = cell2mat(arrayfun(@(x)((x*D_fd/1000*fs_fd+((-D_fd/1000*fs_fd+1):1:0))'), tdTicksAdjI, 'uniformoutput', 0));
            stim.R(iSampInc) = cell2mat(arrayfun(@(x)(x.Right.mA), bsFD.LfpData, 'uniformoutput', 0));
            perSpec.R(iSampInc) = cell2mat(arrayfun(@(x)(x.Right.LFP), bsFD.LfpData, 'uniformoutput', 0));
            
        else
            stim.R = [];
            perSpec.R = [];
        end
    end
    
    if sum(abs(diff(diff(fdTicks))))
        warning('off', 'verbose');
        warning('off', 'backtrace');
        warning('Packet loss for frequency-domain');
        spacing = diff(fdTicks)/ mode(diff(fdTicks));
        iDrop = find(spacing ~= 1);
        Ndrop = spacing(iDrop)-1;
        arrayfun(@(x,y)(warning(['Dropped ' num2str(x) ' packet(s) with timestamps between [' num2str(fdTicks(y)) ', ' num2str(fdTicks(y+1)-D_fd) '] (inclusive) ' ...
            '-- between times ' num2str(fdTicksAdj(y)) 's and ' num2str(fdTicksAdj(y+1)-D_fd/1000) 's'])), Ndrop, iDrop, 'uniformoutput', 0)
        warning('on', 'verbose');
        warning('on', 'backtrace');
    end
    
else
    t_fd = t_td;
    stim.R = zeros(size(t_td));
    stim.L = zeros(size(t_td));
    
end