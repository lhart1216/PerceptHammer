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
D_td = mode(diff(tdTicks)); % ms
tdTicksAdjT = (tdTicks - tdTicks(1) + D_td)/1000;
tdTicksAdjI = tdTicksAdjT / D_td * 1000;


if IGNORE_DROP_PACK
    sig = bsTD.TimeDomainData;
    t_td = (1:length(sig))'/fs_td;
else
    tdPack = cell2mat(cellfun(@(x)(str2num(x)),split(tdPackStr, ','), 'uniformoutput', 0));
    
    T_td = (tdTicks(end) - tdTicks(1) + D_td)/1000;
    t_td = ((1/fs_td):(1/fs_td):T_td)';
    sig = NaN(size(t_td));
    iPackInc = ((tdTicks - tdTicks(1))/D_td+1);
    
    NpackExpect = max(iPackInc);
    if (D_td*fs_td/1000) == floor (D_td*fs_td/1000) % number of samples per packet expected to be an integer
        sizePackExpect = (D_td*fs_td/1000) * ones(NpackExpect,1);
    else % number of samples per packet is not an integer -- plan to alternate # of samples per packet
        sizePackExpect = floor(D_td*fs_td/1000) * ones(NpackExpect,1);
        if tdPack(1) > floor(D_td*fs_td/1000) % starts with larger
            sizePackExpect(1:2:end) = floor(D_td*fs_td/1000)+1;
        else % starts with smaller
            sizePackExpect(2:2:end) = floor(D_td*fs_td/1000)+1;
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
            
            iPackInc = ((fdTicks - fdTicks(1))/D_fd+1);
            iSampInc = cell2mat(arrayfun(@(x)((x*D_fd/1000*fs_fd+((-D_fd/1000*fs_fd+1):1:0))'), iPackInc, 'uniformoutput', 0));
            stim.L(iSampInc) = cell2mat(arrayfun(@(x)(x.Left.mA), bsFD.LfpData, 'uniformoutput', 0));
            perSpec.L(iSampInc) = cell2mat(arrayfun(@(x)(x.Left.LFP), bsFD.LfpData, 'uniformoutput', 0));
            
        else
            stim.L = [];
            perSpec.L = [];
        end
        if isfield(bsFD.LfpData(1),'Right')
            iPackInc = ((fdTicks - fdTicks(1))/D_fd+1);
            iSampInc = cell2mat(arrayfun(@(x)((x*D_fd/1000*fs_fd+((-D_fd/1000*fs_fd+1):1:0))'), iPackInc, 'uniformoutput', 0));
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