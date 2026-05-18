% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = pricingDataToLiveQuotes(messages)
%PRICINGDATATOLIVEQUOTES Convert decoded PricingData structs to a table.

if isempty(messages)
    data = table();
    data.Properties.UserData = struct("Symbols", strings(0, 1));
    return
end

messages = messages(:);
data = struct2table(messages);
symbols = strings(0, 1);

if ismember("Symbol", string(data.Properties.VariableNames))
    symbols = string(data.Symbol);
    symbols = symbols(~ismissing(symbols) & strlength(symbols) > 0);
end

data.Properties.UserData = struct("Symbols", symbols(:));
end
