% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function response = httpTextRequest(url, options)
%HTTPTEXTREQUEST Read a text URL and expose response cookies.

arguments
    url (1,1) string {mustBeNonzeroLengthText}
    options.Timeout (1,1) double {mustBePositive} = 30
    options.UserAgent (1,1) string = yfinance.internal.defaultUserAgent()
    options.CookieHeader (1,1) string = ""
end

import matlab.net.URI
import matlab.net.http.HTTPOptions
import matlab.net.http.RequestMessage
import matlab.net.http.RequestMethod
import matlab.net.http.field.GenericField

headers = GenericField("User-Agent", char(options.UserAgent));

if options.CookieHeader ~= ""
    headers = [headers, GenericField("Cookie", char(options.CookieHeader))];
end

request = RequestMessage(RequestMethod.GET, headers);
httpOptions = HTTPOptions( ...
    ConnectTimeout=options.Timeout, ...
    ResponseTimeout=options.Timeout, ...
    ConvertResponse=false);
message = request.send(URI(char(url)), httpOptions);

response = struct( ...
    "StatusCode", double(message.StatusCode), ...
    "Body", responseBodyText(message.Body.Data), ...
    "CookieHeader", responseCookieHeader(message));
end

function text = responseBodyText(data)
if isempty(data)
    text = "";
elseif isstring(data)
    text = strjoin(data, newline);
elseif ischar(data)
    text = string(data);
elseif isnumeric(data) || islogical(data)
    text = native2unicode(uint8(data(:).'), "UTF-8");
    text = string(text);
else
    text = string(data);
end
end

function cookieHeader = responseCookieHeader(message)
fields = message.getFields("Set-Cookie");
cookieHeader = strings(0, 1);

for fieldIndex = 1:numel(fields)
    fieldText = string(char(fields(fieldIndex)));
    colonIndex = strfind(fieldText, ":");

    if isempty(colonIndex)
        cookieText = fieldText;
    else
        cookieText = extractAfter(fieldText, colonIndex(1));
    end

    cookieText = strtrim(cookieText);
    semicolonIndex = strfind(cookieText, ";");

    if ~isempty(semicolonIndex)
        cookieText = extractBefore(cookieText, semicolonIndex(1));
    end

    if cookieText ~= ""
        cookieHeader(end + 1, 1) = cookieText; %#ok<AGROW>
    end
end

cookieHeader = strjoin(cookieHeader, "; ");
end
