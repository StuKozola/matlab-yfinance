% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestPricingDataProtobuf < matlab.unittest.TestCase
    %TESTPRICINGDATAPROTOBUF Verify Yahoo live PricingData protobuf decoding.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
        end
    end

    methods (Test)
        function base64PricingDataDecodesToLiveQuoteStruct(testCase)
            message = pricingDataFixture();

            data = yfinance.internal.live.decodePricingDataMessage(message);

            testCase.verifyEqual(data.Symbol, "AAPL");
            testCase.verifyEqual(data.RegularMarketPrice, 200.25, AbsTol=1e-6);
            testCase.verifyEqual(data.RegularMarketTime, datetime(1, ConvertFrom="posixtime", TimeZone="UTC"));
            testCase.verifyEqual(data.Currency, "USD");
            testCase.verifyEqual(data.Exchange, "NMS");
            testCase.verifyEqual(data.QuoteType, 8);
            testCase.verifyEqual(data.MarketHours, 1);
            testCase.verifyEqual(data.RegularMarketChangePercent, 1.5, AbsTol=1e-6);
            testCase.verifyEqual(data.RegularMarketVolume, 100);
            testCase.verifyEqual(data.ShortName, "Apple");
            testCase.verifyEqual(data.CirculatingSupply, 123.5);
            testCase.verifyEqual(data.MarketCap, 3000000000000);
        end

        function decodedPricingDataConvertsToLiveQuoteTable(testCase)
            data = yfinance.internal.live.decodePricingDataMessage(pricingDataFixture());

            quotes = yfinance.internal.live.pricingDataToLiveQuotes(data);

            testCase.verifyEqual(height(quotes), 1);
            testCase.verifyEqual(quotes.Symbol, "AAPL");
            testCase.verifyEqual(quotes.RegularMarketPrice, 200.25, AbsTol=1e-6);
            testCase.verifyEqual(quotes.Properties.UserData.Symbols, "AAPL");
        end

        function unknownPricingDataFieldsAreSkipped(testCase)
            bytes = [
                stringField(1, "MSFT")
                lengthDelimitedField(99, uint8(char("ignored")).')
                floatField(2, 300.5)];

            data = yfinance.internal.live.decodePricingDataMessage(base64Encode(bytes));

            testCase.verifyEqual(data.Symbol, "MSFT");
            testCase.verifyEqual(data.RegularMarketPrice, 300.5, AbsTol=1e-6);
        end

        function minimalPricingDataLeavesOptionalFieldsMissing(testCase)
            bytes = [
                stringField(1, "EURUSD=X")
                floatField(2, 1.125)];

            data = yfinance.internal.live.decodePricingDataMessage(base64Encode(bytes));

            testCase.verifyEqual(data.Symbol, "EURUSD=X");
            testCase.verifyEqual(data.RegularMarketPrice, 1.125, AbsTol=1e-6);
            testCase.verifyTrue(ismissing(data.Currency));
            testCase.verifyTrue(isnat(data.RegularMarketTime));
            testCase.verifyTrue(isnan(data.MarketCap));
        end

        function cryptoPricingDataVariantDecodesMarketFields(testCase)
            bytes = [
                stringField(1, "BTC-USD")
                floatField(2, 100000.5)
                sint64Field(28, 5000)
                sint64Field(29, 7000)
                stringField(30, "BTC")
                stringField(31, "CCC")
                doubleField(33, 2000000000000)];

            data = yfinance.internal.live.decodePricingDataMessage(base64Encode(bytes));

            testCase.verifyEqual(data.Symbol, "BTC-USD");
            testCase.verifyEqual(data.Volume24Hr, 5000);
            testCase.verifyEqual(data.VolumeAllCurrencies, 7000);
            testCase.verifyEqual(data.FromCurrency, "BTC");
            testCase.verifyEqual(data.LastMarket, "CCC");
            testCase.verifyEqual(data.MarketCap, 2000000000000);
        end

        function truncatedPricingDataErrors(testCase)
            bytes = uint8([10; 4; 65]);

            testCase.verifyError( ...
                @() yfinance.internal.live.decodePricingDataMessage(bytes), ...
                "yfinance:InvalidPricingData");
        end
    end
end

function message = pricingDataFixture()
bytes = [
    stringField(1, "AAPL")
    floatField(2, 200.25)
    sint64Field(3, 1)
    stringField(4, "USD")
    stringField(5, "NMS")
    int32Field(6, 8)
    int32Field(7, 1)
    floatField(8, 1.5)
    sint64Field(9, 100)
    floatField(10, 201)
    floatField(11, 198)
    floatField(12, 2.5)
    stringField(13, "Apple")
    sint64Field(14, 2)
    floatField(15, 199)
    floatField(16, 197.75)
    floatField(17, 100)
    stringField(18, "AAPL")
    sint64Field(19, 250)
    sint64Field(20, 1)
    sint64Field(21, 0)
    sint64Field(22, 10)
    floatField(23, 200)
    sint64Field(24, 5)
    floatField(25, 200.5)
    sint64Field(26, 6)
    sint64Field(27, 2)
    sint64Field(28, 1000)
    sint64Field(29, 2000)
    stringField(30, "USD")
    stringField(31, "NMS")
    doubleField(32, 123.5)
    doubleField(33, 3000000000000)];
message = base64Encode(bytes);
end

function bytes = stringField(fieldNumber, value)
bytes = lengthDelimitedField(fieldNumber, uint8(char(value)).');
end

function bytes = lengthDelimitedField(fieldNumber, value)
value = uint8(value(:));
bytes = [
    varint(uint64(fieldNumber * 8 + 2))
    varint(uint64(numel(value)))
    value];
end

function bytes = floatField(fieldNumber, value)
bytes = [
    varint(uint64(fieldNumber * 8 + 5))
    typecast(single(value), "uint8").'];
end

function bytes = doubleField(fieldNumber, value)
bytes = [
    varint(uint64(fieldNumber * 8 + 1))
    typecast(double(value), "uint8").'];
end

function bytes = int32Field(fieldNumber, value)
bytes = [
    varint(uint64(fieldNumber * 8))
    varint(uint64(value))];
end

function bytes = sint64Field(fieldNumber, value)
bytes = [
    varint(uint64(fieldNumber * 8))
    varint(zigZagEncode(value))];
end

function value = zigZagEncode(value)
if value >= 0
    value = uint64(value * 2);
else
    value = uint64(-2 * value - 1);
end
end

function bytes = varint(value)
bytes = uint8.empty(0, 1);

while value >= 128
    bytes(end + 1, 1) = uint8(bitor(bitand(value, 127), 128)); %#ok<AGROW>
    value = bitshift(value, -7);
end

bytes(end + 1, 1) = uint8(value);
end

function value = base64Encode(bytes)
value = string(java.util.Base64.getEncoder().encodeToString(uint8(bytes(:))));
end
