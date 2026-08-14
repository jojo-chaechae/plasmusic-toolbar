<div align="center">

# PlasMusic Toolbar


PlasMusic Toolbar is a KDE Plasma widget that shows current playback information and provides playback controls. This fork contains additional Full View media and synced-lyrics features maintained independently from upstream.

</div>

## 🧩 Compatibility

- Compatible with KDE Plasma 6.0.4 and newer.
- Last compatible release for older Plasma 6 versions: [**v3.7.0**](https://github.com/ccatterina/plasmusic-toolbar/tree/v3.7.0)
- Plasma 5: a Plasma 5 version of the widget is available in the `plasma5` branch: https://github.com/ccatterina/plasmusic-toolbar/tree/plasma5


## ✨ Features

- **🎵 Now Playing** — Title, artist and album art shown right in the KDE panel.
- **⏯️ Playback Controls** — Play, pause, skip and go back without leaving the panel.
- **📸 Full View** — Popup with album art, full playback controls (shuffle, repeat included), volume and seek bar.
- **🎼 Synced Mini-Lyrics** — Optional LRCLIB-backed lyrics with clickable timestamp seeking, horizontal overflow scrolling, configurable intermission markers, and experimental glow animation.
- **🖼️ Combined Media View** — Configure album art and mini-lyrics together, including their order, position above or below playback controls, spacing, padding, and album-art visibility.
- **🔀 Preferred Source** — Choose which media player the widget should follow.
- **🖥️ Flexible Layout** — Works in horizontal and vertical panels, and as a desktop widget.
- **🎨 Deep Customization** — Album-art-derived slider colors, fonts, panel visibility, scrolling behavior, playback-section layout, keep-open behavior, and more.

All media info (title, artist, cover art url, playback state) is read from your media player via **[MPRIS2](https://specifications.freedesktop.org/mpris-spec/latest/)**. The same interface is used to send playback and other commands back to the player.

### Synced lyrics

Mini-lyrics are disabled by default and can be enabled in **Full View → Media → Show mini-lyrics**. When enabled, the widget queries [LRCLIB](https://lrclib.net/) for synced lyrics using the current track metadata.

- Click a lyric line to seek to its timestamp when the player supports seeking.
- Long lyric lines can scroll horizontally while the active line is displayed.
- Large timing gaps can be shown as a `♪` intermission row. The gap threshold is configurable in seconds and defaults to 8 seconds.
- The experimental animation selector currently provides `None` and `Glow sweep`.
- Lyrics are unavailable when LRCLIB has no matching synced lyrics or network access is unavailable.


## 📦 Installation

### KDE store

The KDE Store listing is for the upstream project and does not include this fork's additional features:

- https://store.kde.org/p/2128143


### Manual
1. Clone the repository:
    ```sh
    git clone https://github.com/jojo-chaechae/plasmusic-toolbar.git /tmp/plasmusic-toolbar
    ```

2. Install the widget:

    ```sh
    kpackagetool6 -i /tmp/plasmusic-toolbar/src/ --type Plasma/Applet
    ```

3. Upgrading the widget:

    ```sh
    kpackagetool6 -u /tmp/plasmusic-toolbar/src/ --type Plasma/Applet
    ```

4. Restart PlasmaShell after installation or an upgrade:

    ```sh
    plasmashell --replace
    ```

5. Removing the widget:

    ```sh
    kpackagetool6 -r plasmusic-toolbar --type Plasma/Applet
    ```


## 🌍 Translations

Want to help translate PlasMusic Toolbar into your language? See [TRANSLATIONS.md](TRANSLATIONS.md) for instructions.

## 🖼️ Screenshots

TODO: Add updated screenshots for the fork's Full View media and mini-lyrics features.
