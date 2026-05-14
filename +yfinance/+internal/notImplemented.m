function output = notImplemented(apiName, detail)
%NOTIMPLEMENTED Raise a consistent not-implemented error.

arguments
    apiName (1,1) string
    detail (1,1) string = ""
end

if detail == ""
    message = apiName + " is not implemented yet.";
else
    message = apiName + " is not implemented yet for " + detail + ".";
end

error("yfinance:NotImplemented", "%s", message);

output = [];
end

