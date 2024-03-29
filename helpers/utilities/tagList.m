% Creates an object that holds a list of valid tags and tag groups
% associated with code.
%
% Usage:
%
%   >>  tList = tagList(code)
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

classdef tagList < hgsetget
    
    properties (Access = private)
        Code                % Code value associated with list
        Tags                % Map containing single tags in this list
    end % private properties
    
    methods
        function obj = tagList(code)
            %Constructor parses parameters and sets up initial data
            parser = inputParser;
            parser.addRequired('Code', @(x) (~isempty(x) && ischar(x)));
            parser.parse(code)
            obj.Code = parser.Results.Code;
            obj.Tags = containers.Map('KeyType', 'char', 'ValueType', ...
                'any');
        end % tagList constructor
        
        function errormsg = add(obj, value)
            % Add valid tag or tag group to this tagList
            errormsg = '';%tagList.validate(value);
            if ~isempty(errormsg)
                return;
            end
            %value = tagList.getCanonical(value);
            [tstring, errormsg] = tagList.stringify({value});
            if isempty(errormsg) && ~obj.Tags.isKey(tstring)
                obj.Tags(tstring) = value;
            end
        end  % add
        
        function errormsg = addList(obj, values)
            % Add a list of tags or tag group to this tagList
            if isempty(values) || ~iscell(values)
                errormsg = 'input empty or not cell array';
                return;
            end
            errormsg = '';
            for k = 1:length(values)
                errormsg = [errormsg '[' obj.add(values{k}) ...
                    ']']; %#ok<AGROW>
            end
        end  % addList
        
        
        function errormsg = addString(obj, tString)
            % Add a string of valid tags or tag groups to this tagList.
            [tlist, errormsg] = tagList.deStringify(tString);
            if ~isempty(errormsg)
                return;
            end
            for k = 1:length(tlist)
                msg = add(obj, tlist{k});
                if ~isempty(msg)
                    errormsg = [errormsg '[' tlist{k} ':' ...
                        msg '] ']; %#ok<AGROW>
                end
            end
        end  % addValueString
        
        function newList = clone(obj)
            % Clone this tagList object by making a copy of the tag maps
            newList = tagList(obj.Code);
            values = obj.Tags.values;
            tMap = newList.Tags;
            for k = 1:length(values)
                if iscellstr(values{k})
                    tMap(tagList.stringify(values{k})) = values{k};
                else
                    tMap(values{k}) = values{k};
                end
            end
            newList.Tags = tMap;
        end % clone
        
        function code = getCode(obj)
            % Returns the code associated with this tagList
            code = obj.Code;
        end % getCode
        
        function ntags = getCount(obj)
            % Returns the number of tags and tag groups in this tagList
            ntags = length(obj.Tags);
        end % getCount
        
        function jString = getJsonValues(obj)
            % Returns a JSON string version of this tagList object
            jString = tagList.values2Json(obj.Code, obj.Tags.values);
        end % getJsonValues
        
        function keys = getKeys(obj)
            % Returns the keys for this tagList
            keys = obj.Tags.keys;
        end % getCount
        
        function thisStruct = getStruct(obj)
            % Returns this tagList as a structure array
            thisStruct.code = obj.getCode();
            thisStruct.tags = obj.getTags();
        end % getStruct
        
        function tags = getTags(obj)
            % Returns a cell array with all of the tags and tag groups in
            % this tagList
            tags = obj.Tags.values;
        end % getTags
        
        function result = hasAnnotation(obj)
            % check if there's HED annotation associated with this tagList
            % by checking whether its Tags value is empty
            if ~isempty(obj.getTags)
                result = true;
            else
                result = false;
            end
        end % hasAnnotation
        
        function keysRemoved = intersect(obj, newList)
            % Keep only the keys that are in this tagList and in the other
            % tagList
            keys1 = newList.Tags.keys;
            keys2 = obj.Tags.keys;
            keysBoth = intersect(keys1, keys2);
            keysRemoved = setdiff(keys2, keysBoth);  % keys not in both
            for k = 1:length(keysRemoved)
                obj.remove(keysRemoved);
            end
        end % intersect
        
        
        function member = isMember(obj, value)
            % Returns true if value is a valid tag or tag group in this
            % tagList
            [tvalue, errormsg] = tagList.stringify({value});
            if ~isempty(errormsg) || ~obj.Tags.isKey(tvalue)
                member = false;
            else
                member = true;
            end
        end % isMember
        
        
        function remove(obj, value)
            % Remove the tag or tag group in this tagList corresponding to
            % value
            key = tagList.stringify({tagList.getCanonical(value)});
            if ~isempty(key)  && obj.Tags.isKey(key)
                obj.Tags.remove(key);
            end
        end  % remove
        
        function removePrefixes(obj)
            % Remove the tags from this tagList that are prefixes in
            % existing groups
            %             values = obj.Tags.values;
            %             % Remove duplicates from non groups
            %             nongroups = cellfun(@ischar, values);
            %             ngValues = values(nongroups);
            %             [~, duplicates] = tagList.separateDuplicates(ngValues, true);
            %             for k = 1:length(duplicates)
            %                 obj.remove(lower(strtrim(duplicates{k})));
            %             end
            %             % Remove duplicates from each tag group
            %             gValues = values(~nongroups);
            %             for k = 1:length(gValues)
            %                 keep = tagList.separateGroupDuplicates(gValues{k}, true);
            %                key = tagList.stringify(tagList.getCanonical(gValues{k}));
            %             if ~isempty(key)  && obj.Tags.isKey(key)
            %                 obj.Tags.remove(key);
            %             end
        end  % remove
        
        function setCode(obj, code)
            % Sets the code associated with this tagList
            obj.Code = code;
        end % setCode
        
        function keysAdded = union(obj, newList)
            % Adds the tags given in another tagList to those of this
            % tagList
            keysNew = newList.Tags.keys;
            keysOld = obj.Tags.keys;
            addedMask = false(size(keysOld));
            for k = 1:length(keysNew)
                if ~obj.isMember(keysNew{k})
                    obj.Tags(keysNew{k}) = newList.Tags(keysNew{k});
                    addedMask(k) = true;
                end
            end
            keysAdded = keysOld(addedMask);
        end % union
        
    end % public methods
    
    methods(Static = true)
        function [res,errormsg] = deStringify(tstring)
            res = deStringify_helper({},tstring);
            errormsg = '';
            function res = deStringify_helper(res, tstring)
                currRes = {};
                if ~isempty(tstring)
                    [idx,isTagGroup] = getFirstTagOrTagGroup(tstring);
                    if ~isTagGroup
                        currRes{1} = tstring(1:idx); %substring;
                    else
                        currRes{1} = deStringify_helper(res,stripParen(tstring(1:idx)));
                    end
                    res = [res currRes deStringify_helper(res,stripComma(tstring(idx+1:end)))];
                else 
                    res = [res currRes];
                end 
            
            end % deStringify_helper 
            function [endIdx, isTagGroup] = getFirstTagOrTagGroup(str)
                isTagGroup = false;
                endIdx = length(str);
                if ~isempty(str)
                    str = stripComma(str);

                    if strcmp(str(1),'(')
                        isTagGroup = true;
                        stack = {'('};
                        currIdx = 2;
                        while ~isempty(stack) && currIdx <= length(str)
                            if strcmp(str(currIdx),'(')
                                stack = [stack {'('}];
                            elseif strcmp(str(currIdx),')')
                                stack = stack(1:end-1);
                            end
                            currIdx = currIdx + 1;
                        end
                        %str = str(1:currIdx-1);
                        endIdx = currIdx-1;
                    else
                        comma_idx = strfind(str,',');
                        if ~isempty(comma_idx)
                            % has more string
        %                     str = str(1:comma_idx(1)-1);
                            endIdx = comma_idx(1)-1;
                        end
                    end
                end
            end
            function str = stripParen(origStr)
                str = strip(origStr);
                str = regexp(str,'(?<=^\()(.*)(?=\)$)','match');
                if ~isempty(str)
                    str = str{1};
                end
            end
            function str = stripComma(str)
                str = strip(strip(strip(str),','));
            end
        end % deStringify

