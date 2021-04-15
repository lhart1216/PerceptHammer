function [sig, t_td, fs_td, stim, t_fd, fs_fd] = MatchSigAndStim(bsTD, bsFD)
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
sig = bsTD.TimeDomainData;
if sum(abs(diff(diff(tdTicks))))
    warning('off', 'verbose');
    warning('off', 'backtrace');
    warning('Packet loss for time-domain');
    spacing = diff(tdTicks)/ mode(diff(tdTicks));
    iDrop = find(spacing ~= 1);
    Ndrop = spacing(iDrop)-1;
    arrayfun(@(x,y)(warning(['Dropped ' num2str(x) ' packet(s) between [' num2str(tdTicks(y)) ', ' num2str(tdTicks(y+1)) ']'])), Ndrop, iDrop, 'uniformoutput', 0)
    warning('on', 'verbose');
    warning('on', 'backtrace');
end
t_td = (1:length(sig))'/fs_td;

% get frequency domain
if ~isempty(bsFD)
fdTicks = cell2mat(arrayfun(@(x)(x.TicksInMs),bsFD.LfpData, 'uniformoutput', 0));
if isfield(bsFD.LfpData(1),'Left')
    stim.L = cell2mat(arrayfun(@(x)(x.Left.mA), bsFD.LfpData, 'uniformoutput', 0));
else
    stim.L = [];
end
if isfield(bsFD.LfpData(1),'Right')
    stim.R = cell2mat(arrayfun(@(x)(x.Right.mA), bsFD.LfpData, 'uniformoutput', 0));
else
    stim.R = [];
end

if sum(abs(diff(diff(fdTicks))))
    warning('off', 'verbose');
    warning('off', 'backtrace');
    warning('Packet loss for frequency-domain');
    spacing = diff(fdTicks)/ mode(diff(fdTicks));
    iDrop = find(spacing ~= 1);
    Ndrop = spacing(iDrop)-1;
    arrayfun(@(x,y)(warning(['Dropped ' num2str(x) ' packet(s) between [' num2str(fdTicks(y)) ', ' num2str(fdTicks(y+1)) ']'])), Ndrop, iDrop, 'uniformoutput', 0)
    warning('on', 'verbose');
    warning('on', 'backtrace');
end
t_fd = (1:length(stim.L))'/fs_fd + (fdTicks(1)-tdTicks(1))/1000;
else
    t_fd = t_td;
    stim.R = zeros(size(t_td));
    stim.L = zeros(size(t_td));

end