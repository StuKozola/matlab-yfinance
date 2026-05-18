% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function currentConfig = enable_debug_mode()
%ENABLE_DEBUG_MODE Enable verbose request logging for subsequently created sessions.

currentConfig = yfinance.enableDebugMode();
end
