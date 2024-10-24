% Allows a user to tag a study and its associated datasets using a GUI. 
% pop_tagstudy first brings up a GUI to allow the user to set parameters
% for the tagstudy function, and then calls tagstudy to consolidate the
% tags from all of the data files in the study. Depending on the arguments,
% tagstudy may bring up a menu to allow the user to choose which fields
% should be tagged. The tagstudy function may also bring up the CTAGGER GUI
% to allow users to edit the tags.
%
% Usage:
%
%   >>  [STUDY, ALLEEG, fMap, com] = pop_tagstudy(STUDY, ALLEEG, 'key1', value1 ...)
%
% Input:
%
%   Required:
%
%   STUDY
%                    An EEGLAB STUDY structure
%
%   ALLEEG
%                    Structure array containing info of all datasets of a STUDY 
%
%   Optional (key/value):
%
%   'sidecar'
%                    A BIDS events.json sidecar with HED annotation
%
%   'UseCTagger'
%                    If true (default), the CTAGGER GUI is used to edit
%                    field tags.
%
% Output:
%
%   STUDY
%                    
%   ALLEEG
%                    Structure array containing all datasets of the STUDY
%                    with HED tags
%
%   com
%                    String containing call to tagstudy with all
%                    parameters.
%
% Copyright (C) 2012-2019 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
% Kay Robbins kay.robbins@utsa.edu
% Dung Truong dutruong@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 
function [STUDY, ALLEEG, com] = pop_tagstudy(STUDY, ALLEEG, varargin)
checkHedObject();
global hed
if nargin < 1
    help pop_tagstudy;
    return;
end

com = '';
p = parseArguments(varargin{:});

% Call function with menu
fprintf('Begin tagging...\n');
% Call function with menu
if ~isempty(p.sidecar)
    if exist(p.sidecar, 'file')
        hed_json = fileread(p.sidecar);
    else
        hed_json = p.sidecar;
    end
    issues = '';
    if isempty(issues)
        STUDY.etc.HED = hed_json;
        
        fprintf('Tagging complete\n');
    else
        fprintf('Issues with sidecar annotations provided... \n');
        fprintf(issues);
        return;
    end
else
    if isfield(STUDY, 'etc') && isfield(STUDY.etc, 'HED')
        tags = STUDY.etc.HED;
    else
        % merge tags from EEG
        tags = struct([]);
        for e=1:numel(ALLEEG)
            EEG = ALLEEG(e);
            
            if isfield(EEG, 'etc') && isfield(EEG.etc, 'HED')
                EEGtags = EEG.etc.HED;
            else
                value_columns = {'duration', 'epoch'};
                skip_columns = {'latency', 'HED', 'usertags', 'hedtags', 'description', 'urevent'};
                EEGtags = hed.generateSidecar(EEG.event, value_columns, skip_columns);
            end
            tags = mergestruct(jsondecode(EEGtags), tags);
        end
        tags = jsonencode(tags);
    end
    
    % tags is a json string
    % Use CTagger to add annotations
    [tags, canceled] = useCTagger(tags);
    
    if canceled
        fprintf('Tagging was canceled\n');
        return;
    end    

    % save tags
    STUDY.etc.HED = tags;
    for i=1:numel(ALLEEG)
        ALLEEG(i).etc.HED = tags;
    end

    
    fprintf('Tagging complete\n');
end 

com = char(['pop_tagstudy(' logical2str(p.UseGui) ...
    ', ' keyvalue2str(varargin{:}) ');']);
 
%% Helper functions

    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addOptional('UseGui', true, @islogical);
        parser.addOptional('sidecar', '', @ischar);
        parser.addParamValue('UseCTagger', true, @islogical);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments
 
end % pop_tagstudy
