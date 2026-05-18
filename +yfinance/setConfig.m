% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function currentConfig = setConfig(options)
%SETCONFIG Update process-local matlab-yfinance configuration.

arguments
    options.Proxy = []
    options.Retries = []
    options.Timeout = []
    options.UserAgent = []
    options.RetryDelay = []
    options.UseCredentials = []
    options.DebugLogging = []
    options.HideExceptions = []
    options.TimeZoneCacheLocation = []
end

updates = yfinance.internal.configUpdatesFromOptions(options);
currentConfig = yfinance.internal.configStore(Update=updates);
end
