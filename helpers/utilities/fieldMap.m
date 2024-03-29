% Creates an object encapsulating xml tags and type-tagMap association.
% This object can produce output in either JSON or a structure array.
%
% Usage:
%
%   >>  obj = fieldMap()
%
%   >>  obj = fieldMap('key1', 'value1', ...)
%
% Input:
%
%    Optional (key/value):
%
%   'Description'      
%                      String describing the purpose of this fieldMap.
%
%   'PreserveTagPrefixes'   
%                      Logical if false (default) tags with matching
%                      prefixes are merged to be the longest.
%
%   'XML'              
%                      XML string specifying tag hierarchy to be used.
%
% Notes:
%
%   Merge options:
%
%   'Merge'           
%                     If an event with that key is not part of this
%                     object, add it as is.
%
%   'None'            
%                     Don't update anything in the structure
%
%   'Replace'         
%                     If an event with that key is not part of this
%                     object, do nothing. Otherwise, if an event with that
%                     key is part of this object then completely replace
%                     that event with the new one.
%
%   'Update'          
%                     If an event with that key is not part of this
%                     object, do nothing. Otherwise, if an event with that
%                     key is part of this object, then update the tags of
%                     the matching event with the new ones from this event,
%                     using the PreserveTagPrefixes value to determine how to
%                     combine the tags. Also update any empty code
%                     fields by using the values in the
%                     input event.
%
% Copyright (C) Kay Robbins and Thomas Rognon, UTSA, ...
% 2011-2013, krobbins@cs.utsa.edu
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

classdef fieldMap < hgsetget
    properties (Constant = true)
        DefaultXml = 'HED.xml';
%         DefaultSchema = 'HED.xsd';
    end % constant
    
    properties (Access = private)
        Description          % String describing this field map
        GroupMap             % Map for matching event labels
        PreserveTagPrefixes       % If true, don't eliminate duplicate
        % prefixes (default false)
        PrimaryField
        Xml                  % Tag hierarchy as an XML string
        XmlEdited            % If true, the HED has been modified through
        % the CTagger (default false)
%         XmlSchema            % String containing the XML schema
    end % private properties
    
    methods
        function obj = fieldMap(varargin)
            % Constructor parses parameters and sets up initial data
            p = fieldMap.parseArguments(varargin{:});
            obj.Description = p.Description;
            obj.PreserveTagPrefixes = p.PreserveTagPrefixes;
            obj.Xml = p.Xml;
%             obj.XmlSchema = p.XmlSchema;
            obj.GroupMap = containers.Map('KeyType', 'char', ...
                'ValueType', 'any');
        end % fieldMap constructor
        
        function addValues(obj, type, values, varargin)
            % Add values (structure or cell format) to tagMap for type
            p = inputParser;
            p.addRequired('Type', @(x) (~isempty(x) && ischar(x)));
            p.addRequired('Values', ...
                @(x) (isempty(x) || isstruct(x) || isa(x, 'tagList')));
            p.addParamValue('Primary', false, ...
                @(x) validateattributes(x, {'logical'}, {}));
            p.addParamValue('UpdateType', 'merge', ...
                @(x) any(validatestring(lower(x), ...
                {'update', 'replace', 'merge', 'none'})));
            p.parse(type, values, varargin{:});
            primary = p.Results.Primary;
            type = p.Results.Type;
            if ~obj.GroupMap.isKey(type)
                eTag = tagMap('Field', type, 'Primary', primary);
            else
                eTag = obj.GroupMap(type);
            end
            if primary
                obj.PrimaryField = type;
            end
            if iscell(values)
                for k = 1:length(values)
                    eTag.addValue(values{k}, ...
                        'UpdateType', p.Results.UpdateType, ...
                        'PreserveTagPrefixes', obj.PreserveTagPrefixes);
                end
            else
                for k = 1:length(values)
                    eTag.addValue(values(k), ...
                        'UpdateType', p.Results.UpdateType, ...
                        'PreserveTagPrefixes', obj.PreserveTagPrefixes);
                end
            end
            obj.GroupMap(type) = eTag;
        end % addValues
        
        function newMap = clone(obj)
            % Create a copy (newMap) of the fieldMap
            newMap = fieldMap();
            newMap.Description = obj.Description;
            newMap.PreserveTagPrefixes = obj.PreserveTagPrefixes;
            newMap.Xml = obj.Xml;
