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
