%% load all the percept data
clear all
% close all
fold = '~/Documents/Fellowship/Research/Percept/Data.nosync/';
fn = GetFiles({fold});
bool_json = cell2mat(cellfun(@(x)(contains(x(end-3:end), 'json')), fn, 'uniformoutput', 0));
fn = fn(bool_json);
fs = 250;
fsFreq = 2;
co = get(groot, 'defaultaxescolororder');

for i = 1:length(fn)
    json = fileread(fn{i});
    data{i} = jsondecode(json);
end

%% find events when stim is turned on / off


for i = 1:length(fn)
    boolOnOff=cell2mat(cellfun(@(x)(isfield(x, 'TherapyStatus')), data{i}.DiagnosticData.EventLogs, 'uniformoutput', 0));
    onOffdat = data{i}.DiagnosticData.EventLogs(boolOnOff);
    times = cellfun(@(x)(x.DateTime), onOffdat, 'uniformoutput', 0);
    status = cellfun(@(x)(contains(x.TherapyStatus, 'ON')), onOffdat, 'uniformoutput', 0);
    temponoff{i} = [times status ];
end

% concatenate for the same subject
fnSplit = cellfun(@(x)(split(x, '/')), fn, 'uniformoutput', 0);
iPercept = cellfun(@(x)(find(cell2mat(cellfun(@(y)(contains(y, 'Percept')), x, 'uniformoutput', 0)))), fnSplit, 'uniformoutput', 0);
sub = cellfun(@(x,y)(x{y+4}), fnSplit, iPercept, 'uniformoutput', 0);
iPer = cell2mat(cellfun(@(x)(contains(x, 'PER')), sub, 'uniformoutput', 0));
sub(iPer) = cellfun(@(x)(x(1:5)), sub(iPer), 'uniformoutput', 0);
subU = unique(sub);

for i = 1:length(subU)
    iCurrSub = cell2mat(cellfun(@(x)(contains(x, subU{i})), sub, 'uniformoutput', 0));
    temp = temponoff(iCurrSub);
    try
        onoff.(subU{i}) = cat(1, temp{:});
    catch
        disp('hi');
    end
    
    t = datetime(onoff.(subU{i})(:,1), 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss''Z');
    [~,idx] = sort(t);
    onoff.(subU{i}) = onoff.(subU{i})(idx,:);
    [~, ~, numRep] = unique(onoff.(subU{i})(:,1));
    [~, iUniq] = unique([numRep cell2mat(onoff.(subU{i})(:,2))], 'rows');
    onoff.(subU{i}) = onoff.(subU{i})(iUniq,:);
end

clear boolOnOff onOffdat status times temponoff temp

%% find files with time domain data
finas = cellfun(@(x)(fieldnames(x)), data, 'uniformoutput', 0);
containTD = cell2mat(cellfun(@(x)(logical(sum(contains(x, {'TimeDomain', 'SenseChannel'})))), finas, 'uniformoutput', 0));

fnNoTD = fn(~containTD);
fn = fn(containTD);
dataNoTD = data(~containTD);
data = data(containTD);
finas = finas(containTD);
sub = sub(containTD);

%% go through and plot each TD data
[b,a] = butter(3, 100/(fs/2), 'low');
for i = 1:5 %length(data)
 for iSub =  1:length(subU)
%     for iSub =  5
    idxSub = find(cell2mat(cellfun(@(x)(contains(x, subU{iSub})), sub, 'uniformoutput', 0)));
    
    for i = idxSub
        disp(fn{i});
        TDfields = {'LfpMontageTimeDomain', 'BrainSenseTimeDomain', 'IndefiniteStreaming', 'SenseChannelTests'};
        for k =  1:length(TDfields)
            if sum(contains(finas{i},TDfields{k}))
                for j = 1:length(data{i}.(TDfields{k}))
                    
                    if contains(TDfields{k}, 'BrainSenseTimeDomain')
                        tStmp = datetime(data{i}.BrainSenseTimeDomain(j).FirstPacketDateTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS''Z');
                        disp(tStmp);
                        [~,jMatch] = min(cell2mat(arrayfun(@(x)(abs(datenum(tStmp-datetime(x.FirstPacketDateTime, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS''Z')))), data{i}.BrainSenseLfp, 'uniformoutput', 0)));
                        [sig, t_td, fs_td, stim, t_fd, fs_fd, perSpec] = MatchSigAndStim(data{i}.BrainSenseTimeDomain(j), data{i}.BrainSenseLfp(jMatch), 1);
                        
                    else
                        [sig, t_td, fs_td, stim, t_fd, fs_fd, perSpec] = MatchSigAndStim(data{i}.LfpMontageTimeDomain(1), [], 1);
                        
                    end
                    
                    sigFilt = filter(b,a,sig);
                    
                    % frequency domain
                    [pxx,fxx] = pwelch(sig, fs, fs/2, 256);
                    [pxxFilt,fxxFilt] = pwelch(sigFilt, fs, fs/2, 256);
                    
                    figure;
                    set(gcf, 'units', 'normalized', 'position', [-1 0 1 1]);
                    subplot(2,2,1:2)
                    
                    PlotSigAndStim(sig, t_td, [stim.L, stim.R], t_fd, {'Left', 'Right'});
                    title({fn{i}, TDfields{k}, [num2str(j) ' -- ' data{i}.(TDfields{k})(j).Channel ' -- ' data{i}.(TDfields{k})(j).FirstPacketDateTime]});
                    
                    
                    subplot(2,2,3);
                    pl2=ParallelPlot(t_td, [sig, sigFilt]);
                    xlabel('time (s)');
                    ylabel('LFP (uV)');
                    set(gca, 'xlim', [0 10]);
                    pan xon;
                    
                    subplot(2,2,4);
                    hold on;
                    plot(fxx/pi*fs/2,pxx)
                    plot(fxxFilt/pi*fs/2,pxxFilt)
                    %                 set(gca, 'ylim', [0 100]);
                    %                 set(gca, 'xlim', [0 125]);
                    xlabel ('freq (Hz)');
                    ylabel ('PSD (uV^2/Hz)')
                    
                    set(findall(gcf,'-property','FontSize'),'FontSize',14)
                end
            end
        end
    end
end
