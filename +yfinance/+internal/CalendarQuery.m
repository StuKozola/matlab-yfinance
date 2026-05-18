% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef CalendarQuery
    %CALENDARQUERY Build Yahoo Finance calendar visualization filters.

    properties (SetAccess = private)
        Operator (1,1) string
        Operands (1,:) cell
    end

    methods
        function obj = CalendarQuery(operator, operands)
            arguments
                operator (1,1) string {mustBeNonzeroLengthText}
                operands (1,:) cell = {}
            end

            obj.Operator = lower(strtrim(operator));
            obj.Operands = normalizeOperands(operands);
        end

        function value = toStruct(obj)
            %TOSTRUCT Convert the query object to Yahoo's JSON-ready schema.
            operands = obj.Operands;

            for operandIndex = 1:numel(operands)
                if isa(operands{operandIndex}, "yfinance.internal.CalendarQuery")
                    operands{operandIndex} = operands{operandIndex}.toStruct();
                end
            end

            value = struct( ...
                "operator", obj.Operator, ...
                "operands", {operands});
        end

        function value = isEmpty(obj)
            %ISEMPTY True when the query has no operands.
            value = isempty(obj.Operands);
        end
    end
end

function operands = normalizeOperands(operands)
for operandIndex = 1:numel(operands)
    if ischar(operands{operandIndex})
        operands{operandIndex} = string(operands{operandIndex});
    end
end
end
