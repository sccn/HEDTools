function [STUDY,EEG,tags] = removeTagsSTUDY(STUDY,EEG)
    fprintf('Clearing STUDY tags... \n');
    tags = '';
    if isfield(STUDY.etc, 'HED')
        tags = STUDY.etc.HED;
        STUDY.etc = rmfield(STUDY.etc, 'HED');
    end
    for i=1:length(EEG)
        EEGTemp = EEG(i);
        [EEGTemp, ~] = removeTagsEEG(EEGTemp);
        EEG(i) = EEGTemp;
        pop_saveset(EEG(i), 'filename', EEG(i).filename, 'filepath', EEG(i).filepath); 
    end    
    fprintf('Done.\n')    
end % removeTagsSTUDY