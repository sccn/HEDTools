function [EEG, results] = eventsToLong(EEG)
    [servicesUrl, options] = getHedWebSettings();
    writeeventstsv(EEG, 'events.tsv');
    spreadsheetText = fileread('events.tsv');
    delete('events.tsv');
    % get HED column
    hed_index = find(strcmpi(fieldnames(EEG.event), 'HED')); % assumes only one column name HED
    request = struct('service', 'spreadsheet_to_long', ...
                  'schema_version', '8.0.0',...
                  'spreadsheet_string', spreadsheetText, ...
                  'expand_defs', 'on', ...
                  'has_column_names', 'on', ...
                  ['column_' num2str(hed_index) '_input'], '', ...
                  ['column_' num2str(hed_index) '_check'], 'on');
              % 'schema_version', schemaText, ...
    response = webwrite(servicesUrl, request, options);
    response = jsondecode(response);
    outputReport(response, 'Convert events annotation to long form');
    results = response.results;
    fid = fopen('events_long.tsv','w');
    fprintf(fid, results.spreadsheet);
    fclose(fid);
    EEG = importeventstsv(EEG, 'events_long.tsv');
end