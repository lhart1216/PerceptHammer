fn = '~/Documents/Fellowship/Research/ADAPT-PD/Json/MW_Report_Json_Session_Report_20211111T100914.json';
 data = LoadJson(fn);
%% Left

thresh.L = [data.Groups.Initial(1).ProgramSettings.SensingChannel(1).LowerLfpThreshold...
          data.Groups.Initial(1).ProgramSettings.SensingChannel(1).UpperLfpThreshold];

stim.L = [data.Groups.Initial(1).ProgramSettings.SensingChannel(1).LowerLimitInMilliAmps ...
        data.Groups.Initial(1).ProgramSettings.SensingChannel(1).UpperLimitInMilliAmps];
      
      
% 11/9
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left.x2021_11_09T15_17_34Z;
PlotTimeline(tlob, thresh.L, stim.L, 'LEFT')

% 11/10
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left.x2021_11_10T15_17_34Z;
PlotTimeline(tlob, thresh.L, stim.L, 'LEFT')

% 11/11
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left.x2021_11_11T15_17_34Z;
PlotTimeline(tlob, thresh.L, stim.L, 'LEFT')


%% Right

thresh.R = [data.Groups.Initial(1).ProgramSettings.SensingChannel(2).LowerLfpThreshold...
          data.Groups.Initial(1).ProgramSettings.SensingChannel(2).UpperLfpThreshold];

stim.R = [data.Groups.Initial(1).ProgramSettings.SensingChannel(2).LowerLimitInMilliAmps ...
        data.Groups.Initial(1).ProgramSettings.SensingChannel(2).UpperLimitInMilliAmps];
      
      
% 11/9
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_09T15_17_34Z;
PlotTimeline(tlob, thresh.R, stim.R, 'RIGHT')

% 11/10
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_10T15_17_34Z;
PlotTimeline(tlob, thresh.R, stim.R, 'RIGHT')

% 11/11
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_11T15_17_34Z;
PlotTimeline(tlob, thresh.R, stim.R, 'RIGHT')

%% Left after first adjustment
thresh1.L = thresh.L - diff(thresh.L)/2;
      
% 11/9
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left.x2021_11_09T15_17_34Z;
PlotTimeline(tlob, [thresh.L; thresh1.L], stim.L, 'LEFT')


% 11/10
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left.x2021_11_10T15_17_34Z;
PlotTimeline(tlob, [thresh.L; thresh1.L], stim.L, 'LEFT')

% 11/11
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Left.x2021_11_11T15_17_34Z;
PlotTimeline(tlob, [thresh.L; thresh1.L], stim.L, 'LEFT')


%% Right after first adjustment
thresh1.R = thresh.R - diff(thresh.R);
      
% 11/9
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_09T15_17_34Z;
PlotTimeline(tlob, [thresh.R; thresh1.R], stim.R, 'RIGHT')

% 11/10
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_10T15_17_34Z;
PlotTimeline(tlob, [thresh.R; thresh1.R], stim.R, 'RIGHT')

% 11/11
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_11T15_17_34Z;
PlotTimeline(tlob, [thresh.R; thresh1.R], stim.R, 'RIGHT')


%% Right after second adjustment
thresh2.R = thresh.R - 1.35*diff(thresh.R);
      
% 11/9
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_09T15_17_34Z;
PlotTimeline(tlob, [thresh.R; thresh1.R; thresh2.R], stim.R, 'RIGHT')

% 11/10
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_10T15_17_34Z;
PlotTimeline(tlob, [thresh.R; thresh1.R; thresh2.R], stim.R, 'RIGHT')

% 11/11
tlob = data.DiagnosticData.LFPTrendLogs.HemisphereLocationDef_Right.x2021_11_11T15_17_34Z;
PlotTimeline(tlob, [thresh.R; thresh1.R; thresh2.R], stim.R, 'RIGHT')
