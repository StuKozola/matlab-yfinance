% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function queries = predefinedScreenerQueries()
%PREDEFINEDSCREENERQUERIES Return predefined Yahoo Finance screener query names.

queries = yfinance.internal.predefinedScreenerQueryNames();
end
