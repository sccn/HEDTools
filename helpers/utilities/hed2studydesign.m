function alldes = hed2studydesign(fMap)
    % get fMap
    if ischar(fMap) && endsWith(fMap,'events.json')
        % expand Def option for events.json
        
        fMap = fieldMap.createfMapFromJson(fMap);
    end
    
    designs = []; % struct array
    % designs(1).cond : factor name
    % designs(1).var : column field associated with this factor
    % designs(1).values: struct array
    % designs(1).values(1).code: column value associated with this factor level
    % designs(1).values(1).name: factor level name
    % designs(1).values(1).HED: factor level associated HED string
    %   
    % get experiment control variables and their values
    fields = fMap.getFields();
    for f=1:length(fields)
        field = fields{f};
        tMap = fMap.getMap(field);
        values = tMap.getCodes();
        for val=1:numel(values)
            value = values{val};
            tList = tMap.getValue(value);
            tags = jsonencode(tList.getTags());
            % get experiment condition values
            if contains(tags, 'Condition-variable')
                [condName, valueName] = getCondValueName(tags);
                
                valueStruct = [];
                valueStruct.code = value;
                valueStruct.name = valueName;
                valueStruct.HED = tags; 
                
                if isempty(designs) || (~isempty(designs) && ~any(strcmp({designs.cond}, condName)))
                    design = [];
                    design.cond = condName;
                    design.var = tMap.getField();
                    design.values = [];
                    design.values = [design.values valueStruct];
                    designs = [designs design];
                else
                    currdesigns = {designs.cond};
                    design = designs(strcmp(currdesigns, condName));
                    design.values = [design.values valueStruct];
                    designs(strcmp(currdesigns, condName)) = design;
                end       
            end
        end
        
    end
    
    % reformat to conform with EEGLAB STUDY design format
    alldes = [];
    for i=1:numel(designs)
        des = [];
        design = designs(i);
        des.name = design.cond;
        des.filepath = '';
        des.variable = [];
        des.variable.label = design.var;
        des.variable.value = {design.values.code};
        des.variable.vartype = 'categorical';
        des.variable.paring = 'on';
        levels = {'one', 'two', 'three'};
        des.variable.level = levels{i};
        des.cases.label = 'subject'; % TODO
        des.cases.value = {1,2,3,4,5}; % TODO
        des.include = {};
        alldes = [alldes des];
    end
        
    function [cond_name, cond_value_name] = getCondValueName(hed)
        % detect Definition name
        hed_rpl = strrep(hed,'(','');
        hed_rpl = strrep(hed_rpl,')','');
        hed_rpl = strrep(hed_rpl,']','');
        hed_rpl = strrep(hed_rpl,'[','');
        hed_rpl = strrep(hed_rpl,'"','');
        hed_splitted = strsplit(hed_rpl, ',');
        % Def tag immediately precedes Experiment-condition tag
        exp_cond_idx = find(contains(hed_splitted, 'Condition-variable'));
        cond_name = strsplit(hed_splitted{exp_cond_idx}, '/');
        cond_name = cond_name{2};
        
        cond_value_name = strsplit(hed_splitted{exp_cond_idx-1}, '/');
        % value name is after /
        cond_value_name = cond_value_name{2};
    end
end