%         function [tlist, errormsg] = deStringify(tstring)
%             % Create a cell array representing a comma-separated string of
%             % tags
%             tlist = {};
%             errormsg = '';
%             if isempty(tstring) || ~ischar(tstring)
%                 errormsg = 'input empty or not a string';
%                 return;
%             end
%             try
%                 tlist = regexpi(tstring, ',(?![^\(]*\))', 'split');
%                 % Remove empty cells
%                 tlist = tlist(~cellfun('isempty', strtrim(tlist)));
%                 for k = 1:length(tlist)
%                     if ~isempty(regexpi(tlist{k}, '^\s*\(', 'once'))
%                         tlist{k} = regexprep(tlist{k}, '[\(\)]', '');
%                         tlist{k} = regexpi(tlist{k}, ...
%                             ',', 'split');
%                         if any(~cellfun(@isempty, strfind(tlist{k}, '~')))
%                             tlist{k} = ...
%                                 tagList.splitTildesInGroup(tlist{k});
%                         end
%                     end
%                     tlist{k} = strtrim(tlist{k});
%                     msg = tagList.validate(tlist{k});
%                     if ~isempty(msg)
%                         errormsg = [errormsg '[' msg ']']; %#ok<AGROW>
%                     end
%                 end
%             catch mex
%                 errormsg = [errormsg '[' mex.message ']'];
%             end
%         end % deStringify
        
        function tsorted = getCanonical(tgroup)
            % Returns a sorted version of a valid tag or tag group
            tsorted = {};
            if isempty(tgroup)
                return;
            elseif ischar(tgroup)
                tsorted = strrep(tgroup, '"','');
                tsorted = strtrim(tsorted);
                %                 if ~strcmp(tsorted(1), '/')
                %                     tsorted = ['/', tsorted];
                %                 end
                if strcmp(tsorted(1), '/')
                    tsorted = tsorted(2:end);
                end
                if strcmp(tsorted(end), '/')
                    tsorted = tsorted(1:end-1);
                end
                return
            elseif ~iscellstr(tgroup)
                return;
            end
            tgroup = strrep(tgroup, '"','');
            tgroup = strtrim(tgroup(:))';   % make sure a row
            empties = cellfun(@isempty, tgroup);
            tgroup(empties) = [];   % remove empties
            for k = 1:length(tgroup)
                %                 if ~strcmp(tgroup{k}, '~') && ~strcmp(tgroup{k}(1), '/')
                %                     tgroup{k} = ['/', tgroup{k}];
                %                 end
                if ~strcmp(tgroup{k}, '~') && strcmp(tgroup{k}(1), '/')
                    tgroup{k} = tgroup{k}(2:end);
                end
                if ~strcmp(tgroup{k}, '~') && strcmp(tgroup{k}(end), '/')
                    tgroup{k} = tgroup{k}(1:end - 1);
                end
            end
            empties = cellfun(@isempty, tgroup);
            tgroup(empties) = [];   % remove empties
            tildepos = find(strcmpi('~', tgroup));
            tsorted = cell(1, length(tgroup));
            tindex = [0 tildepos length(tgroup) + 1];
            for k = 1:length(tildepos) + 1
                theind = (tindex(k) + 1):(tindex(k+1) - 1);
                tsorted(theind) = sort(tgroup(theind));
                if tindex(k+1) <= length(tgroup)
                    tsorted{tindex(k+1)} = '~';
                end
            end
        end % getCanonical
        
        function tCanonical = getUnsortedCanonical(tgroup)
            % Returns a unsorted version of a valid tag or tag group
            tCanonical = {};
            if isempty(tgroup)
                return;
            elseif ischar(tgroup)
                tCanonical = strrep(tgroup, '"','');
                tCanonical = strtrim(tCanonical);
                if strcmp(tCanonical(1), '/')
                    tCanonical = tCanonical(2:end);
                end
                %             if ~strcmp(tCanonical(1), '/')
                %                 tCanonical = ['/', tCanonical];
                %             end
                if strcmp(tCanonical(end), '/')
                    tCanonical = tCanonical(1:end-1);
                end
                return
            elseif ~iscellstr(tgroup)
                return;
            end
            tgroup = strrep(tgroup, '"','');
            tgroup = strtrim(tgroup(:))';   % make sure a row
            empties = cellfun(@isempty, tgroup);
            tgroup(empties) = [];   % remove empties
            for k = 1:length(tgroup)
                %             if ~strcmp(tgroup{k}, '~') && ~strcmp(tgroup{k}(1), '/')
                %                 tgroup{k} = ['/', tgroup{k}];
                %             end
                if ~strcmp(tgroup{k}, '~') && strcmp(tgroup{k}(1), '/')
                    tgroup{k} = tgroup{k}(2:end);
                end
                if ~strcmp(tgroup{k}, '~') && strcmp(tgroup{k}(end), '/')
                    tgroup{k} = tgroup{k}(1:end - 1);
                end
            end
            empties = cellfun(@isempty, tgroup);
            tgroup(empties) = [];   % remove empties
            tildepos = find(strcmpi('~', tgroup));
            tCanonical = cell(1, length(tgroup));
            tindex = [0 tildepos length(tgroup) + 1];
            for k = 1:length(tildepos) + 1
                theind = (tindex(k) + 1):(tindex(k+1) - 1);
                tCanonical(theind) = tgroup(theind);
                if tindex(k+1) <= length(tgroup)
                    tCanonical{tindex(k+1)} = '~';
                end
            end
        end % getUnsortedCanonical
        
        function tremoved = removeGroupDuplicates(tgroup, prefix)
            % Removes duplicates from a tag group based on prefix
            tremoved = {};
            if ~iscellstr(tgroup)
                return;
            end
            
            tildepos = find(strcmpi('~', tgroup));
            tindex = [0 tildepos length(tgroup) + 1];
            for k = 1:length(tildepos) + 1
                theind = (tindex(k) + 1):(tindex(k+1) - 1);
                piece = tgroup(theind);
                keep = tagList.separateDuplicates(piece, prefix);
                tremoved = [tremoved keep]; %#ok<AGROW>
                if tindex(k+1) <= length(tgroup)
                    tremoved = [tremoved {'~'}]; %#ok<AGROW>
                end
            end
        end   % removeGroupDuplicates
        
        function [keep, duplicates] = separateDuplicates(tlist, prefix)
            % Returns a list of tags without duplicates from cellstr
            duplicates = {};
            keep = {};
            if isempty(tlist)
                return;
            end
            nlist = sort(tagList.getCanonical(tlist));
            for k = 1:length(nlist) - 1
                if (~prefix && strcmp(nlist{k+1}, nlist{k})) || ...
                        (prefix && ...
                        ~isempty(regexp(nlist{k+1}, ['^' nlist{k}], ...
                        'match')))
                    duplicates{end + 1} = nlist{k}; %#ok<AGROW>
                else
                    keep{end + 1} = nlist{k}; %#ok<AGROW>
                end
            end
            keep{end + 1} = nlist{end};
            
        end % separateDuplicates
        
        function tildeTagGroup = splitTildesInGroup(TagGroup)
            % Splits the tildes in the cellstr tag group
            tildeTagGroup = {};
            tagGroupCount  = 1;
            numGroupTags = length(TagGroup);
            for groupTagNum = 1:numGroupTags
                if strfind(TagGroup{groupTagNum}, '~')
                    tildeTags = strtrim(strsplit(...
                        TagGroup{groupTagNum}, '~', ...
                        'CollapseDelimiters', false));
                    numTildeGroupTags = length(tildeTags);
                    for numTildeGroupTag = 1:numTildeGroupTags-1
                        tildeTagGroup{tagGroupCount} = ...
                            tildeTags{numTildeGroupTag}; %#ok<AGROW>
                        tagGroupCount  = tagGroupCount + 1;
                        tildeTagGroup{tagGroupCount} = '~'; %#ok<AGROW>
                        tagGroupCount  = tagGroupCount + 1;
                    end
                    tildeTagGroup{tagGroupCount} = ...
                        tildeTags{numTildeGroupTags}; %#ok<AGROW>
                    tagGroupCount  = tagGroupCount + 1;
                else
                    tildeTagGroup{tagGroupCount} = ...
                        TagGroup{groupTagNum}; %#ok<AGROW>
                    tagGroupCount  = tagGroupCount + 1;
                end
            end
        end % splitTildesInGroup
        
        function [tstring, errormsg] = stringify(tlist)
            % Create a string from a cell array of strings or cellstrs
            tstring = '';
            if isempty(tlist)
                errormsg = 'input is empty';
            elseif ~iscell(tlist) && ~ischar(tlist)
                errormsg = 'input is not cell array nor string';
            else
                if ischar(tlist)
                    tlist = {tlist};
                end
                tstring = jsonencode(tlist);
                tstring = strrep(strrep(tstring,'[','('),']',')');
                %tstring = strip(strip(tstring,'('),')');
                tstring = strrep(tstring,'"','');
                tstring = tstring(2:end-1);
                errormsg = '';
