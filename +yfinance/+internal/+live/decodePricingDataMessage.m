% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

function data = decodePricingDataMessage(message)
%DECODEPRICINGDATAMESSAGE Decode a Yahoo PricingData protobuf payload.

if isstring(message) || ischar(message)
    bytes = base64Decode(message);
elseif isa(message, "uint8")
    bytes = message(:);
else
    error("yfinance:InvalidPricingData", "PricingData input must be base64 text or uint8 bytes.");
end

data = emptyPricingData();
position = 1;

while position <= numel(bytes)
    [key, position] = readVarint(bytes, position);
    fieldNumber = floor(double(key) / 8);
    wireType = mod(double(key), 8);

    switch fieldNumber
        case 1
            [data.Symbol, position] = readString(bytes, position, wireType);
        case 2
            [data.RegularMarketPrice, position] = readFloat(bytes, position, wireType);
        case 3
            [unixTime, position] = readSint64(bytes, position, wireType);
            data.RegularMarketTime = unixDatetime(unixTime);
        case 4
            [data.Currency, position] = readString(bytes, position, wireType);
        case 5
            [data.Exchange, position] = readString(bytes, position, wireType);
        case 6
            [data.QuoteType, position] = readInt32(bytes, position, wireType);
        case 7
            [data.MarketHours, position] = readInt32(bytes, position, wireType);
        case 8
            [data.RegularMarketChangePercent, position] = readFloat(bytes, position, wireType);
        case 9
            [data.RegularMarketVolume, position] = readSint64(bytes, position, wireType);
        case 10
            [data.RegularMarketDayHigh, position] = readFloat(bytes, position, wireType);
        case 11
            [data.RegularMarketDayLow, position] = readFloat(bytes, position, wireType);
        case 12
            [data.RegularMarketChange, position] = readFloat(bytes, position, wireType);
        case 13
            [data.ShortName, position] = readString(bytes, position, wireType);
        case 14
            [unixTime, position] = readSint64(bytes, position, wireType);
            data.ExpireDate = unixDatetime(unixTime);
        case 15
            [data.RegularMarketOpen, position] = readFloat(bytes, position, wireType);
        case 16
            [data.RegularMarketPreviousClose, position] = readFloat(bytes, position, wireType);
        case 17
            [data.StrikePrice, position] = readFloat(bytes, position, wireType);
        case 18
            [data.UnderlyingSymbol, position] = readString(bytes, position, wireType);
        case 19
            [data.OpenInterest, position] = readSint64(bytes, position, wireType);
        case 20
            [data.OptionsType, position] = readSint64(bytes, position, wireType);
        case 21
            [data.MiniOption, position] = readSint64(bytes, position, wireType);
        case 22
            [data.LastSize, position] = readSint64(bytes, position, wireType);
        case 23
            [data.Bid, position] = readFloat(bytes, position, wireType);
        case 24
            [data.BidSize, position] = readSint64(bytes, position, wireType);
        case 25
            [data.Ask, position] = readFloat(bytes, position, wireType);
        case 26
            [data.AskSize, position] = readSint64(bytes, position, wireType);
        case 27
            [data.PriceHint, position] = readSint64(bytes, position, wireType);
        case 28
            [data.Volume24Hr, position] = readSint64(bytes, position, wireType);
        case 29
            [data.VolumeAllCurrencies, position] = readSint64(bytes, position, wireType);
        case 30
            [data.FromCurrency, position] = readString(bytes, position, wireType);
        case 31
            [data.LastMarket, position] = readString(bytes, position, wireType);
        case 32
            [data.CirculatingSupply, position] = readDouble(bytes, position, wireType);
        case 33
            [data.MarketCap, position] = readDouble(bytes, position, wireType);
        otherwise
            position = skipField(bytes, position, wireType);
    end
end
end

