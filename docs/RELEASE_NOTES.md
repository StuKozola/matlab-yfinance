# Release Notes

## 0.1.2

Patch release for live-test resiliency, Yahoo schema-drift hardening, and experimental streaming groundwork.

Hardening:

- Optional live Yahoo smoke tests now skip known endpoint availability failures while still failing product regressions.
- Added calendar parser fixture coverage for empty responses, missing row values, and flat row payloads.
- Added schema-drift fixtures for sparse quoteSummary recommendation trends, option contracts, funds data, and screener quotes.
- Hardened parsers for heterogeneous Yahoo cell arrays and formatted values without raw numeric fields.
- Documented the true Yahoo WebSocket/protobuf parity investigation and recommended keeping polling as the default baseline.
- Added internal Yahoo `PricingData` protobuf decoder groundwork with fixture tests for future experimental streaming.
- Added internal live stream control/frame helpers and fake-transport tests for future WebSocket transport integration.

Validation snapshot:

- `buildtool package`: 203 fixture-backed tests passing with zero Code Analyzer issues.
- `buildtool liveTest`: skips known Yahoo availability failures by assumption unless `YFINANCE_LIVE_TESTS=1` is set.

## 0.1.1

Patch release for license metadata and packaging.

Highlights:

- Added the Apache License 2.0 `LICENSE` file.
- Added a project `NOTICE` file with upstream attribution and data-source disclaimers.
- Added SPDX license headers across MATLAB source, tests, examples, build scripts, and workflows.
- Included `LICENSE` and `NOTICE` in packaged toolbox files.
- Updated README license documentation.

Validation snapshot:

- `buildtool package`: 185 fixture-backed tests passing with zero Code Analyzer issues.
- `buildtool liveTest`: skips by default unless `YFINANCE_LIVE_TESTS=1` is set.

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
- Tag-triggered release workflow that attaches the toolbox package to GitHub Releases.
- Apache License 2.0 with NOTICE attribution and SPDX headers in source files.

Validation snapshot:

- `buildtool package`: 184 fixture-backed tests passing with zero Code Analyzer issues.
- `buildtool liveTest`: skips by default unless `YFINANCE_LIVE_TESTS=1` is set.

Known limitations:

- Yahoo Finance endpoints are unofficial and can change or rate-limit requests.
- MATLAB live quote support uses polling, not upstream Python's Yahoo protobuf WebSocket stream.
- pandas-specific behaviors such as DataFrame indexes and exact property-only access are intentionally mapped to MATLAB tables, timetables, structs, and methods.
