# Live Streaming and Live Tests

## Supported live quote behavior

`yfinance.WebSocket` and `yfinance.AsyncWebSocket` provide MATLAB-native subscribe, listen, unsubscribe, and callback workflows using repeated Yahoo quote snapshots.

This is the supported first-release behavior. Upstream Python `yfinance` uses a Yahoo WebSocket stream with protobuf payloads. MATLAB does not ship a built-in Yahoo-specific protobuf WebSocket decoder, so this toolbox currently favors a reliable polling implementation with normal MATLAB tables and callbacks.

Future work can add a true low-level WebSocket/protobuf transport if the dependency and packaging tradeoffs are acceptable for a MATLAB toolbox. See [WEBSOCKET_PROTOBUF_INVESTIGATION.md](WEBSOCKET_PROTOBUF_INVESTIGATION.md) for the current investigation and recommendation.

## Optional live tests

Default `buildtool test`, `buildtool check`, and `buildtool package` runs use fixture-backed tests only. They do not depend on Yahoo availability, network access, or rate-limit state.

Live smoke tests live under `tests_live/` and are opt-in:

```matlab
setenv("YFINANCE_LIVE_TESTS", "1")
buildtool liveTest
```

From a shell:

```powershell
$env:YFINANCE_LIVE_TESTS = "1"
matlab -batch "buildtool liveTest"
```

The live tests currently exercise recent price downloads, search, predefined screeners, and the calendar visualization endpoint. Yahoo Finance endpoints are unofficial, so known availability failures such as rate limits, authorization changes, timeouts, empty responses, and network errors are filtered as skipped assumptions. The target still fails when a live smoke test reaches Yahoo successfully but the toolbox behavior is incorrect.
