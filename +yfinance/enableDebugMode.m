function currentConfig = enableDebugMode()
%ENABLEDEBUGMODE Enable verbose request logging for subsequently created sessions.

currentConfig = yfinance.setConfig(DebugLogging=true);
end
