# Backend Requirements — Campaign Content Endpoint (Debug Screen, Phase 2)

## Why this is needed

The app's hidden Debug screen (reached by tapping the version number on Home 3×) can
already **browse and inspect** campaigns via the existing
`GET /api/v1/core/campaigns-list` endpoint. However, that endpoint is a *reporting* view:
it returns spot/budget stats and an ad **name**, but **no playable ad content** — no image
URL, no text, no program type, no display dimensions.

To finish the Debug screen's primary remaining feature — **preview a selected campaign's
ad on the phone and Play/Stop it on the connected LED sign** — the backend must expose the
actual ad content for a specific campaign.

This is the one missing piece. Once it exists, the frontend wiring is small (the
`fetchCampaignContent()` stub and the disabled Play/Stop UI are already in place).

---

## Endpoint

```
GET /api/v1/core/campaigns/<campaign_id>/content
```

- `campaign_id` (path, int) — the `id` from a `campaigns-list` element.
- **No trailing slash** (match the `campaigns-list` convention).

### Alternative (also acceptable)
Instead of a new route, **embed the same `content` object in each `campaigns-list`
element**. That avoids the N+1 round-trips the debug screen would otherwise make, at the
cost of a heavier list payload. Either approach works for the frontend; the standalone
endpoint is preferred so the list stays lightweight.

---

## Authentication

Same as `campaigns-list`: JWT Bearer token (rest_framework_simplejwt). Any authenticated
user passes (no advertiser scoping required for this debug/ops view).

```
Authorization: Bearer <access_token>
```

---

## Response — 200 OK

A JSON object wrapping a single `content` object. The `content` shape **must match the
existing `AdContent` interface** the app already consumes for `serve-ad` (see
`src/services/AdService.ts:26-39`), so the same render and BLE-send code path is reused
verbatim — no new client logic.

```jsonc
{
  "content": {
    "programType": "image",                 // "image" | "text" | "animation" | "mixed"  (REQUIRED)
    "displaySize": { "width": 96, "height": 16 },  // REQUIRED — LED matrix pixel size
    "contentUrl": "https://cdn.mobill.com/ads/123.png",  // image/animation/mixed only
    "textContent": "SUMMER SALE",            // text/mixed only
    "textColor": "#FF0000",                  // text/mixed only — hex string
    "templateMode": "full",                  // "full" | "leftImage" | "leftText"  (optional)
    "mode": 9,                               // optional, 1–13
    "speed": 150,                            // optional, 1–255
    "stayTime": 5                            // optional, 0–255 (SECONDS — see note)
  }
}
```

### Field reference

| Field          | Type                              | Required | Notes |
|----------------|-----------------------------------|----------|-------|
| `programType`  | `"image" \| "text" \| "animation" \| "mixed"` | **yes** | Drives both the on-phone preview and the native protocol path. |
| `displaySize`  | `{ width: int, height: int }`     | **yes**  | LED matrix size. Production hardware is **96×16**. |
| `contentUrl`   | string (https URL)                | for `image`/`animation`/`mixed` | Publicly fetchable (or token-less CDN) image/GIF. PNG/JPEG for image, GIF for animation. Must be HTTPS — the phone `<Image>` and the native downloader both fetch it directly. |
| `textContent`  | string                            | for `text`/`mixed` | The text to render/scroll. |
| `textColor`    | string (`#RRGGBB`)                | for `text`/`mixed` | Hex color. |
| `templateMode` | `"full" \| "leftImage" \| "leftText"` | no | Layout for `mixed`; defaults to `"full"`. |
| `mode`         | int                               | no | Display/scroll mode. Valid **1–13**; client defaults to **9** if missing/out of range. |
| `speed`        | int                               | no | Scroll/animation speed. Valid **1–255**; client defaults to **150**. |
| `stayTime`     | int                               | no | On-screen dwell. Valid **0–255**; client defaults to **5**. |

> **`stayTime` unit:** the client currently treats `stayTime` as **seconds** (no ms→s
> conversion — see `validateStayTime` in `src/utils/displayValidation.ts`, the
> `/1000` line is commented out). Send **seconds**, consistent with whatever `serve-ad`
> already sends. If `serve-ad` sends milliseconds today, flag it — the two endpoints must
> agree, and the client treats them identically.

The client clamps `mode`/`speed`/`stayTime` to the ranges above and substitutes defaults
for missing/invalid values (`validateMode`/`validateSpeed`/`validateStayTime`), so
out-of-range values won't crash — but send valid data so the preview matches the sign.

### Content-type rules (so the frontend can validate cleanly)
- `programType: "image"` → `contentUrl` present; `textContent`/`textColor` ignored.
- `programType: "text"`  → `textContent` + `textColor` present; `contentUrl` ignored.
- `programType: "animation"` → `contentUrl` present (GIF).
- `programType: "mixed"` → both `contentUrl` and `textContent`/`textColor` present;
  `templateMode` indicates layout.

---

## Errors

| Status | Body | When |
|--------|------|------|
| 401 | (simplejwt default) | Missing/invalid token. |
| 404 | `{ "error": "Campaign not found" }` | Unknown `campaign_id`. |
| 409 (or 200 with explicit signal) | `{ "error": "Campaign has no ad content" }` | Campaign exists but has no associated ad/creative. Prefer **404/409 with a clear message** over a 200 with empty fields, so the debug UI can say "no content" rather than rendering a blank preview. |
| 500 | `{ "error": "An error occurred while fetching campaign content" }` | Server-side failure (match `campaigns-list`'s 500 shape). |

---

## Example

```bash
curl -s "https://api.mobill.com/api/v1/core/campaigns/123/content" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

```json
{
  "content": {
    "programType": "image",
    "displaySize": { "width": 96, "height": 16 },
    "contentUrl": "https://cdn.mobill.com/ads/summer-sale.png",
    "stayTime": 8
  }
}
```

---

## Notes / constraints

- **Reuse the `serve-ad` content builder.** Whatever logic `serve-ad` uses to assemble
  `AdResponse.content` for a chosen ad should be factored to also produce content for an
  arbitrary `campaign_id` here. The goal is byte-for-byte the same `AdContent` shape, so
  the app renders/sends it identically whether it came from `serve-ad` or this endpoint.
- **`contentUrl` must be reachable by the device** (HTTPS, no auth header required, or a
  signed URL the app can use as-is) — the native BLE downloader and the React Native
  `<Image>` both fetch it directly without attaching the JWT.
- **Performance:** this is a single-campaign lookup, so the N+1 concern noted on
  `campaigns-list` doesn't apply. If you instead choose to embed `content` in the list,
  watch payload size for large markets.
- **Scope:** debug/ops only. No advertiser scoping is required (consistent with
  `campaigns-list`).

---

## Frontend integration once this ships (for reference)

1. Implement `CampaignService.fetchCampaignContent(id)` to GET this endpoint and return
   `data.content` as `AdContent` (currently a stub returning `null` —
   `src/services/CampaignService.ts`).
2. In `DebugScreen.tsx`, on opening a campaign's detail, fetch its content; render an
   `<Image source={{ uri: contentUrl }}>` for image/animation/mixed, or styled `<Text>`
   for text.
3. Enable **Play** → build the display config the same way `HomeScreen.displayAd()` does
   (`validateMode/Speed/StayTime` + `DisplayManager.displayContent`), via a shared
   `buildDisplayConfig(content)` helper. **Stop** → existing `turnOffDisplay` path.
```

