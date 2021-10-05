function [jsondat, fn] = LoadJson(p)
% can pass path to a file, or to a directory (and will extract all json
% files from it)

uo = {'uniformoutput', 0};

fn = {};
[~,~,ext] = fileparts(p);


if isempty(ext) % passed a directory
    fn = GetFiles({p});
    bool_json = cell2mat(cellfun(@(x)(contains(x(end-3:end), 'json')), fn, uo{:}));
    fn = fn(bool_json);
    
    for i = 1:length(fn)
        temp = fileread(fn{i});
        jsondat{i} = jsondecode(temp);
    end
    jsondat = jsondat';
    fn = fn';
    
else % passed a file name
    temp = fileread(p);
    if contains(ext, 'json')
    jsondat = jsondecode(temp);
    else
        error('Input file is not a json file');
    end
end







