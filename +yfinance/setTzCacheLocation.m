% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function currentConfig = setTzCacheLocation(location)
%SETTZCACHELOCATION Store an upstream-compatible timezone cache location.

arguments
    location (1,1) string
end

currentConfig = yfinance.setConfig(TimeZoneCacheLocation=location);
end
