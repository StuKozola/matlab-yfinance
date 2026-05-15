function data = industryResponseToData(response, options)
%INDUSTRYRESPONSETODATA Convert Yahoo industry domain data.

arguments
    response struct
    options.Key (1,1) string = ""
end

payload = domainData(response, options.Key);
data = commonDomainData(payload, options.Key);
data.SectorKey = stringField(payload, "sectorKey");
data.SectorName = stringField(payload, "sectorName");
data.TopPerformingCompanies = yfinance.internal.yahooStructArrayToTable( ...
    fieldOrEmpty(payload, "topPerformingCompanies"));
data.TopGrowthCompanies = yfinance.internal.yahooStructArrayToTable( ...
    fieldOrEmpty(payload, "topGrowthCompanies"));
end

function data = commonDomainData(payload, key)
data = struct( ...
    "Key", key, ...
    "Name", stringField(payload, "name"), ...
    "Symbol", stringField(payload, "symbol"), ...
    "Overview", overviewStruct(fieldOrEmpty(payload, "overview")), ...
    "TopCompanies", yfinance.internal.yahooStructArrayToTable(fieldOrEmpty(payload, "topCompanies")), ...
    "ResearchReports", yfinance.internal.yahooStructArrayToTable(fieldOrEmpty(payload, "researchReports")), ...
    "Raw", payload);
end

function payload = domainData(response, key)
if ~isfield(response, "data") || isempty(response.data)
    error("yfinance:InvalidResponse", "Yahoo Finance response does not contain industry data for %s.", key);
end

payload = response.data;
end

function value = overviewStruct(overview)
value = struct( ...
    "CompaniesCount", numericField(overview, "companiesCount"), ...
    "MarketCap", rawField(overview, "marketCap"), ...
    "MessageBoardId", stringField(overview, "messageBoardId"), ...
    "Description", stringField(overview, "description"), ...
    "IndustriesCount", numericField(overview, "industriesCount"), ...
    "MarketWeight", rawField(overview, "marketWeight"), ...
    "EmployeeCount", rawField(overview, "employeeCount"));
end

function value = fieldOrEmpty(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = struct.empty(0, 1);
end
end

function value = stringField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
else
    value = "";
end
end

function value = numericField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName)) && isnumeric(inputStruct.(fieldName))
    value = double(inputStruct.(fieldName));
else
    value = NaN;
end
end

function value = rawField(inputStruct, fieldName)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = yfinance.internal.unwrapYahooValue(inputStruct.(fieldName));
else
    value = NaN;
end
end
