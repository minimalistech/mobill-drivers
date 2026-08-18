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

## Build numbers

Every garage test build bumps `CURRENT_PROJECT_VERSION` so the installed build is
identifiable on the phone (Version 1.0.5 (N) on the home screen / in Settings).

| Build | Contains (cumulative) |
|---|---|
| 1 | Phase 0 instrumentation only — baseline |
| 2 | + step 1b (log gating) + step 1a (backpressure chunk writes) |
| 3 | + step 1c (no 15 ms post-ACK delay) + step 1d (link-derived chunk size, capped 180) + ACK-handler log gating |

## Results

| Step (commit) | GIF | frames | packets | t_frames_ms | t_convert_ms | t_serialize_ms | t_transfer_ms | pkt_avg_ms | retries | total (stopwatch) | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Baseline (Phase 0, ee91660) | nike | 40 (of 114) | 157 (1,061 chunks) | 1150 | 89 | 147 | 29177 | 168.5 (min 102.7, max 1456.5) | 0 | ~31 s | logs/202608180627.log; LZSS 737 KB → ~158 KB |
| Build 2 (1b+1a, b72bbda) | nike | 40 | 157 | 551 | 85 | 144 | 29403 | 167.5 (min 97.1, max 1350.0) | 0 | ~30 s | logs/202608180648.log — backpressure path active on all packets |
| Build 2 | prada | 30 | 133 | 408 | 74 | 116 | 18538 | 119.8 | 0 | ~19 s | |
| Build 2 | adidas | 35 | 112 | 508 | 69 | 135 | 25759 | 209.6 | 0 | ~26 s | |
| Build 2 | nike (repeat) | 40 | 157 | 692 | 85 | 140 | 32469 | 187.2 | 0 | display showed in ~1–2 s | **Device answered `0201` at begin (CRC cache hit) and displayed instantly; app re-uploaded 157 packets anyway** |

| Build 3 (1c+1d, 72025a0) | nike | 40 | 157 | 487 | 90 | 141 | 29944 | 186.8 (min 113.3) | 0 | ~30 s | logs/202608180705.log |
| Build 3 | prada | 30 | 133 | 481 | 75 | 108 | 18524 | 135.7 (min 113.4) | 0 | ~19 s | |
| Build 3 | adidas | 35 | 112 | 408 | 67 | 124 | 25974 | 228.3 (min 89.4) | 0 | ~26 s | |

### Build 3 conclusions — transport optimization has hit the protocol floor
- Step 1c (no 15 ms post-ACK delay) also produced **no change**: totals identical to build 2 run-to-run. Like the chunk pacing, the delay was absorbed by connection-interval alignment. Kept (harmless, correct).
- Only one >500 ms stall per transfer, always packet 0 → packet 1 (~1.1–1.4 s): device-side storage preparation, not app-side. No periodic main-thread stalls — the dedicated-BLE-queue idea is low-value; dropped.
- Per-packet cost is radio/firmware-quantized: ~113 ms best, 135–230 ms session-dependent. **First-time sends are floor-bound at roughly packets × ~120-230 ms** (nike: ~19–30 s). LZSS already achieves 79% on nike; the encoder already emits RGB444, so pre-quantization gains nothing. No further app-side transport lever exists for first-time sends within this protocol.
- The remaining transformative wins are protocol-level: **`0201` CRC skip** (repeat sends → ~1–2 s; production ads repeat constantly) and **program slots 0–8** (preload rotation, switch in ms).

### Build 2 conclusions
- Step 1a (backpressure) produced **no speedup**: the 10 ms chunk pacing had been overlapping radio transmission, not extending it. Kept anyway (correct mechanism, 0 retries, no cost).
- Per-packet floor is ~97–120 ms (connection-interval + device ACK). Inter-packet gap distribution is bimodal: ~76 packets at 90–180 ms, ~61 at 210–330 ms (missed connection events / main-thread contention), max 1.37 s.
- Remaining transport levers: remove 15 ms post-ACK delay (1c), get send/ACK handling off the contended main thread (1e). Beating the ~120 ms × packets floor requires fewer packets (Phase 2 compression) or the `0201` CRC skip.
- **`0201` at the begin command = device already has this CRC32 and is displaying it.** First-time sends got `0200`. Skipping the 157-packet data phase on `0201` makes repeat content ~1–2 s.