%                 [tstring, errormsg] = tagList.stringifyElement(tlist{1});
%                 if ~isempty(errormsg)
%                     return;
%                 end
%                 for k = 2:length(tlist)
%                     [tnext, errormsg] = tagList.stringifyElement(tlist{k});
%                     if ~isempty( errormsg)
%                         return;
%                         
%                     end
%                     tstring = [tstring ',' tnext]; %#ok<AGROW>
%                 end
            end
        end  % stringify
        
%         function [tstring, errormsg] = stringifyElement(telement)
%             % Create a string from cellstr or from string
%             tstring = '';
%             errormsg = '';
%             if isempty(telement)
%                 errormsg = 'element is empty';
%             elseif ischar(telement)
%                 tstring = strtrim(telement);
%             elseif iscellstr(telement)
%                 tstring = ['(' strtrim(telement{1})];
%                 for k = 2:length(telement)
%                     tstring = [tstring ',' ...
%                         strtrim(telement{k})]; %#ok<AGROW>
%                 end
%                 tstring = [tstring ')'];
%             else
%                 errormsg = 'element is not string or cellstr';
%             end
%         end  % stringifyElement
        
        function eJson = tagList2Json(value)
            % Convert a tagList to a JSON string
            res.code = value.getCode();
            res.tags = value.getTags();
            eJson = jsonencode(res);
