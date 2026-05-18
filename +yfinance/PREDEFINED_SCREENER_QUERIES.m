% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function definitions = PREDEFINED_SCREENER_QUERIES()
%PREDEFINED_SCREENER_QUERIES Return upstream-style predefined screener definitions.

definitions = yfinance.internal.predefinedScreenerQueryDefinitions();
end
