% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function currentConfig = enableDebugMode()
%ENABLEDEBUGMODE Enable verbose request logging for subsequently created sessions.

currentConfig = yfinance.setConfig(DebugLogging=true);
end
