function value = configValue(name)
%CONFIGVALUE Return one normalized value from the global configuration.

arguments
    name (1,1) string {mustBeNonzeroLengthText}
end

config = yfinance.internal.configStore();

switch name
    case "Timeout"
        value = config.session.timeout;
    case "UserAgent"
        value = config.session.userAgent;
    case "MaxRetries"
        value = config.network.retries;
    case "RetryDelay"
        value = config.session.retryDelay;
    case "UseCredentials"
        value = config.session.useCredentials;
    case "DebugMode"
        value = config.debug.logging;
    otherwise
        error("yfinance:InvalidConfigKey", "Unsupported configuration key '%s'.", name);
end
end
