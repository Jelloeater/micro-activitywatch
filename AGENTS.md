# Agent Instructions for micro-activitywatch

## Project Overview

ActivityWatch plugin for the Micro editor - sends heartbeat events to ActivityWatch for time tracking.

## Repository

https://github.com/Jelloeater/micro-activitywatch

## Key Files

- `activitywatch.lua` - Main plugin (~400 lines)
- `help/activitywatch.md` - Help documentation
- `repo.json` - Plugin metadata for Micro's plugin manager
- `.github/workflows/ci.yml` - CI pipeline (Lua linting, JSON validation)

## Important Implementation Details

### HTTP Requests

Micro's Lua uses Go's `net/http`. POST body must be a `strings.Reader`:

```lua
local strings = import("strings")
http.Post(url, "content-type", strings.NewReader(jsonBody))
```

### ActivityWatch API

- Bucket creation: `POST /api/0/buckets/{bucket_id}`
- Heartbeat: `POST /api/0/buckets/{bucket_id}/heartbeat?pulsetime=120`
- Required JSON field: `timestamp` in ISO 8601 format

### Configuration

- API URL: Controlled by `AW_API_URL` environment variable
- Default: `http://localhost:5600/api/0`
- Bucket ID: `aw-watcher-micro_{hostname}`

### Debugging

Run Micro with `-debug` flag to see logs:
```shell
micro -debug filename
```

Check log output for "ActivityWatch" messages.

## Common Issues

1. **nil pointer on http.Post**: Use `strings.NewReader()` not raw string
2. **422 Unprocessable Entity**: Add `timestamp` field to JSON body
3. **Duration showing 0**: Need periodic heartbeat timer (30s interval)
4. **Config file errors**: Removed config file - now uses ENV var only

## Running Tests

Manual test - send heartbeat:
```bash
curl -X POST "http://localhost:5600/api/0/buckets/aw-watcher-micro_TEST/heartbeat?pulsetime=120" \
  -H "Content-Type: application/json" \
  -d '{"timestamp": "2026-02-16T18:00:00Z", "data": {"file": "/test.lua"}}'
```

Check events:
```bash
curl "http://localhost:5600/api/0/buckets/aw-watcher-micro_TEST/events?limit=5"
```
