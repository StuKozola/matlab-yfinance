function updates = configUpdatesFromOptions(options)
%CONFIGUPDATESFROMOPTIONS Convert public config options to nested updates.

updates = struct();

if hasOption(options.Proxy)
    updates.network.proxy = string(options.Proxy);
end

if hasOption(options.Retries)
    validateattributes(options.Retries, {'numeric'}, {'scalar', 'nonnegative', 'integer'});
    updates.network.retries = double(options.Retries);
end

if hasOption(options.Timeout)
    validateattributes(options.Timeout, {'numeric'}, {'scalar', 'positive'});
    updates.session.timeout = double(options.Timeout);
end

if hasOption(options.UserAgent)
    updates.session.userAgent = string(options.UserAgent);
end

if hasOption(options.RetryDelay)
    validateattributes(options.RetryDelay, {'numeric'}, {'scalar', 'nonnegative'});
    updates.session.retryDelay = double(options.RetryDelay);
end

if hasOption(options.UseCredentials)
    updates.session.useCredentials = logical(options.UseCredentials);
end

if hasOption(options.DebugLogging)
    updates.debug.logging = logical(options.DebugLogging);
end

if hasOption(options.HideExceptions)
    updates.debug.hide_exceptions = logical(options.HideExceptions);
end

if hasOption(options.TimeZoneCacheLocation)
    updates.timezoneCacheLocation = string(options.TimeZoneCacheLocation);
end
end

function value = hasOption(value)
value = ~(isempty(value) && ~(isstring(value) && isscalar(value)));
end
