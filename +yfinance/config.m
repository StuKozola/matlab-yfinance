function currentConfig = config()
%CONFIG Return process-local matlab-yfinance configuration.

currentConfig = yfinance.internal.configStore();
end
