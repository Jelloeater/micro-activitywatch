# WakaTime for Micro Editor

[![Coding time tracker](https://wakatime.com/badge/github/wakatime/micro-wakatime.png?branch=master)](https://wakatime.com/badge/github/wakatime/micro-wakatime)

Metrics, insights, and time tracking automatically generated from your programming activity.

## Installation

Using the plugin manager:

```shell
micro -plugin install wakatime
```

Or from within micro (must restart micro afterwards for the plugin to be loaded):

```shell
> plugin install wakatime
```

Or manually install by cloning this repo as `wakatime` into your `plug` directory:

```shell
git clone https://github.com/wakatime/micro-wakatime ~/.config/micro/plug/wakatime
```

For the first time you install WakaTime in your machine the Micro startup could delay a bit.

1. Enter your [api key](https://wakatime.com/api-key), then hit `Enter`.

   > (If you're not prompted, press ctrl + e then type `wakatime.apikey`.)

2. Use Micro Editor and your coding activity will be displayed on your [WakaTime dashboard](https://wakatime.com).

## Usage

Visit https://wakatime.com to see your coding activity.

![Project Overview](https://wakatime.com/static/img/ScreenShots/Screen-Shot-2016-03-21.png)

## Configuring

Extension settings are stored in the INI file at `$HOME/.wakatime.cfg`.

More information can be found from [wakatime core](https://github.com/wakatime/wakatime#configuring).

## Troubleshooting

First, turn on debug mode:

1. Run micro with flag `-debug`.
   > Logs are only generated when running with debug flag. Any other previous logs haven't been recorded.

Next, navigate to the folder you started micro and open `log.txt`.

Errors outside the scope of this plugin go to `$HOME/.wakatime/wakatime.log` from [wakatime-cli][wakatime-cli-help].

The [How to Debug Plugins][how to debug] guide shows how to check when coding activity was last received from your editor using the [Plugins Status Page][plugins status page].

For more general troubleshooting info, see the [wakatime-cli Troubleshooting Section][wakatime-cli-help].

[wakatime-cli-help]: https://github.com/wakatime/wakatime#troubleshooting
[how to debug]: https://wakatime.com/faq#debug-plugins
[plugins status page]: https://wakatime.com/plugin-status

---

# ActivityWatch for Micro Editor

Time tracking plugin using [ActivityWatch](https://activitywatch.net/) - an open source, privacy-focused alternative to WakaTime.

## Installation

Using the plugin manager:

```shell
micro -plugin install activitywatch
```

Or from within micro:

```shell
> plugin install activitywatch
```

Or manually install by cloning this repo as `activitywatch` into your `plug` directory:

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
