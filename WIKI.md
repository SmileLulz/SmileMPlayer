# 📖 Wiki

### CLI Usage

```sh
# Generate default theme files
smilemplayer --gen-theme # or -gt

# Show help message
smilemplayer --help # or -h
```

### Config

Config file is generated automatically on first launch.

Location (Linux): `~/.config/SmileMPlayer/config.json`

Location (Windows): `C:\Users\<Username>\AppData\Local\SmileMPlayer\config.json`

| Key                           | Description                        | Default value | Available values                                   |
| ----------------------------- | ---------------------------------- | ------------- | -------------------------------------------------- |
| `current_playlist`            | Current selected playlist index    | `0`           |                                                    |
| `folders`                     | All added playlists (folder paths) | `[]` (empty)  |                                                    |
| `loop`                        | Current loop state                 | `none`        | `none`, `track`, `playlist`                        |
| `master_gain_db`              | Master output volume gain          | `4.0`         |                                                    |
| `mpris_enabled`               | Enable MPRIS integration           | `true`        | `true`, `false`                                    |
| `replaygain_enabled`          | Enable ReplayGain (2.0)            | `true`        | `true`, `false`                                    |
| `replaygain_mode`             | ReplayGain mode                    | `track`       | `off`, `track`, `album`                            |
| `replaygain_preamp_db`        | ReplayGain preamp volume           | `0.0`         |                                                    |
| `replaygain_prevent_clipping` | ReplayGain clipping protection     | `true`        | `true`, `false`                                    |
| `shuffle`                     | Shuffle mode                       | `false`       | `true`, `false`                                    |
| `sort`                        | Current sorting mode               | `title`       | `title`, `artist`, `filename`, `mtime`, `duration` |
| `sort_desc`                   | Sort descend/inverse               | `false`       | `true`, `false`                                    |
| `theme`                       | Custom theme file (.qml) path      | `""` (empty)  |                                                    |
| `volume`                      | Current volume                     | `0.5`         | `0.0` - `1.0`                                      |

> [!NOTE]
> For any path string in config file, use double backslash
>
> For example: `"theme": "C:\\Users\\<Username>\\AppData\\Local\\SmileMPlayer\\theme\\Main.qml"`

Default generated config template:

```json
{
  "current_playlist": 0,
  "folders": [],
  "loop": "none",
  "master_gain_db": 4.0,
  "replaygain_enabled": true,
  "replaygain_mode": "track",
  "replaygain_preamp_db": 0.0,
  "replaygain_prevent_clipping": true,
  "shuffle": false,
  "sort": "title",
  "sort_desc": false,
  "theme": "",
  "volume": 0.5
}
```
