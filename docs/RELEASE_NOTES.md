# Release Notes

## 0.1.0

Initial MATLAB toolbox release candidate for `matlab-yfinance`.

Highlights:

- Pure MATLAB package namespace under `+yfinance` with no Python runtime dependency.
- Historical price downloads, chart metadata, corporate actions, fast quote metadata, quoteSummary-backed fundamentals, holders, analyst data, financial statements, options, news, search, lookup, predefined/custom screeners, market/sector/industry data, fund data, calendars, and compatibility aliases.
- MATLAB-native `WebSocket` and `AsyncWebSocket` classes using reliable quote polling for subscribe/listen/unsubscribe workflows.
- Process-local configuration helpers and upstream-compatible debug/timezone-cache facade functions.
- Generated API reference, getting-started docs, parity audit, live-test policy, examples, and repeatable build tasks.
- Fixture-backed unit suite plus opt-in live Yahoo smoke tests.
- GitHub Actions packaging with the generated `.mltbx` uploaded as the `matlab-yfinance-toolbox` artifact.

Validation snapshot:

- `buildtool package`: 184 fixture-backed tests passing with zero Code Analyzer issues.
- `buildtool liveTest`: skips by default unless `YFINANCE_LIVE_TESTS=1` is set.

Known limitations:

- Yahoo Finance endpoints are unofficial and can change or rate-limit requests.
- MATLAB live quote support uses polling, not upstream Python's Yahoo protobuf WebSocket stream.
- pandas-specific behaviors such as DataFrame indexes and exact property-only access are intentionally mapped to MATLAB tables, timetables, structs, and methods.
