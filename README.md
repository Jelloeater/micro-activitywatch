# ActivityWatch for Micro Editor

Time tracking plugin using [ActivityWatch](https://activitywatch.net/) - an open source, privacy-focused alternative to ActivityWatch.

## Installation
Manually install by cloning this repo as `activitywatch` into your `plug` directory:

```shell
git clone https://github.com/Jelloeater/micro-activitywatch ~/.config/micro/plug/activitywatch
```

## Requirements

- [ActivityWatch](https://activitywatch.net/) running (default: `http://localhost:5600`)
- Micro editor v2.0.0+

## Usage

The plugin will automatically create a bucket named `aw-watcher-micro_{hostname}` and send heartbeats when you:
- Save files
- Move the cursor
- Select text
- Scroll
- And more...

A heartbeat is sent every 30 seconds while a file is open to track duration.

### Commands

- `activitywatch.status` - Show connection status
- `activitywatch.test` - Test connection to ActivityWatch
- `activitywatch.apiurl` - Show current API URL

## Configuration

### Environment Variable

Set `AW_API_URL` to override the default ActivityWatch endpoint:

```bash
export AW_API_URL="http://localhost:5600/api/0"
```

For permanent configuration, add to your shell profile (`.zshrc`, `.bashrc`, etc.).

### Default Values

- API URL: `http://localhost:5600/api/0`
- Bucket ID: `aw-watcher-micro_{hostname}`

## Data Collected

The plugin sends the following data to ActivityWatch:
- File path being edited
- File extension (language detection)
- Project name (detected from `.git` folder, falls back to directory name)
- Whether the file was written to (save action)

## Troubleshooting

Run Micro with debug flag to see logs:

```shell
micro -debug ~/.zshrc
```

Check the log output for "ActivityWatch" messages.

Common issues:
- ActivityWatch not running: Start `aw-qt` or `aw-server`
- Wrong API URL: Set `AW_API_URL` environment variable
