% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef ScreenerQuery
    %SCREENERQUERY Base object for Yahoo Finance custom screener queries.

    properties (Constant)
        ValidOperators (1,:) string = ["EQ", "IS-IN", "BTWN", "GT", "LT", "GTE", "LTE", "AND", "OR"]
    end

    properties (SetAccess = protected)
        Operator (1,1) string
        Operands (1,:) cell
        QuoteType (1,1) string
    end

    methods
        function obj = ScreenerQuery(operator, operands, quoteType)
            arguments
                operator (1,1) string {mustBeNonzeroLengthText}
                operands (1,:) cell
                quoteType (1,1) string {mustBeNonzeroLengthText}
            end

            obj.Operator = upper(strtrim(operator));
            obj.Operands = normalizeOperands(operands);
            obj.QuoteType = upper(strtrim(quoteType));
            obj.validate();
        end

        function value = toStruct(obj)
            %TOSTRUCT Convert the query object to Yahoo's JSON-ready schema.
            operator = obj.Operator;
            operands = obj.Operands;

            if operator == "IS-IN"
                operator = "OR";
                operands = cell(1, numel(obj.Operands) - 1);

                for operandIndex = 2:numel(obj.Operands)
                    operands{operandIndex - 1} = struct( ...
                        "operator", "EQ", ...
                        "operands", {{obj.Operands{1}, obj.Operands{operandIndex}}});
                end
            else
                operands = obj.structOperands(operands);
            end

            value = struct( ...
                "operator", operator, ...
                "operands", {operands});
        end

        function text = string(obj)
            text = obj.formatQuery();
        end

        function text = char(obj)
            text = char(string(obj));
        end
    end

    methods (Access = private)
        function validate(obj)
            if ~ismember(obj.Operator, obj.ValidOperators)
                error( ...
                    "yfinance:InvalidQueryOperator", ...
                    "Unsupported screener query operator '%s'.", ...
                    obj.Operator);
            end

            if isempty(obj.Operands)
                error("yfinance:InvalidQueryOperand", "Screener query operands cannot be empty.");
            end

            switch obj.Operator
                case {"AND", "OR"}
                    obj.validateLogicalOperands();
                case "EQ"
                    obj.validateFieldValueOperands(2, false);
                case "IS-IN"
                    obj.validateFieldValueOperands(2, false, MinimumCount=true);
                case "BTWN"
                    obj.validateFieldValueOperands(3, true);
                case {"GT", "LT", "GTE", "LTE"}
                    obj.validateFieldValueOperands(2, true);
            end
        end

        function validateLogicalOperands(obj)
            if numel(obj.Operands) <= 1
                error("yfinance:InvalidQueryOperand", "Logical screener queries require at least two child queries.");
            end

            for operandIndex = 1:numel(obj.Operands)
                if ~isa(obj.Operands{operandIndex}, "yfinance.internal.ScreenerQuery")
                    error("yfinance:InvalidQueryOperand", "Logical screener operands must be query objects.");
                end
            end
        end

        function validateFieldValueOperands(obj, count, requireNumericValues, options)
            arguments
                obj
                count (1,1) double {mustBePositive, mustBeInteger}
                requireNumericValues (1,1) logical
                options.MinimumCount (1,1) logical = false
            end

            if options.MinimumCount
                isValidCount = numel(obj.Operands) >= count;
            else
                isValidCount = numel(obj.Operands) == count;
            end

            if ~isValidCount
                error("yfinance:InvalidQueryOperand", "Operator %s received the wrong number of operands.", obj.Operator);
            end

            if ~isScalarText(obj.Operands{1})
                error("yfinance:InvalidQueryOperand", "The first screener operand must be a Yahoo field name.");
            end

            if requireNumericValues
                for operandIndex = 2:numel(obj.Operands)
                    if ~isnumeric(obj.Operands{operandIndex}) || ~isscalar(obj.Operands{operandIndex})
                        error("yfinance:InvalidQueryOperand", "Operator %s requires numeric comparison values.", obj.Operator);
                    end
                end
            end
        end

        function operands = structOperands(~, operands)
            for operandIndex = 1:numel(operands)
                if isa(operands{operandIndex}, "yfinance.internal.ScreenerQuery")
                    operands{operandIndex} = operands{operandIndex}.toStruct();
                end
            end
        end

        function text = formatQuery(obj)
            className = split(string(class(obj)), ".");
            operandText = strings(1, numel(obj.Operands));

            for operandIndex = 1:numel(obj.Operands)
                operandText(operandIndex) = formatOperand(obj.Operands{operandIndex});
            end

            text = className(end) + "(" + obj.Operator + ", [" + strjoin(operandText, ", ") + "])";
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

function value = isScalarText(value)
value = (isstring(value) || ischar(value)) && isscalar(string(value));
end

function text = formatOperand(value)
if isa(value, "yfinance.internal.ScreenerQuery")
    text = string(value);
elseif isstring(value) || ischar(value)
    text = string(value);
elseif isnumeric(value) || islogical(value)
    text = string(value);
else
    text = "<" + string(class(value)) + ">";
end
end
