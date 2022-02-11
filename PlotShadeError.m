function [plot_sig, plot_err] = PlotShadeError(x, y, er, varargin)


lw = 1;
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'axis'
            ax = varargin{i+1};
        case 'color'
            co = varargin{i+1};
        case 'linewidth'
            lw = varargin{i+1}';
    end
end

if ~exist('ax')
    ax = gca;
end
co = get(gca, 'ColorOrder');

if size(x,1) == 1
    x = x';
end

if size(x,1) ~= size(y,1)
    y = y';
end
if size(er,1) ~= size(x,1)
    er = er';
end

for i = 1:size(y,2)
    sigHi = y(:,i) + er(:,i);
    sigLo = y(:,i) - er(:,i);
    c = co(mod(length(get(ax, 'Children')), size(co, 1))+(1:size(y,2)), :);
    hold(ax, 'on');
    plot_err(i) = patch(ax, [x; flip(x)], [sigHi; flip(sigLo)], c, 'edgecolor', c, 'facealpha', 0.25, 'edgealpha', 0.25);
    plot_sig(i) = plot(ax, x, y(:,i), 'color', c, 'linewidth', lw);
    
    
    
end