function data = emptyPricingData()
data = struct( ...
    "Symbol", missing, ...
    "RegularMarketPrice", NaN, ...
    "RegularMarketTime", NaT(1, 1, TimeZone="UTC"), ...
    "Currency", missing, ...
    "Exchange", missing, ...
    "QuoteType", NaN, ...
    "MarketHours", NaN, ...
    "RegularMarketChangePercent", NaN, ...
    "RegularMarketVolume", NaN, ...
    "RegularMarketDayHigh", NaN, ...
    "RegularMarketDayLow", NaN, ...
    "RegularMarketChange", NaN, ...
    "ShortName", missing, ...
    "ExpireDate", NaT(1, 1, TimeZone="UTC"), ...
    "RegularMarketOpen", NaN, ...
    "RegularMarketPreviousClose", NaN, ...
    "StrikePrice", NaN, ...
    "UnderlyingSymbol", missing, ...
    "OpenInterest", NaN, ...
    "OptionsType", NaN, ...
    "MiniOption", NaN, ...
    "LastSize", NaN, ...
    "Bid", NaN, ...
    "BidSize", NaN, ...
    "Ask", NaN, ...
    "AskSize", NaN, ...
    "PriceHint", NaN, ...
    "Volume24Hr", NaN, ...
    "VolumeAllCurrencies", NaN, ...
    "FromCurrency", missing, ...
    "LastMarket", missing, ...
    "CirculatingSupply", NaN, ...
    "MarketCap", NaN);
end

function bytes = base64Decode(message)
message = strtrim(string(message));

try
    bytes = typecast(java.util.Base64.getDecoder().decode(char(message)), "uint8");
    bytes = bytes(:);
catch exception
    error("yfinance:InvalidPricingData", "Unable to base64-decode Yahoo PricingData payload. %s", exception.message);
end
end

function [value, position] = readString(bytes, position, wireType)
requireWireType(wireType, 2);
[length, position] = readVarint(bytes, position);
length = double(length);
ensureAvailable(bytes, position, length);
value = string(native2unicode(bytes(position:(position + length - 1)).', "UTF-8"));
position = position + length;
end

function [value, position] = readFloat(bytes, position, wireType)
requireWireType(wireType, 5);
ensureAvailable(bytes, position, 4);
value = double(typecast(bytes(position:(position + 3)), "single"));
position = position + 4;
end

function [value, position] = readDouble(bytes, position, wireType)
requireWireType(wireType, 1);
ensureAvailable(bytes, position, 8);
value = typecast(bytes(position:(position + 7)), "double");
position = position + 8;
end

function [value, position] = readInt32(bytes, position, wireType)
requireWireType(wireType, 0);
[rawValue, position] = readVarint(bytes, position);
value = double(rawValue);
end

function [value, position] = readSint64(bytes, position, wireType)
requireWireType(wireType, 0);
[rawValue, position] = readVarint(bytes, position);
value = zigZagDecode(rawValue);
end

function [value, position] = readVarint(bytes, position)
value = uint64(0);
shift = 0;

while true
    ensureAvailable(bytes, position, 1);
    currentByte = uint64(bytes(position));
    position = position + 1;
    value = bitor(value, bitshift(bitand(currentByte, 127), shift));

    if bitand(currentByte, 128) == 0
        return
    end

    shift = shift + 7;

    if shift > 63
        error("yfinance:InvalidPricingData", "Invalid protobuf varint in Yahoo PricingData payload.");
    end
end
end

function value = zigZagDecode(rawValue)
if bitand(rawValue, 1) == 0
    value = double(bitshift(rawValue, -1));
else
    value = -double(bitshift(rawValue, -1)) - 1;
end
end

function position = skipField(bytes, position, wireType)
switch wireType
    case 0
        [~, position] = readVarint(bytes, position);
    case 1
        ensureAvailable(bytes, position, 8);
        position = position + 8;
    case 2
        [length, position] = readVarint(bytes, position);
        length = double(length);
        ensureAvailable(bytes, position, length);
        position = position + length;
    case 5
        ensureAvailable(bytes, position, 4);
        position = position + 4;
    otherwise
        error("yfinance:InvalidPricingData", "Unsupported protobuf wire type %d in Yahoo PricingData payload.", wireType);
end
end

function requireWireType(actual, expected)
if actual ~= expected
    error("yfinance:InvalidPricingData", "Unexpected protobuf wire type %d in Yahoo PricingData payload.", actual);
end
end

function ensureAvailable(bytes, position, count)
if position + count - 1 > numel(bytes)
    error("yfinance:InvalidPricingData", "Truncated Yahoo PricingData protobuf payload.");
end
end

function value = unixDatetime(unixTime)
if isnan(unixTime)
    value = NaT(1, 1, TimeZone="UTC");
else
    value = datetime(unixTime, ConvertFrom="posixtime", TimeZone="UTC");
end
end
