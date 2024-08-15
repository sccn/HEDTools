% Allows a user to tag a EEG structure. First all of the tag information
% and potential fields are extracted from EEG.event and EEG.etc.tags
% structures. After existing event tags are extracted and merged with an
% optional input fieldMap, the user is presented with a GUI to accept or
% exclude potential fields from tagging. Then the user is presented with
% the CTagger GUI to edit and tag. Finally, the tags are rewritten to the
% EEG structure.
%
% Usage:
%
%   >>  [EEG, com] = pop_tageeg(EEG)
%
%   >>  [EEG, com] = pop_tageeg(EEG, sidecare, 'key1', value1 ...)
%
%   >>  [EEG, com] = pop_tageeg(EEG, 'key1', value1 ...)
%
% Input:
%
%   Required:
%
%   EEG
%                    The EEG dataset structure that will be tagged. The
%                    dataset will need to have an .event field.
%
%   Optional:
%
%   UseGui
%                    If true (default), use a series of menus to set
%                    function arguments.
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
%   EEG
%                    The EEG dataset structure that has been tagged. The
%                    tags will be written to the .tags field under
%                    the .etc field.
%
%   tags
%                    A BIDS events.json sidecar string with HED annotation
%   com
%                    String containing call to tageeg with all parameters.
%
% Copyright (C) 2012-2016 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
% Kay Robbins kay.robbins@utsa.edu
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

function [EEG, tags, com] = pop_tageeg(EEG, varargin)
com = '';
checkHedObject();
global hed

% Display help if inappropriate number of arguments
if nargin < 1
    EEG = '';
    help pop_tageeg;
    return;
end

p = parseArguments(EEG, varargin{:});

% Call function with menu
if ~isempty(p.sidecar)
    if exist(p.sidecar, 'file')
        hed_json = fileread(p.sidecar);
    else
        hed_json = p.sidecar;
    end
    % issues = hed.validateSidecar(hed_json);
    issues = '';
    if isempty(issues)
        EEG.etc.HED = hed_json;
        
        fprintf('Tagging complete\n');
    else
        fprintf('Issues with sidecar annotations provided... \n');
        fprintf(issues);
        return;
    end
else
    if isfield(EEG, 'etc') && isfield(EEG.etc, 'HED')
        tags = EEG.etc.HED;
    else
        value_columns = {};
        skip_columns = {'latency', 'HED', 'usertags', 'hedtags'};
        tags = hed.generateSidecar(EEG.event, value_columns, skip_columns);
    end
    
    % tags is a json string
    % Use CTagger to add annotations
    [tags, canceled] = useCTagger(tags);

    EEG.etc.HED = tags;

    if canceled
        fprintf('Tagging was canceled\n');
        return;
    end    
    
    fprintf('Tagging complete\n');
end 

com = char(['pop_tageeg(' inputname(1) ', ' p.sidecar ...
    ', ' keyvalue2str(varargin{:}) ');']);

    %% Parse arguments
    function p = parseArguments(EEG, varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addRequired('EEG', @(x) (isempty(x) || isstruct(EEG)));
        parser.addOptional('sidecar', '', @ischar);
        parser.addParamValue('UseCTagger', true, @islogical);
        parser.parse(EEG, varargin{:});
        p = parser.Results;
    end % parseArguments

end % pop_tageeg