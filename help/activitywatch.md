# ActivityWatch Plugin

Time tracking plugin for the Micro editor that sends heartbeat events to ActivityWatch.

## Features

- Automatic time tracking when editing files
- Tracks file changes, cursor movements, and selections
- Captures file language and project name (via .git folder)
- Debounced heartbeats (2-minute interval) to reduce API calls

## Installation

1. Ensure ActivityWatch is running (`http://localhost:5600`)
2. Install this plugin via Micro's plugin manager or copy to `~/.config/micro/plugins/`

## Usage

### Commands

- `activitywatch.status` - Show connection status and bucket info
- `activitywatch.test` - Test connection to ActivityWatch server
- `activitywatch.apiurl` - Configure API URL (default: `http://localhost:5600/api/0`)

### Configuration

The plugin stores configuration in `~/.activitywatch.cfg`:
- `api_url` - ActivityWatch API endpoint
- `hostname` - Computed automatically

## Requirements

- Micro editor v2.0.0+
- ActivityWatch running on localhost (or custom endpoint)
