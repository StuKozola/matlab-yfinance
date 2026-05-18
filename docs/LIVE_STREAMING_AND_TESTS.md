# Live Streaming and Live Tests

## Supported live quote behavior

`yfinance.WebSocket` and `yfinance.AsyncWebSocket` provide MATLAB-native subscribe, listen, unsubscribe, and callback workflows using repeated Yahoo quote snapshots by default.

This is the supported first-release behavior. Upstream Python `yfinance` uses a Yahoo WebSocket stream with protobuf payloads. The MATLAB toolbox keeps polling as the default because Yahoo's stream is unofficial and can change without notice.

Opt-in experimental streaming is available through `yfinance.ExperimentalWebSocket` or `yfinance.WebSocket(Transport="stream")`. It uses the internal `wss://` transport and protobuf decoder under `+yfinance/+internal/+live`.

```matlab
stream = yfinance.ExperimentalWebSocket();
stream.subscribe("BTC-USD");
quotes = stream.listen([], MaxIterations=1);
stream.close();
```

See [WEBSOCKET_PROTOBUF_INVESTIGATION.md](WEBSOCKET_PROTOBUF_INVESTIGATION.md) for implementation details and tradeoffs.

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

The live tests currently exercise recent price downloads, search, predefined screeners, the calendar visualization endpoint, and the experimental Yahoo `wss://` stream. Yahoo Finance endpoints are unofficial, so known availability failures such as rate limits, authorization changes, timeouts, empty responses, network errors, and WebSocket handshake rejections are filtered as skipped assumptions. The target still fails when a live smoke test reaches Yahoo successfully but the toolbox behavior is incorrect.
