# MATLAB yfinance Full-Clone Implementation Plan

## Summary

Build a latest-MATLAB-only toolbox named `matlab-yfinance` that mirrors the current Python `yfinance` project as closely as MATLAB conventions allow. The public API will live under the `yfinance` package namespace, for example `yfinance.Ticker`, `yfinance.Tickers`, `yfinance.download`, `yfinance.Search`, `yfinance.Screener`, and WebSocket clients.

The implementation should be phased but architected for full parity from the start: shared HTTP/session/caching/data-normalization internals first, then price history and quote APIs, then financial statements/options/search/screener, then live streaming.

## Key Changes

- Create a MATLAB Toolbox project with:
  - `+yfinance/` public package API.
  - `+yfinance/+internal/` HTTP clients, Yahoo endpoint adapters, validation, cache, datetime/timezone utilities, JSON normalization.
  - `tests/` using `matlab.unittest`.
  - `docs/` examples and API reference source.
  - `buildfile.m` for test, lint, package, and documentation tasks.
- Public API target:
  - `yfinance.download(symbols, Name=Value...)` returning a `timetable` or structured multi-symbol result.
  - `yfinance.Ticker(symbol)` with methods/properties for `history`, `actions`, `dividends`, `splits`, `capitalGains`, `info`, `fastInfo`, `calendar`, `recommendations`, `upgradesDowngrades`, `sustainability`, `analystPriceTargets`, `earnings`, `incomeStmt`, `balanceSheet`, `cashFlow`, `options`, `optionChain`, `news`, and ISIN/metadata helpers.
  - `yfinance.Tickers(symbols)` for batch ticker access and grouped download.
  - `yfinance.Search`, `yfinance.Screener`, `yfinance.EquityQuery`, `yfinance.FundsData`, `yfinance.Market`, `yfinance.Sector`, `yfinance.Industry`, and lookup/domain classes matching upstream concepts.
  - `yfinance.WebSocket` and `yfinance.AsyncWebSocket` equivalents where MATLAB supports them; async behavior can use timers/background pools if native async APIs are insufficient.
- Data model:
  - Historical OHLCV data returns MATLAB `timetable`.
  - Financial statements, holders, recommendations, and option chains return `table`.
  - Scalar quote/profile metadata returns `struct` with stable field names.
  - Multi-symbol downloads return either grouped timetables or a struct keyed by sanitized ticker symbols, controlled by name-value options.
  - Preserve Yahoo timestamps, currencies, exchange timezone metadata, and adjusted/unadjusted price fields.
- Internal architecture:
  - Central `Session` abstraction handles cookies, crumb acquisition, retries, rate-limit backoff, user-agent headers, timeout, proxy, and query serialization.
  - Endpoint adapters isolate Yahoo Finance URLs such as chart, quoteSummary, quote, search, screener, options, market, and news.
  - Normalizers convert raw Yahoo JSON into MATLAB-native tables/timetables with deterministic variable names.
  - Cache layer supports in-memory cache first, with optional filesystem cache later.
  - Error taxonomy includes invalid ticker, empty response, Yahoo schema change, rate limited, network failure, and unsupported interval/range.
- Compatibility:
  - Target only the latest MATLAB release available during implementation.
  - Do not require Python or the Python `yfinance` package at runtime.
  - Add optional Python parity tests only for development, not as production dependency.

## Implementation Phases

1. Project foundation:
   - Create MATLAB Project/toolbox metadata, package folders, `buildfile.m`, test structure, README, license/disclaimer, and contribution guide.
   - Add lint/static-analysis build tasks following MATLAB Agentic Toolkit guidance: run tests, use MATLAB diagnostics, and keep generated/cache artifacts out of source control.
2. Core transport and parsing:
   - Implement session, HTTP GET/POST helpers, crumb/cookie handling, retry/backoff, JSON decode wrappers, and response fixtures.
   - Add deterministic conversion utilities for datetime, timezone, missing values, Yahoo numeric/string/null variants, and table/timetable schemas.
3. Price history and download:
   - Implement chart/history APIs, adjusted prices, dividends, splits, capital gains, actions, repair/back-adjust/auto-adjust behavior where possible.
   - Implement `download` and `Tickers` batching with sequential baseline first, then optional parallel fetch.
4. Ticker metadata and quote modules:
   - Implement `info`, `fastInfo`, quote summaries, recommendations, calendar, sustainability, holders, insider transactions, news, and quote/profile fields.
   - Normalize unavailable modules to empty tables/structs with warnings only where upstream behavior warrants it.
5. Fundamentals, options, search, screener, markets:
   - Implement financial statements, earnings, cash flow, balance sheet, option expirations/chains, search, lookup, screener queries, sector/industry/funds/market data.
   - Add query-builder classes for equity/fund screeners using MATLAB objects and name-value constructors.
6. WebSocket/live data:
   - Implement live quote streaming API with subscribe/unsubscribe, callbacks, reconnect, and message normalization.
   - If MATLAB lacks a clean native equivalent for upstream async behavior, provide synchronous event-loop plus documented background execution pattern.
7. Documentation and packaging:
   - Add examples equivalent to common upstream workflows: single ticker history, multi-ticker download, options chain, fundamentals, search/screener, and streaming.
   - Package as `.mltbx`; include toolbox metadata, examples, tests, and generated docs.

## Test Plan

- Unit tests:
  - Name-value parsing and validation.
  - URL/query construction.
  - Cookie/crumb/session behavior with mocked responses.
  - JSON normalization into structs, tables, and timetables.
  - Timezone/date-range/interval conversions.
  - Error handling for invalid ticker, empty response, malformed JSON, and rate limits.
- Fixture-based integration tests:
  - Record representative Yahoo responses as fixtures.
  - Validate stable schemas for history, actions, quote info, fundamentals, options, search, and screener output.
- Live integration tests:
  - Mark as optional/slow.
  - Use major liquid symbols like `AAPL`, `MSFT`, `SPY`.
  - Skip gracefully when network access is unavailable or Yahoo blocks/rate-limits.
- Parity tests:
  - Compare selected MATLAB outputs against Python `yfinance` for shared examples during development.
  - Treat schema compatibility and numerical/date equivalence as acceptance criteria, allowing MATLAB-native type differences.
- Build checks:
  - `buildtool test`
  - static code checks
  - toolbox packaging validation
  - example smoke tests

## Assumptions

- Package namespace will be `yfinance`, so user code reads naturally as `yfinance.Ticker("AAPL")`.
- Runtime will be pure MATLAB, with no Python dependency.
- First release aims for full-clone architecture and broad API coverage, but implementation should land in phases so core historical/quote functionality becomes usable early.
- Yahoo Finance is not an official stable API; the toolbox must isolate endpoint-specific behavior internally so schema changes are easier to repair.
- Include a legal/disclaimer section matching the spirit of upstream `yfinance`: educational/research use, Yahoo terms awareness, and no affiliation with Yahoo.

## Sources

- Upstream yfinance repository and API surface: https://github.com/ranaroussi/yfinance
- Upstream yfinance documentation: https://ranaroussi.github.io/yfinance/
- MATLAB Agentic Toolkit repository: https://github.com/matlab/matlab-agentic-toolkit
- MATLAB testing/development guidance source reviewed: https://github.com/matlab/matlab-agentic-toolkit/tree/main/skills-catalog
