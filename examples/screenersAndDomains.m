%% Screeners and Market Domains
% Run predefined/custom screeners and inspect market domain data.

gainers = yfinance.screen("day_gainers", Count=10);
predefinedQueries = yfinance.predefinedScreenerQueries();
searchResults = yfinance.Search("apple", IncludeResearch=true, IncludeNavLinks=true);
lookup = yfinance.Lookup("apple");
stockMatches = lookup.getStock(Count=10);

query = yfinance.EquityQuery("and", { ...
    yfinance.EquityQuery("gt", {"percentchange", 3}), ...
    yfinance.EquityQuery("eq", {"region", "us"})});
customGainers = yfinance.screen(query, Size=10, SortField="percentchange", SortAscending=true);

market = yfinance.Market("us");
sector = yfinance.Sector("technology");
industry = yfinance.Industry("software-infrastructure");

disp(gainers.Quotes)
disp(predefinedQueries)
disp(searchResults.Research)
disp(searchResults.Nav)
disp(stockMatches)
disp(customGainers.Quotes)
disp(market.Status)
disp(sector.Industries)
disp(industry.TopPerformingCompanies)