%             newMap.XmlSchema = obj.XmlSchema;
            values = obj.GroupMap.values;
            tMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for k = 1:length(values)
                tMap(values{k}.getField()) = values{k};
            end
            newMap.GroupMap = tMap;
        end % clone
        
        function description = getDescription(obj)
            % Return a string describing the purpose of the fieldMap
            description = obj.Description;
        end % getDescription
        
        function fields = getFields(obj)
            % Return the field names of the fieldMap
            fields = obj.GroupMap.keys();
        end % getFields
        
        function jString = getJson(obj)
            % Return a JSON string version of the fieldMap
            jString = savejson('', obj.getStruct());
        end % getJson
        
        function jString = getJsonValues(obj)
            % Return a JSON string representation of the tag maps
            jString = tagMap.values2Json(obj.GroupMap.values);
        end % getJsonValues
        
        function tMap = getMap(obj, field)
            % Return a tagMap object associated field name
            if ~obj.GroupMap.isKey(field)
                tMap = '';
            else
                tMap = obj.GroupMap(field);
            end
        end % getMap
        
        function tMaps = getMaps(obj)
            % Return the tagMap objects as a cell array
            tMaps = obj.GroupMap.values;
        end % getMaps
        
        function pPrefix = getPreserveTagPrefixes(obj)
            % Return the logical PreserveTagPrefixes flag of the fieldMap
            pPrefix = obj.PreserveTagPrefixes;
        end % getPreservePrefix
        
        function primaryField = getPrimaryField(obj)
            % Return the primary field of the fieldMap
            primaryField = obj.PrimaryField;
        end % getFields
        
        function thisStruct = getStruct(obj)
            % Return the fieldMap as a structure array
            thisStruct = struct('description', obj.Description, ...
                'xml', obj.Xml, 'map', '');
            types = obj.GroupMap.keys();
            if isempty(types)
                return;
            end
            events = struct('field', types, 'values', '');
            for k = 1:length(types)
                eTags = obj.GroupMap(types{k});
                events(k).values = eTags.getValueStruct();
            end
            thisStruct.map = events;
        end % getStruct
        
        function tags = getTags(obj, field, value)
            % Return the tag string associated with value event of field
            tags = '';
            try
                tMap = obj.GroupMap(field);
                codes = tMap.getCodes();
                if any(strcmp('HED',codes)) && ~strcmp(lower(value), 'n/a')
                    eStruct = tMap.getValue('HED');
                    tags = eStruct.getTags();
                    if iscell(tags(1))
                        for c=1:numel(tags)
                            tags{c} = strrep(tags{c},'#',value);
                        end
                    else
                        tags = strrep(tags,'#',value);
                    end
                else
                    eStruct = tMap.getValue(value);
                    tags = eStruct.getTags();
                end
            catch me %#ok<NASGU>
            end
        end % getTags
        
        function value = getValue(obj, type, key)
            % Return the value structure corresponding to specified field
            % and key
            value = '';
            if obj.GroupMap.isKey(type)
                value = obj.GroupMap(type).getValue(key);
            end
        end % getValue
        
        function values = getValues(obj, type)
            % Return the values for field as a cell array of structures
            if obj.GroupMap.isKey(type)
                values = obj.GroupMap(type).getValues();
            else
                values = '';
            end
        end % getValues
        
        function xml = getXml(obj)
            % Return a string containing the xml of the fieldMap
            xml = obj.Xml;
        end % getXml
        
        function xmlEdited = getXmlEdited(obj)
            % Returns true if the XML was edited through the CTagger
            xmlEdited = obj.XmlEdited;
        end % getXmlEdited
        
        function result = isField(obj, field)
            result = ~isempty(field) && obj.GroupMap.isKey(field);
        end
        
        function result = isEmpty(obj)
            % Check if the fieldMap is empty (no fields or none of the
            % fields has tagMap)
            fields = obj.getFields();
            if isempty(fields)
                result = 0;
            else
                fMapStruct = obj.getStruct();
                if all(arrayfun(@(field) isempty(fMapStruct.map(field)), 1:length(fields)))
                    result = 0;
                else
                    result = 1;
                end
            end
        end
        
        function result = hasAnnotation(obj)
            % Check if the fieldMap has annotation
            result = ~isEmpty(obj); % if empty then don't have annotation
            if ~result
                fields = obj.getFields();
                for f=1:numel(fields)
                    if obj.getMap(fields{f}).hasAnnotation()
                        result = 1;
                        return
                    end
                end
            end % hasAnnotation
        end
        
        function merge(obj, fMap, updateType, excludeFields, includeFields)
            % Combine another fieldMap with this object based on update
            % type
            if isempty(fMap)
                return;
            end
            fields = fMap.getFields();
            fields = setdiff(fields, excludeFields);
            if ~isempty(includeFields)
                fields = intersect(fields, includeFields);
            end
            for k = 1:length(fields)
                type = fields{k};
                tMap = fMap.getMap(type);
                if ~obj.GroupMap.isKey(type)
                    obj.GroupMap(type) = tMap; %tagMap('Field', type);
                end
                myMap = obj.GroupMap(type);
                myMap.merge(tMap, updateType, obj.PreserveTagPrefixes)
                obj.GroupMap(type) = myMap;
            end
        end % merge
        
        function removeMap(obj, field)
            % Remove the tag map associated with specified field name
            if ~isempty(field) && obj.GroupMap.isKey(field)
                obj.GroupMap.remove(field);
            end
        end % removeMap
        
        function setPrimaryMap(obj, field)
            % Sets the tag map associated with specified field name as a
            % primary field
            if ~isempty(field) && obj.GroupMap.isKey(field)
                tMap = getMap(obj, field);
                setPrimary(tMap, true);
                obj.GroupMap.remove(field);
                obj.GroupMap(field) = tMap;
            end
        end % setPrimaryMap
        
        function setDescription(obj, description)
            % Set the description of the fieldMap
            obj.Description = description;
        end % setDescription
        
        function xml = setXml(obj, xml)
            % Set the XML of the fieldMap
            obj.Xml = xml;
        end % setXml
        
        function xmlEdited = setXmlEdited(obj, xmlEdited)
            % Set the XML of the fieldMap
            obj.XmlEdited = xmlEdited;
        end % setXmlEdited
        
        function clearTagsInFields(obj, fields)
            % clear all the tags in the given fields
            for f=1:numel(fields)
                type = fields{f};
                if obj.GroupMap.isKey(type)
                    obj.GroupMap(type) = obj.GroupMap(type).clearTags();
                end
            end
        end % clearTagsInFields
    end % public methods
    
    methods (Static = true)
        function fMap = createfMapFromStruct(structfMap)
            % Create a fieldmap from its struct form
            fMap = fieldMap('Description', structfMap.description, 'XML', structfMap.xml);
            map = structfMap.map;
            fields = {map.field};
            for i=1:numel(fields)
                fMap.addValues(fields{i},map(i).values);
            end
        end
        
        function fMap = createfMapFromJson(jsonFile)
            % Create a fieldMap from the json sidecar, complying with BIDS
            % events.json HED annotation
            
            % parse file
            if ~endsWith(jsonFile,'.json')
                error('Not a json file');
            end
            try
                json = fileread(jsonFile);
            catch
                error('Error reading json file %s', jsonFile);
            end
            % construct fMapStruct from json
            jsonStruct = jsondecode(json);
            fields = fieldnames(jsonStruct);

            fMapStruct.description = 'fieldMap generated from json file';
            fMapStruct.xml = 'HEDLatest.xml';
            maps = [];
            for i=1:numel(fields)
                map = [];
                map.field = fields{i};
                if ~isfield(jsonStruct.(fields{i}), 'HED') && ~isfield(jsonStruct.(fields{i}), 'Levels')
                    map.values.code = 'HED';
                    map.values.tags = {};
                else
                    tagmaps = [];
                    if isfield(jsonStruct.(fields{i}), 'Levels')
                        levels = fieldnames(jsonStruct.(fields{i}).Levels);
                        for l=1:numel(levels)
                            tagmap = [];
                            tagmap.code = levels{l};
                            if isfield(jsonStruct.(fields{i}), 'HED') && isfield(jsonStruct.(fields{i}).HED, levels{l})
                                tagmap.tags = tagList.deStringify(jsonStruct.(fields{i}).HED.(levels{l}));
                            else
                                tagmap.tags = {};
                            end
                            tagmaps = [tagmaps tagmap];
                        end
                    else % don't have Levels but have HED
                        if isstruct(jsonStruct.(fields{i}).HED)
                            levels = fieldnames(jsonStruct.(fields{i}).HED);
                            for l=1:numel(levels)
                                tagmap = [];
                                tagmap.code = levels{l};
                                tagmap.tags = tagList.deStringify(jsonStruct.(fields{i}).HED.(levels{l}));
                                tagmaps = [tagmaps tagmap];
                            end
                        else
                            tagmaps.code = 'HED';
                            tagmaps.tags = tagList.deStringify(jsonStruct.(fields{i}).HED);
                        end
                    end
                    map.values = tagmaps;
                end 
                maps = [maps map];
            end
            fMapStruct.map = maps;
            
            % create fMap from fMapStruct
            fMap = fieldMap.createfMapFromStruct(fMapStruct);
        end % createfMapFromJson
        
        function json = createJsonFromFieldMap(fMap)
            fieldnames = fMap.getFields();
            result = [];
            for i=1:numel(fieldnames)
               field = fieldnames{i};
               result.(field).HED = containers.Map;
               values = fMap.getValues(field);
               for v=1:numel(values)
                   code = values{v}.getCode();
    %                if ~isempty(str2num(code))
    %                    code = ['x' code];
    %                end
                   if ~isempty(values{v}.getTags())
                       if strcmp(code,'HED')
                           result.(field).HED = tagList.stringify(values{v}.getTags());
                       else
                           result.(field).HED(code) = tagList.stringify(values{v}.getTags());
                       end
                   else
                       result.(field).HED(code) = "";
                   end
               end
            end
            json = jsonencode(result);
