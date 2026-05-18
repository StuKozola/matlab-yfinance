% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function message = streamControlMessage(action, symbols)
%STREAMCONTROLMESSAGE Build Yahoo live stream control JSON.

arguments
    action (1,1) string {mustBeMember(action, ["subscribe", "unsubscribe"])}
    symbols
end

symbols = yfinance.internal.normalizeSymbols(symbols);

if isempty(symbols)
    error("yfinance:InvalidSymbol", "At least one ticker symbol must be provided.");
end

payload = struct();
payload.(action) = cellstr(symbols(:).');
message = string(jsonencode(payload));
end
