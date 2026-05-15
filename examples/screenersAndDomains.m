%% Screeners and Market Domains
% Run predefined/custom screeners and inspect market domain data.

gainers = yfinance.screen("day_gainers", Count=10);

query = yfinance.EquityQuery("and", { ...
    yfinance.EquityQuery("gt", {"percentchange", 3}), ...
    yfinance.EquityQuery("eq", {"region", "us"})});
customGainers = yfinance.screen(query, Size=10, SortField="percentchange", SortAscending=true);

market = yfinance.Market("us");
sector = yfinance.Sector("technology");
industry = yfinance.Industry("software-infrastructure");

disp(gainers.Quotes)
disp(customGainers.Quotes)
disp(market.Status)
disp(sector.Industries)
disp(industry.TopPerformingCompanies)
