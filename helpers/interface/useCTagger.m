function [tags, canceled] = useCTagger(tags)
    json = jsonencode(tags);

    % start CTagger
    [new_tags, canceled] = loadCTagger(json);
    
    % merge result
    if ~canceled
        tags = mergeStructures(tags, new_tags);
    end
    
    
    function [result, canceled] = loadCTagger(json)
       canceled = false;
       notified = false;
        loader = javaObject('TaggerLoader', json);
        while (~notified)
            pause(0.5);
            notified = loader.isNotified();
        end
        if loader.isCanceled()
            canceled = true;
            result = [];
        else
            result = jsondecode(char(loader.getHEDJson()));
        end
    end
end