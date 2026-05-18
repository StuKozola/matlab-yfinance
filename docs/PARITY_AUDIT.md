# yfinance Parity Audit

Audit date: 2026-05-18

This document compares the current MATLAB package surface with the upstream Python `yfinance` public API. It is a working release-hardening checklist, not a claim of exact pandas-compatible behavior.

## Sources Reviewed

- Upstream public exports: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/__init__.py
- Upstream ticker methods and properties: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/base.py and https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/ticker.py
- Upstream multi-ticker surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/tickers.py
- Upstream search surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/search.py
- Upstream lookup surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/lookup.py
- Upstream calendars surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/calendars.py
- Upstream config/debug/cache exports: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/config.py, https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/utils.py, and https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/cache.py
- Upstream screener/domain/live modules reviewed during implementation: `screener`, `domain`, and `live` under https://github.com/ranaroussi/yfinance

## Current Public API Coverage

| Upstream area | MATLAB status | Notes |
| --- | --- | --- |
| `download` | Covered | Sequential MATLAB implementation returning timetables/structs rather than pandas multi-index frames. |
| `Ticker` | Broad coverage | History, actions, metadata, quoteSummary modules, holders, analysis, statements, options, news, ISIN, fund data, and compatibility aliases are implemented. |
| `Tickers` | Covered baseline | `history`, `download`, `fastInfo`, `news`, and `live` are implemented. |
| `Search` | Covered baseline | Quotes, news, lists, research reports, navigation links, raw response, `All`, and upstream-style search flags are implemented. |
| `Lookup` | Covered baseline | Type-specific lookup methods/properties now cover all, stock/equity, mutual fund, ETF, index, future, currency, and cryptocurrency lookup. |
| `screen`, `Screener`, query builders | Covered baseline | Predefined and custom query objects are implemented, including exported predefined query names/definitions. |
| `Market`, `Sector`, `Industry` | Covered baseline | Key Yahoo domain data is exposed as structs and tables. |
| `FundsData` | Covered baseline | Fund overview, operations, holdings, asset classes, ratings, and sector weights are exposed. |
| `WebSocket`, `AsyncWebSocket` | MATLAB-compatible baseline | Subscribe/listen/unsubscribe workflow is implemented by polling quote snapshots; internal Yahoo `PricingData` protobuf decoding, stream transport scaffolding, and raw RFC 6455 `ws://` framing exist, but Yahoo production `wss://` transport remains a future parity item. The support policy is documented in `docs/LIVE_STREAMING_AND_TESTS.md`, and the implementation investigation is in `docs/WEBSOCKET_PROTOBUF_INVESTIGATION.md`. |
| `Calendars` | Covered baseline | Earnings, IPO, economic-event, and split calendars are implemented through Yahoo's visualization endpoint with MATLAB tables. |
| `config`, `set_config`, `enable_debug_mode`, `set_tz_cache_location` | Covered baseline | Process-local configuration, debug logging defaults, and upstream-compatible timezone cache location metadata are implemented. MATLAB-specific `setConfig`, `enableDebugMode`, and `setTzCacheLocation` aliases are also provided. |
| `PREDEFINED_SCREENER_QUERIES` | Covered baseline | `yfinance.PREDEFINED_SCREENER_QUERIES()` returns upstream-style predefined screener definitions; `yfinance.predefinedScreenerQueries()` returns the current names. |

## Remaining Gaps

No release-blocking upstream export gaps remain for the current MATLAB scope.

Post-release candidates:

1. Consider an opt-in experimental Yahoo WebSocket/protobuf client if the dependency and packaging tradeoffs in `docs/WEBSOCKET_PROTOBUF_INVESTIGATION.md` are acceptable.
2. Continue expanding fixture coverage around Yahoo schema drift and optional live smoke coverage.

## Release Readiness Notes

- The MATLAB API intentionally uses methods and PascalCase table variable names where that fits MATLAB conventions.
- Exact pandas behaviors such as `as_dict`, `pretty`, multi-index columns, and property-only access are not direct MATLAB goals.
- Yahoo endpoints are unofficial and schema-prone; fixture coverage should keep expanding around response variants and missing fields.
