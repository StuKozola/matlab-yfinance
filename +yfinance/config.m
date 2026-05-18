% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function currentConfig = config()
%CONFIG Return process-local matlab-yfinance configuration.

currentConfig = yfinance.internal.configStore();
end
