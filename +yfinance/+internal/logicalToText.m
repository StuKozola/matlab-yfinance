% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function value = logicalToText(flag)
%LOGICALTOTEXT Convert a scalar logical to Yahoo query text.

arguments
    flag (1,1) logical
end

if flag
    value = "true";
else
    value = "false";
end
end
