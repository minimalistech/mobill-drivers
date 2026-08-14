# BLE transfer performance log — perf/ble-transfer-speed

Every optimization step is one commit, tested against the real display before the next step.
Grep the Xcode console for `PERF|` lines and record them here after each gate run.

- `PERF|animation|…` — prep stages (frame extraction, pixel conversion, serialization), logged once per send from `DisplayManagerBridge.m`.
- `PERF|transfer|…` — BLE transfer (packet count, retries, total ms, per-packet send→ACK stats), logged once per send from `GWPeripheral.m`. The small begin-command logs its own line; the big data transfer is the line with the large packet count.
- `PERF|pkt_error|…` / `PERF|pkt_timeout|…` — device NAK / 5s watchdog events. Should stay at zero; any increase after a step fails the gate.

## Test gate procedure
1. Send nike-192x48.gif, adidas_192x48.gif, prada_192x48.gif (2–3 runs each; 5 for step 1a).
2. Verify: transfer completes, animation plays correctly (garbage columns = corruption), no pkt_error/pkt_timeout lines, no disconnects.
3. At steps 1a/1d and any serialization change: also send one image ad and one text ad.
4. Record the numbers below. If the gate fails: revert the step's commit (or flip its legacy constant), re-test, note what happened.

## Results

| Step (commit) | GIF | frames | packets | t_frames_ms | t_convert_ms | t_serialize_ms | t_transfer_ms | pkt_avg_ms | retries | total (stopwatch) | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Baseline (Phase 0) | nike | | | | | | | | | | |
| Baseline (Phase 0) | adidas | | | | | | | | | | |
| Baseline (Phase 0) | prada | | | | | | | | | | |
