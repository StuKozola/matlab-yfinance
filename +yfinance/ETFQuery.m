classdef ETFQuery < yfinance.internal.ScreenerQuery
    %ETFQUERY Build Yahoo Finance ETF screener filters.

    methods
        function obj = ETFQuery(operator, operands)
            arguments
                operator (1,1) string {mustBeNonzeroLengthText}
                operands (1,:) cell
            end

            obj@yfinance.internal.ScreenerQuery(operator, operands, "ETF");
        end
    end
end
