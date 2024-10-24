% This function validates the HED tags in a EEG dataset structure against
% a HED schema.
%
% Usage:
%
%   >>  issues = validateeeg(EEG)
%
%   >>  issues = validateeeg(EEG, 'key1', 'value1', ...)
%
% Input:
%
%   EEG         
%                   A EEG dataset structure containing HED tags.
%
%   Optional (key/value):
%
%   'GenerateWarnings'
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
%   'HedXml'
%                   The full path to a HED XML file containing all of the
%                   tags. This by default will be the HED.xml file
%                   found in the hed directory.
%
%   'outputFileDirectory'
%                   The directory where the validation output is written 
%                   to. There will be a log file generated for each study
%                   dataset validated.
%
%   'writeOutputToFile'
%                   If true, write the validation issues to a
%                   log file in addition to the workspace. If false,
%                   (default) only write the issues to the workspace. 
%
% Output:
%
%   issues
%                   A struct array containing all of the issues found through
%                   the validation. Each struct corresponds to the issues
%                   found on a particular line/event. Empty string if no
%                   issue
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

function issues = validateeeg(EEG, varargin)
p = parseArguments(EEG, varargin{:});
checkHedObject();
global hed

% Validates the eeg structure
if isfield(p.EEG, 'etc') && isfield(p.EEG.etc, 'HED')
    issues = hed.validateEvents(p.EEG.event, p.EEG.etc.HED);
    
    if p.writeOutputToFile
        writeOutputFile(p);
    end
else
    issues = ['The HED field do not exist in' ...
        ' the events. Please tag this dataset before' ...
        ' running the validation.\n'];
end


    function p = parseArguments(EEG, varargin)
        % Parses the arguements passed in and returns the results
        p = inputParser();
        p.addRequired('EEG', @(x) (~isempty(x) && isstruct(x)));
        p.addParamValue('generateWarnings', false, ...
            @(x) validateattributes(x, {'logical'}, {}));
        p.addParamValue('hedXml', 'HED.xml', ...
            @(x) (~isempty(x) && ischar(x)));
        p.addParamValue('outputFileDirectory', pwd, @ischar);
        p.addParamValue('writeOutputToFile', false, @islogical);
        p.parse(EEG, varargin{:});
        p = p.Results;
    end % parseArguments
    
    function parsedIssues = parseIssues(issues)
        % process issues to see if it's all empty. In such case, return
        % empty string indicating no issue found
        checkIfEmpty = cellfun(@isempty, issues);
        if sum(checkIfEmpty) == numel(issues)
            parsedIssues = '';
        else
            parsedIssues = [];
            for i=1:numel(issues)
                if ~isempty(issues{i})
                    issueStruct = [];
                    issueStruct.event = ['Issue(s) found in event ' num2str(i)];
                    issueStruct.issues = issues{i};
                    parsedIssues = [parsedIssues issueStruct];
                end
            end
        end
    end
    function writeOutputFile(p)
        % Writes the issues to the log file
        p.dir = p.outputFileDirectory;
        if ~isempty(p.EEG.filename)
        [~, p.file] = fileparts(p.EEG.filename);
        else
        [~, p.file] = fileparts(p.EEG.setname);    
        end
        p.ext = '.txt';
        try
            if ~isempty(p.issues)
                createLogFile(p, false);
            else
                createLogFile(p, true);
            end
        catch
            throw(MException('validateeeg:cannotWrite', ...
                'Could not write log file'));
        end
    end % writeOutputFiles

    function createLogFile(p, empty)
        % Creates a log file containing any issues
        errorFile = fullfile(p.dir, ['validated_' p.file p.ext]);
        fileId = fopen(errorFile,'w');
        if ~empty
            for i=1:numel(p.issues)
                printIssue(p.issues(i), fileId);
                fprintf(fileId, '\n');
            end
        else
            fprintf(fileId, 'No issues were found.');
        end
        fclose(fileId);
    end % createLogFile
    
    function printIssue(issueStruct, fileId)
        % key 'event' and 'issues' are defined in parseIssues()
        fprintf(fileId, '%s:\n',issueStruct.event);
        for i=1:numel(issueStruct.issues)
            fprintf(fileId, '\t-%s', issueStruct.issues(i).message); % issues.message is the key defined by Python validator
        end
    end
end % validateeeg