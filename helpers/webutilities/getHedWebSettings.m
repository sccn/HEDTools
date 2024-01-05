function [servicesUrl, options] = getHedWebSettings()
host = 'https://hedtools.ucsd.edu/hed';
csrfUrl = [host '/services']; 
servicesUrl = [host '/services_submit'];
[cookie, csrftoken] = getSessionInfo(csrfUrl);
header = ["Content-Type" "application/json"; ...
          "Accept" "application/json"; ...
          "X-CSRFToken" csrftoken; "Cookie" cookie];

options = weboptions('MediaType', 'application/json', 'Timeout', 120, ...
                     'HeaderFields', header);