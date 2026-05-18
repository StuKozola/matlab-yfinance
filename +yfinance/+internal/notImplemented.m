% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function notImplemented(apiName, detail)
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
end
