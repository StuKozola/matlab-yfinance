% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = marketSummaryResponseToTable(response, options)
%MARKETSUMMARYRESPONSETOTABLE Convert Yahoo market summary data.

arguments
    response struct
    options.Market (1,1) string = ""
end

if ~isfield(response, "marketSummaryResponse") || isempty(response.marketSummaryResponse)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain market summary data.");
end

payload = response.marketSummaryResponse;

if isfield(payload, "error") && ~isempty(payload.error)
    error("yfinance:YahooError", "Yahoo Finance returned a market summary error for %s.", options.Market);
end

if ~isfield(payload, "result") || isempty(payload.result)
    data = table();
    data.Properties.UserData = struct("Market", options.Market);
    return
end

data = yfinance.internal.yahooStructArrayToTable(payload.result);
data.Properties.UserData = struct("Market", options.Market);
end
