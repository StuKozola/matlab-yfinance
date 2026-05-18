% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function symbols = normalizeSymbols(symbols)
%NORMALIZESYMBOLS Convert user ticker input to normalized string symbols.

arguments
    symbols {mustBeText}
end

symbols = string(symbols);
symbols = symbols(:);
symbols = upper(strtrim(symbols));
symbols(symbols == "") = [];
end
