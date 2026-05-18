function config = configStore(options)
%CONFIGSTORE Read, update, or reset process-local yfinance configuration.

arguments
    options.Update struct = struct()
    options.Reset (1,1) logical = false
end

persistent state

if isempty(state) || options.Reset
    state = yfinance.internal.configDefaults();
end

if ~isempty(fieldnames(options.Update))
    state = mergeStructs(state, options.Update);
end

config = state;
end

function output = mergeStructs(output, updates)
fields = fieldnames(updates);

for fieldIndex = 1:numel(fields)
    fieldName = fields{fieldIndex};
    value = updates.(fieldName);

    if isstruct(value) && isscalar(value) && isfield(output, fieldName) && ...
            isstruct(output.(fieldName)) && isscalar(output.(fieldName))
        output.(fieldName) = mergeStructs(output.(fieldName), value);
    else
        output.(fieldName) = value;
    end
end
end