%             tags = value.getTags();
%             code = value.getCode();
%             if isempty(tags)
%                 tagString = '';
%             elseif ischar(tags)
%                 tagString = ['["' tags '"]'];
%             else
%                 tagString = '';
%                 for j = 1:length(tags)
%                     if ischar(tags{j})
%                         tagString = ...
%                             [tagString ',' '["' tags{j} '"]']; %#ok<AGROW>
%                     else
%                         tagGroup = tags{j};
%                         tagGroupString = '';
%                         for k = 1:length(tagGroup)
%                             tagGroupString = ...
%                                 [tagGroupString ',' '"' ...
%                                 tagGroup{k} '"']; %#ok<AGROW>
%                         end
%                         tagGroupString = ...
%                             regexprep(tagGroupString,',','', 'once');
%                         tagString = ...
%                             [tagString ',' '[' ...
%                             tagGroupString ']']; %#ok<AGROW>
%                     end
%                 end
%                 tagString = regexprep(tagString,',','', 'once');
%             end
%             tagString = ['[' tagString ']'];
%             eJson = ['{"code":"' code, ...
%                 '","tags":' tagString '}'];
        end % tagList2Json
        
        function errormsg = validate(itag)
            % Validate the input as a valid tag or tag group
            if isempty(itag)
                errormsg = 'empty input';
            elseif ischar(itag)
                errormsg = tagList.validateTag(itag);
            elseif iscellstr(itag)
                errormsg = tagList.validateTagGroup(itag);
            else
                errormsg = 'input not char or cellstr';
            end
        end % validate
        
        function errormsg = validateTag(tstring) %#ok<INUSD>
            % Validate a tag string
            errormsg = '';
        end % validateTag
        
        function errormsg = validateTagGroup(cgroup)
            % Validate a cellstr containing a tag group
            errormsg = '';
            if isempty(cgroup) || ~iscellstr(cgroup)
                errormsg = 'group is empty or not a cellstr';
                return;
            end
            tildes = strcmpi('~', cgroup);
            if sum(tildes) > 2
                errormsg = 'group has more than 2 tildes';
                return;
            end
            for k = 1:length(cgroup)
                if strcmpi('~', cgroup{k})
                    continue;
                end
                msg = tagList.validateTag(cgroup{k});
                if ~isempty(msg)
                    errormsg = [errormsg '[' cgroup{k} ...
                        ':' msg '] ']; %#ok<AGROW>
                end
            end
        end % validateTagGroup
        
    end % static method
    
end % tagList