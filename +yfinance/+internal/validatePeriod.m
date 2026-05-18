% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function validatePeriod(period)
%VALIDATEPERIOD Validate a Yahoo chart range value.

validPeriods = ["1d", "5d", "1mo", "3mo", "6mo", "1y", "2y", "5y", "10y", "ytd", "max"];

if ~ismember(period, validPeriods)
    error( ...
        "yfinance:InvalidPeriod", ...
        "Period must be one of: %s.", ...
        strjoin(validPeriods, ", "));
end
end
