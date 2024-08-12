function hasHED = checkHedObject()
global hed
hasHED = false;
if isobject(hed) && isprop(hed, 'HedVersion')
    hasHED = true;
    if isprop(hed, 'ServicesUrl')
        request = hed.getRequestTemplate();
        request.service = 'get_services';
        response = webwrite(hed.ServicesUrl, request, hed.WebOptions);
        response = jsondecode(response);
        error_msg = HedToolsService.getResponseError(response);
        if error_msg
            try
                hed = getHedTools('8.3.0', 'https://hedtools.org/hed');
            catch
                hasHED = false;
            end
        end
    end
end
if ~hasHED
    error('HED service not initialized. Please try re-initializing the HEDTools plug-in first.');
end