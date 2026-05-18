% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function modules = normalizeModules(modules)
%NORMALIZEMODULES Normalize Yahoo quoteSummary module names.

arguments
    modules {mustBeText}
end

modules = string(modules);
modules = strtrim(modules(:).');
modules(modules == "") = [];
modules = unique(modules, "stable");

if isempty(modules)
    error("yfinance:InvalidModule", "At least one quoteSummary module must be provided.");
end
end
