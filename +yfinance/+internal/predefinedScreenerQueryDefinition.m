% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function [definition, isKnown] = predefinedScreenerQueryDefinition(queryName)
%PREDEFINEDSCREENERQUERYDEFINITION Look up one predefined screener definition.

arguments
    queryName (1,1) string {mustBeNonzeroLengthText}
end

queryName = lower(strtrim(queryName));
definitions = yfinance.internal.predefinedScreenerQueryDefinitions();
isKnown = isfield(definitions, char(queryName));

if isKnown
    definition = definitions.(queryName);
else
    definition = struct();
end
end
