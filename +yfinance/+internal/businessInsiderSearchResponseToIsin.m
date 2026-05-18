% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function isin = businessInsiderSearchResponseToIsin(text, options)
%BUSINESSINSIDERSEARCHRESPONSETOISIN Extract an ISIN from search suggestions.

arguments
    text (1,1) string
    options.Symbol (1,1) string = ""
    options.Query (1,1) string = ""
end

symbol = upper(strtrim(options.Symbol));
text = string(text);

if text == ""
    isin = "-";
    return
end

tokens = regexp(char(text), ['"' regexptranslate("escape", char(symbol)) '\|([A-Z]{2}[A-Z0-9]{9}[0-9])\|'], ...
    "tokens", "once");

if isempty(tokens) && options.Query ~= "" && contains(lower(text), lower(options.Query))
    tokens = regexp(char(text), '"\|([A-Z]{2}[A-Z0-9]{9}[0-9])\|', "tokens", "once");
end

if isempty(tokens)
    isin = "-";
else
    isin = string(tokens{1});
end
end
