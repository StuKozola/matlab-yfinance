% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function currentConfig = set_tz_cache_location(location)
%SET_TZ_CACHE_LOCATION Store an upstream-compatible timezone cache location.

arguments
    location (1,1) string
end

currentConfig = yfinance.setTzCacheLocation(location);
end
