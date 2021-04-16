function p_out = GetFiles(p_in)
% ===================
% last edited 6/11/20 by LHH
% ===================
% A recursive function that goes through the path and extracts the files from
% all folders and subfolders
% ===================
% Input Variables:
% p_in = a cell array including the paths to folder(s) to extract the files
%     names from
% ===================
% Output Variables:
% p_out = a cell array including the paths of the files and folder in the input
%         path
% ===================
% Internal Variables:
% ext = extension for the components of p_in
% fn = file names for components of p_in
% iFile = indices for components of p_in that are files
% iFolder = indices for components of p_in that are folders
% iHidden = indices for components of p_in that are hidden files/folders
% uo = parameter for cellfun used, allowing output to not be uniform
% sl = direction of slash used for paths given the computer, either / or \
% subCont = cell array including directory information of the contents of 
%           each of the folders in p_in. Each cell corresponds to each 
%           folder in p_in, and contains a struct array regarding the 
%           direct information for each of the subcontents, including path, 
%           file name, etc.
% subContName = cell array including file names for the contents of each of
%               the folders in p_in. Each cell corresponds to each folder 
%               in p_in
% subContpath = cell array including full pathfor the contents of each of
%               the folders in p_in. Each cell corresponds to each folder 
%               in p_in
% ===================

%% defining parameters for cellfun used multiple times below
uo = {'uniformoutput', 0};
sl = SlDefine;

%% Extracts subfolder and files

[~, fn ,ext] = cellfun(@(x)(fileparts(x)), p_in, uo{:}); % finds the file name and extension for components of p_in
iHidden = cell2mat(cellfun(@(x)(isempty(x) || x(1)=='.'), fn, uo{:})); % finds indices of p_in that are hidden files/folders (start with a period)
iFolder = cell2mat(cellfun(@(x)(isempty(x)), ext, uo{:})); % finds indices of p_in that are folders by finding which don't have extensions
iFile = logical(~iFolder .* ~iHidden); % finds indices of files by those that have extensions but aren't hidden
subCont = cellfun(@(x)(dir(x)), p_in(iFolder), uo{:}); % finds the directory information the contents
                                                       % of each of the folders in p_in 
subContName = cellfun(@(x)({x.name}), subCont, uo{:}); % extracts the filenames for the contents of
                                                       % each of the folders in p_in
subContPath = cellfun(@(x,y)(cellfun(@(a)([x, sl, a]), y, uo{:})), ... 
                             p_in(iFolder), subContName, uo{:}); % concatenates the folder name. 
if isempty(subContPath) % if subContPath is empty, then all the contents of p_in are files
    p_out = p_in(iFile); % only output the files (needed to filter out hidden files)
else 
    p_out = [p_in(iFile) GetFiles([subContPath{:}])]; % Recursively calls GetFiles for the folders
                                                      % and then concatentaes to the files                                                       
end
