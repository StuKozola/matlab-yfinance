% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = decodeStreamFrame(frame)
%DECODESTREAMFRAME Decode one Yahoo stream JSON frame.

if isstring(frame) || ischar(frame)
    try
        frame = jsondecode(char(frame));
    catch exception
        error("yfinance:InvalidStreamFrame", "Unable to decode Yahoo stream JSON frame. %s", exception.message);
    end
end

if ~isstruct(frame) || ~isfield(frame, "message") || isempty(frame.message)
    error("yfinance:InvalidStreamFrame", "Yahoo stream frame does not contain a PricingData message.");
end

data = yfinance.internal.live.decodePricingDataMessage(string(frame.message));
end
