# yfinance Parity Audit

Audit date: 2026-05-18

This document compares the current MATLAB package surface with the upstream Python `yfinance` public API. It is a working release-hardening checklist, not a claim of exact pandas-compatible behavior.

## Sources Reviewed

- Upstream public exports: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/__init__.py
- Upstream ticker methods and properties: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/base.py and https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/ticker.py
- Upstream multi-ticker surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/tickers.py
- Upstream search surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/search.py
- Upstream lookup surface: https://raw.githubusercontent.com/ranaroussi/yfinance/main/yfinance/lookup.py
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
| `WebSocket`, `AsyncWebSocket` | MATLAB-compatible baseline | Subscribe/listen/unsubscribe workflow is implemented by polling quote snapshots; true Yahoo protobuf streaming remains a future parity item. |
| `Calendars` | Missing | Upstream export not yet implemented. |
| `config`, `set_config`, `enable_debug_mode`, `set_tz_cache_location` | Missing or not applicable | MATLAB session has explicit transport options but no global config/cache facade yet. |
| `PREDEFINED_SCREENER_QUERIES` | Covered baseline | `yfinance.PREDEFINED_SCREENER_QUERIES()` returns upstream-style predefined screener definitions; `yfinance.predefinedScreenerQueries()` returns the current names. |

## High-Priority Remaining Gaps

1. Add `Calendars` if release scope requires upstream export parity.
2. Evaluate a true Yahoo WebSocket/protobuf client or document the polling baseline as the supported MATLAB behavior for the first release.
3. Add optional live integration tests that are skipped or isolated from CI by default.
4. Decide whether a MATLAB global config/cache facade is useful, or keep transport/session configuration explicit.

## Release Readiness Notes

- The MATLAB API intentionally uses methods and PascalCase table variable names where that fits MATLAB conventions.
- Exact pandas behaviors such as `as_dict`, `pretty`, multi-index columns, and property-only access are not direct MATLAB goals.
- Yahoo endpoints are unofficial and schema-prone; fixture coverage should keep expanding around response variants and missing fields.
