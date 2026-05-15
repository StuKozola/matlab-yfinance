function name = pascalFieldName(name)
%PASCALFIELDNAME Convert a Yahoo field name to a valid PascalCase name.

arguments
    name (1,1) string
end

name = matlab.lang.makeValidName(name);
name = upper(extractBetween(name, 1, 1)) + extractAfter(name, 1);
name = char(name);
end