%             json = strrep(json, '"',"'");
        end % createJsonFromFieldMap
        
        function baseTags = loadFieldMap(tagsFile)
            % Load a field map from a .mat file that contains a fieldMap
            % object.
            baseTags = '';
            try
                t = load(tagsFile);
                tFields = fieldnames(t);
                for k = 1:length(tFields)
                    nextField = t.(tFields{k});
                    if isa(nextField, 'fieldMap')
                        baseTags = nextField;
                        return;
                    end
                end
            catch ME         %#ok<NASGU>
            end
        end % loadFieldMap
        
        function successful = saveFieldMap(tagsFile, ...
                tagsObject) %#ok<INUSD>
            % Save a field map to a .mat file
            successful = true;
            try
                save(tagsFile, 'tagsObject');
            catch ME         %#ok<NASGU>
                successful = false;
            end
        end % saveFieldMap
        
        function p = parseArguments(varargin)
            % Parses the input arguments and returns the results
            parser = inputParser;
            parser.addParamValue('Description', '', @ischar);
            parser.addParamValue('PreserveTagPrefixes', true, ... %false, ... % HACK for CNS 2023
                @(x) validateattributes(x, {'logical'}, {}));
            parser.addParamValue('Xml', fileread(fieldMap.DefaultXml), ...
                @(x) (ischar(x)));
%             parser.addParamValue('XmlSchema', ...
%                 fileread(fieldMap.DefaultSchema), @ischar);
            parser.parse(varargin{:})
            p = parser.Results;
        end % parseArguments
        
    end % static methods
    
end % fieldMap