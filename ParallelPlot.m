function out = ParallelPlot(t,in, varargin)
% ===================
% last edited 9/12/19
% ===================
% This plots signals with offset y-axes so they can be visually compared
% ===================
% Input Variables:
% t = time vector 
% in = input signal (must have same time-domention as t) 
% varargin(1) = if user wants to define the offset between signals.
% otherwise, it is 1.5x the largest signal amplitude
% ===================
% Output Variables:
% out = the offset signals
% ===================
% Internal Variables:
% avg = means of channels
% demean = demeaned signals
% offset = spacing between the signals
% ranges = max-min of each channel
% maxR = largest ranges
% ===================

%% looks to see if user defined the offset
if size(varargin,1) ~= 0
    offset = varargin{1};
else
    offset = 0;
end

%% makes sure that the time and signal arrays use same dimension for time
if size(t,1) ~= size(in,1) & size(t,2) ~= size(in,2)
    error('t and in need to be both organized the samme -- both as columnn or row vectors');
end

%%  function assumes time-axis is dim1. if not, transposes
if size(t,2)>size(t,1) 
    in=in';
end

%% demeans signals
avg = mean(in);
demean = in - repmat(avg,size(in,1),1);

%% finds amplitudes of signals, and uses these to calculate the offset if not defined by the user
ranges = max(demean)-min(demean);
maxR = max(ranges);
if offset == 0
    offset = maxR*1.5;
end
out = demean - repmat(offset*(0:(size(in,2)-1)),size(in,1),1);

%% plots
plot(t,out);

end

