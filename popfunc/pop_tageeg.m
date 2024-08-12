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
%   'BaseMap'
%                    A json file containing HED annotation 
%                    (see https://bids-specification.readthedocs.io/en/stable/99-appendices/03-hed.html#annotating-events-by-categories)
%                    or fieldMap object or the name of a file that contains
%                    a fieldMap object to be used to initialize tag
%                    information.
%
%   'EventFieldsToIgnore'
%                    A one-dimensional cell array of field names in the
%                    .event substructure to ignore during the tagging
%                    process. By default the following subfields of the
%                    .event structure are ignored: .latency, .epoch,
%                    .urevent, .HED. The user can
%                    over-ride these tags using this name-value parameter.
%
%   'FMapDescription'
%                    The description of the fieldMap object. The
%                    description will show up in the .etc.tags.description
%                    field of any datasets tagged by this fieldMap.
%
%   'FMapSaveFile'
%                    A string representing the file name for saving the
%                    final, consolidated fieldMap object that results from
%                    the tagging process.
%
%   'HEDExtensionsAllowed'
%                    If true (default), the HED can be extended. If
%                    false, the HED cannot be extended. The
%                    'ExtensionAnywhere argument determines where the HED
%                    can be extended if extension are allowed.
%
%   'HedXML'
%                    Full path to a HED XML file. The default is the
%                    HED.xml file in the hed directory.
%
%   'OverwriteUserHed'
%                    If true, overwrite/create the 'HED_USER.xml' file with
%                    the HED from the fieldMap object. The
%                    'HED_USER.xml' file is made specifically for modifying
%                    the original 'HED.xml' file. This file will be written
%                    under the 'hed' directory.
%
%   'PreserveTagPrefixes'
%                    If false (default), tags for the same field value that
%                    share prefixes are combined and only the most specific
%                    is retained (e.g., /a/b/c and /a/b become just
%                    /a/b/c). If true, then all unique tags are retained.
%
%   'PrimaryEventField'
%                    The name of the primary field. Only one field can be
%                    the primary field. A primary field requires a label,
%                    category, and a description tag. The default is the
%                    .type field.
%
%   'SeparateUserHedFile'
%                    The full path and file name to write the HED from the
%                    fieldMap object to. This file is meant to be
%                    stored outside of the HEDTools.
%
%   'UseCTagger'
%                    If true (default), the CTAGGER GUI is used to edit
%                    field tags.
%
%   'WriteFMapToFile'
%                    If true, write the fieldMap object to the
%                    specified 'FMapSaveFile' file.
%
%   'WriteSeparateUserHedFile'
%                    If true, write the fieldMap object to the file
%                    specified by the 'SeparateUserHedFile' argument.
%
% Output:
%
%   EEG
%                    The EEG dataset structure that has been tagged. The
%                    tags will be written to the .tags field under
%                    the .etc field.
%
%   fMap
%                    A fieldMap object that stores all of the tags.
%
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
<<<<<<< HEAD
checkHedObject();
global hed
=======
if ~exist('hed', 'var')
    hed = getHedTools('8.2.0', 'https://hedtools.org/hed');
end
>>>>>>> main
% Display help if inappropriate number of arguments
if nargin < 1
    EEG = '';
    help pop_tageeg;
    return;
end

p = parseArguments(EEG, varargin{:});
inputArgs = getkeyvalue({'BaseMap', 'EventFieldsToIgnore' ...
        'HedXml', 'PreserveTagPrefixes'}, varargin{:});
% Call function with menu
<<<<<<< HEAD
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
=======
if p.UseGui
    if isfield(EEG, 'etc') && isfield(EEG.etc, 'HED')
        tags = EEG.etc.HED;
    else
        tags = hed.getHedSidecarTemplate(EEG.event);
>>>>>>> main
    end
    
    % tags is a json string
    % Use CTagger to add annotations
    [tags, canceled] = useCTagger(tags);

<<<<<<< HEAD
    EEG.etc.HED = tags;

    if canceled
        fprintf('Tagging was canceled\n');
        return;
    end    
    
    fprintf('Tagging complete\n');
end 
=======
    if canceled
        fprintf('Tagging was canceled\n');
        return;
    end    
    
    fprintf('Tagging complete\n');
    
    % Save HED if modified
    % if fMap.getXmlEdited()
    %     savehedInputArgs = getkeyvalue({'OverwriteUserHed', ...
    %         'SeparateUserHedFile', 'WriteSeparateUserHedFile'}, ...
    %         varargin{:});
    %     [fMap, overwriteUserHed, separateUserHedFile, ...
    %         writeSeparateUserHedFile] = pop_savehed(fMap, ...
    %         savehedInputArgs{:});
    %     savehedOutputArgs = {'OverwriteUserHed', overwriteUserHed, ...
    %         'SeparateUserHedFile', separateUserHedFile, ...
    %         'WriteSeparateUserHedFile', writeSeparateUserHedFile};
    %     inputArgs = [inputArgs savehedOutputArgs];
    % end
    
    % Write tags to EEG
    fprintf('Saving tags... ');
    % EEG = writetags(EEG, fMap, 'PreserveTagPrefixes', p.PreserveTagPrefixes, 'WriteIndividualTags', false); 
    % EEG = writetags(EEG, fMap, 'WriteIndividualTags', true);
    EEG.etc.HED = tags;
    fprintf('Done.\n');
else % Call function without menu %if nargin > 1 && ~p.UseGui
    % extract tag map from EEG. If none exists, create a new empty fMap
    % [fMap, canceled, ~] = findtags(EEG);
    tags = findtags(EEG);

    % if a base map is provided, merge it
    if isfield(p, 'BaseMap')
        if ischar(p.BaseTags)
            base_tags = jsonread(p.BaseTags);
        elseif isstruct(p.BaseTags)
            base_tags = p.BaseTags;
        else
            base_tags = struct([]);
        end
        tags = mergeStructures(tags, base_tags);
    end

    % Write tags to EEG
    fprintf('Saving tags... ');
    if isfield(EEG, 'etc')
        EEG.etc.HED = tags;
    else
        EEG.etc = [];
        EEG.etc.HED = tags;
    end
        
    fprintf('Done.\n');
end
>>>>>>> main

com = char(['pop_tageeg(' inputname(1) ', ' p.sidecar ...
    ', ' keyvalue2str(inputArgs{:}) ');']);

<<<<<<< HEAD
=======
%%% Helper functions
    function tags = findtags(EEG)
        if isfield(EEG, 'etc') 
            if isfield(EEG.etc, 'HED')
                tags = EEG.etc.HED;
            else
                tags = createEmptyHEDStructFromEvents(EEG);
            end
        else
            tags = createEmptyHEDStructFromEvents(EEG);
        end
    end
    function tags = createEmptyHEDStructFromEvents(EEG)
        event_fields = fieldnames(EEG.event);
        tags = [];
        for i=1:numel(event_fields)
            tags.(event_fields{i}) = [];
            if ischar(EEG.event(1).(event_fields{i}))
                unique_vals = unique({EEG.event.(event_fields{i})});
            else
                unique_vals = unique([EEG.event.(event_fields{i})]);
            end
            tags.(event_fields{i}).HED = [];
            if numel(unique_vals) < 20 % arbitrary threshold
                for j=1:numel(unique_vals)
                    tags.(event_fields{i}).HED.(reformatInvalidValue(unique_vals{j})) = [];
                end
            end
        end
    end
    function value = reformatInvalidValue(value)
        if isnumeric(value)
            value = sprintf('x%d', value); % assume int
        elseif ischar(value)
            if strcmp(value, 'n/a')
                value = 'na';
            end
        end
    end
    
>>>>>>> main
    %% Parse arguments
    function p = parseArguments(EEG, varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addRequired('EEG', @(x) (isempty(x) || isstruct(EEG)));
        parser.addOptional('sidecar', '', @ischar);
        parser.addParamValue('BaseMap', '', @(x) isa(x, 'fieldMap') || ...
            ischar(x));
        parser.addParamValue('EventFieldsToIgnore', ...
            {'latency', 'epoch', 'urevent', 'HED'}, ...
            @iscellstr);
        parser.addParamValue('FMapDescription', '', @ischar);
        parser.addParamValue('FMapSaveFile', '', @(x)(isempty(x) || ...
            (ischar(x))));
        parser.addParamValue('HedExtensionsAllowed', true, @islogical);
        parser.addParamValue('HedXml', which('HED.xml'), @ischar);
        parser.addParamValue('OverwriteUserHed', false, @islogical);
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.addParamValue('PrimaryEventField', 'type', @(x) ...
            (isempty(x) || ischar(x)))
        parser.addParamValue('SeparateUserHedFile', '', @(x) ...
            (isempty(x) || (ischar(x))));
        parser.addParamValue('UseCTagger', true, @islogical);
        parser.addParamValue('WriteFMapToFile', false, @islogical);
        parser.addParamValue('WriteSeparateUserHedFile', false, ...
            @islogical);
        parser.parse(EEG, varargin{:});
        p = parser.Results;
    end % parseArguments

end % pop_tageeg