function [EEG,tags] = removeTagsEEG(EEG)
    fprintf('Clearing EEG tags... ');
    tags = '';
    if isfield(EEG.etc, 'HED')
        tags = EEG.etc.HED;
        EEG.etc = rmfield(EEG.etc, 'HED');
    end

end % removeTagsEEG