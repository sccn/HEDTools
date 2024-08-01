% This function will extract data epochs time locked to events that contain
% specified HED tags. The HED tags are assumed to be stored in the
% .event.HED field of EEG structure passed in.
%
% Usage:
%
%   >> EEG = epochhed(EEG, querystring)
%
%   >> EEG = epochhed(EEG, querystring, varargin)
%
% Inputs:
%
%   EEG
%                Input dataset. Data may already be epoched; in this case,
%                extract (shorter) subepochs time locked to epoch events.
%                The dataset is assumed to be tagged and has a .HED field in the .event structure.
%
%   querystring  
%                A query string consisting of tags that you want to search
%                for. Two tags separated by a comma use the AND operator
%                by default, meaning that it will only return a true match
%                if both the tags are found. The OR (||) operator returns
%                a true match if either one or both tags are found.
%
% Optional inputs (key/value):
%
%   'exclusivetags'
%                A cell array of tags that nullify matches to other tags.
%                If these tags are present in both the EEG dataset event
%                tags and the tag string then a match will be returned.
%                By default, this argument is set to
%                {'Attribute/Intended effect', 'Attribute/Offset', 
%                Attribute/Participant indication}.
%
%   'newname'
%                New dataset name. The default is "[old_dataset] epochs"
%
%   'valuelim'
%                [min max] data limits. If one positive value is given,
%                the opposite value is used for lower bound. For example,
%                use [-50 50] to remove artifactual epoch. The default is
%                [-Inf Inf].
%
%   'verbose'
%                ['on'|'off']. The default is 'on'.
%
% deprecated
%
%   'timeunit'
%                Time unit ['seconds'|'points'] If 'seconds,' consider
%                events times to be in seconds. If 'points,' consider
%                events as indices into the data array. The default is
%                'points'.
% Outputs:
%
%   EEG
%                Output dataset that has extracted data epochs.
%
%   indices
%                The indices of accepted events.  
%
%   epochHedStrings
%                A cell array of HED strings associated with the
%                time-locking event for each epoch.
%
% Copyright (C) 2012-2018 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
% Kay Robbins kay.robbins@utsa.edu
%
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

function [EEG, indices, epochHedStrings] = epochhed(EEG, querystring, ...
    varargin)
global hed
parsedArguments = parseArguments(EEG, querystring, varargin{:});
eventsRect = rectify_events(EEG.event, EEG.srate);
issues = hed.validateEvents(eventsRect, EEG.etc.HED);
annotations = hed.getHedAnnotations(eventsRect, EEG.etc.HED);
factors = hed.searchHed(annotations, querystring);
indices = find(factors);
EEG = pop_epoch(EEG, '', parsedArguments.timelim, 'eventindices', indices); % TODO select time window
epochHedStrings = annotations(indices);


    function p = parseArguments(EEG, querystring, varargin)
        % Parses the arguments passed in and returns the results
        p = inputParser();
        p.addRequired('EEG', @(x) ~isempty(x) && isstruct(x));
        p.addRequired('querystring', @(x) ischar(x));
        p.addParamValue('timelim', [-1 2], @(x) isnumeric(x) && ...
            numel(x) == 2);
        p.addParamValue('eventindices', 1:length(EEG.event), ...
            @isnumeric); %#ok<NVREPL>
        p.addParamValue('exclusivetags', ...
            {'Attribute/Intended effect', 'Attribute/Offset'}, ...
            @iscellstr); %#ok<NVREPL>
        p.addParamValue('mask', [], ...
            @islogical); %#ok<NVREPL>
        p.addParamValue('newname', [EEG.setname ' epochs'], ...
            @(x) ischar(x)); %#ok<NVREPL>
        p.addParamValue('timeunit', 'points', ...
            @(x) any(strcmpi({'points', 'seconds'}, x))); %#ok<NVREPL>
        p.addParamValue('valuelim', [-inf inf], ...
            @(x) isnumeric(x) && any(numel(x) == [1 2])) %#ok<NVREPL>
        p.addParamValue('verbose', 'on', ...
            @(x) any(strcmpi({'on', 'off'}, x)));  %#ok<NVREPL>
        p.parse(EEG, querystring, varargin{:});
        p = p.Results;
    end % parseArguments
end % epochhed