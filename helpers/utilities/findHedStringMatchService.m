function matchIndices = findHedStringMatchService(EEG, query)
    % get events.json
    fMap = fieldMap.createfMapFromStruct(EEG.etc.tags);
%     jsonText = fieldMap.createJsonFromFieldMap(fMap);
    jsonText = fileread('/Users/dtyoung/Documents/HED/datasets/sternberg/task-WorkingMemory_events.json'); % Temporary for book chapter
    % get events.tsv
    eventsText = writeeventstsv(EEG, '');
    
    % pass them both the HED service
    [servicesUrl, options] = getHedWebSettings();
    request1 = struct('service', 'events_search', ...
                  'schema_version', '8.0.0', ...
                  'json_string', jsonText, ...
                  'events_string', eventsText, ...
                  'query', query);
    
    response1 = webwrite(servicesUrl, request1, options);
    response1 = jsondecode(response1);
    outputReport(response1, 'Example 1 Querying an events file');
    
    % TODO check for error
    fid = fopen('search_results.tsv','w');
    fprintf(fid, response1.results.data);
    fclose(fid);
    
    results_table = loadtxt('search_results.tsv');
    idx_col = results_table(:,1);
    valid_idx = cellfun(@isnumeric, idx_col);
    matchIndices = cellfun(@(x) x+1, idx_col(valid_idx));
    
    delete('search_results.tsv');
end