import "./components"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris


Item {
    id: compact

    readonly property bool horizontal: widget.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool fillAvailableSpace: plasmoid.configuration.fillAvailableSpace
    readonly property int panelTextMode: plasmoid.configuration.panelTextMode
    readonly property bool panelTextHoverSwap: plasmoid.configuration.panelTextHoverSwap
    readonly property int panelTextLineCount: plasmoid.configuration.panelTextLineCount
    readonly property bool panelTextStableWidth: plasmoid.configuration.panelTextStableWidth
    readonly property bool panelTextReplaceIntermission: plasmoid.configuration.panelTextReplaceIntermission
    readonly property bool miniLyricsMode: panelTextMode === 3
    readonly property int miniLyricsAlignment: plasmoid.configuration.panelMiniLyricsAlignment
    readonly property int miniLyricsAnimation: plasmoid.configuration.panelMiniLyricsAnimation
    readonly property int panelLyricsAnimation: plasmoid.configuration.panelMiniLyricsAnimation
    readonly property bool miniLyricsClickable: plasmoid.configuration.panelMiniLyricsClickable
    readonly property bool panelTextStableWidthActive: panelTextStableWidth
        || (panelTextHoverSwap && panelTextMode !== 2)
    readonly property bool lyricsConfigured: panelTextMode === 1 || panelTextMode === 2
        || panelTextMode === 3 || (panelTextHoverSwap && panelTextMode < 2)
    readonly property bool lyricsAvailable: lyricsManager.available
    readonly property bool lyricsIntermission: lyricsManager.currentLine >= 0
        && lyricsManager.currentLine < lyricsManager.lines.length
        && Number(lyricsManager.lineTimestamps[lyricsManager.currentLine]) < 0
    readonly property bool hoverSwapActive: panelTextHoverSwap && lyricsAvailable && panelHoverHandler.hovered
    readonly property bool showSongInfo: (panelTextMode === 2
            || (panelTextMode === 0 && !hoverSwapActive)
            || (panelTextMode === 1 && (!lyricsAvailable || hoverSwapActive
                || (panelTextReplaceIntermission && lyricsIntermission)))
            || (panelTextMode === 3 && panelTextReplaceIntermission && lyricsIntermission))
    readonly property bool showLyrics: lyricsConfigured
        && lyricsAvailable
        && (!panelTextReplaceIntermission || !lyricsIntermission || panelTextMode === 0)
        && (panelTextMode === 2
            || (panelTextMode === 0 && hoverSwapActive)
            || (panelTextMode === 1 && !hoverSwapActive)
            || panelTextMode === 3)

    Layout.preferredWidth: horizontal ? grid.implicitWidth + lengthMargin * 2 : grid.implicitWidth
    Layout.preferredHeight: !horizontal ? grid.implicitHeight + lengthMargin * 2 : grid.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.fillHeight: horizontal || fillAvailableSpace
    Layout.fillWidth: !horizontal || fillAvailableSpace

    readonly property int widgetThickness: horizontal ? height : width
    readonly property int controlsSize: Math.round(widgetThickness * plasmoid.configuration.panelControlsSizeRatio)
    readonly property bool spaceBetweenControlsInPanel: plasmoid.configuration.spaceBetweenControlsInPanel
    readonly property int iconSize: Math.round(widgetThickness * plasmoid.configuration.panelIconSizeRatio)
    readonly property int lengthMargin: Math.round((widgetThickness - Math.max(controlsSize, iconSize))) / 2

    readonly property bool colorsFromAlbumCover: plasmoid.configuration.colorsFromAlbumCover
    readonly property int panelBackgroundRadius: plasmoid.configuration.panelBackgroundRadius
    readonly property bool useImageColors: panelIcon.imageReady && panelIcon.type == PanelIcon.Type.Image && colorsFromAlbumCover
    readonly property color imageColor: useImageColors ? panelIcon.imageColor : Kirigami.Theme.textColor
    readonly property color backgroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, "black", 0.5)
    property color backgroundColor: useImageColors ? backgroundColorFromImage : "transparent"
    readonly property var backgroundColorBrightness: Kirigami.ColorUtils.brightnessForColor(backgroundColor)
    readonly property color contrastColor: backgroundColorBrightness === Kirigami.ColorUtils.Dark ? "white" : "black"
    readonly property color foregroundColorFromImage: Kirigami.ColorUtils.tintWithAlpha(imageColor, contrastColor, .6)
    property color foregroundColor: useImageColors ? foregroundColorFromImage : Kirigami.Theme.textColor

    LyricsManager {
        id: lyricsManager
        enabled: compact.lyricsConfigured
        title: player.title
        artists: player.artists
        album: player.album
        songLength: player.songLength
        songPosition: player.songPosition
    }

    Behavior on backgroundColor {
        ColorAnimation {
            duration: Kirigami.Units.longDuration
        }
    }

    Behavior on foregroundColor {
        ColorAnimation {
            duration: Kirigami.Units.longDuration
        }
    }

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        Item {
            width: horizontal ? parent.width : parent.width
            height: horizontal ? parent.height : parent.height
            Rectangle {
                id: progress
                color: foregroundColor
                height: horizontal ? parent.height : parent.height * (player.songPosition / player.songLength)
                width: horizontal ? parent.width * (player.songPosition / player.songLength) : parent.width
                visible: plasmoid.configuration.mediaProgressInPanel
                opacity: player.playbackStatus === Mpris.PlaybackStatus.Playing ? 0.15 : 0.07
            }
        }
    }
    layer.enabled: compact.panelBackgroundRadius > 0 && (!Qt.colorEqual(backgroundColor, "transparent") || plasmoid.configuration.mediaProgressInPanel)
    layer.effect: OpacityMask {
        maskSource: Item {
            width: compact.width
            height: compact.height
            Rectangle {
                anchors.fill: parent
                radius: compact.panelBackgroundRadius
            }
        }
    }

    MouseAreaWithWheelHandler {
        id: panelMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
        propagateComposedEvents: true

        onClicked: (mouse) => {
            switch (mouse.button) {
            case Qt.MiddleButton:
                player.playPause()
                break
            case Qt.BackButton:
                if (player.canGoPrevious) {
                    player.previous();
                }
                break
            case Qt.ForwardButton:
                if (player.canGoNext) {
                    player.next();
                }
                break
            default:
                if (mouse.modifiers & Qt.ControlModifier) {
                    if (player.canRaise) player.raise()
                } else {
                    widget.expanded = !widget.expanded;
                }
            }
        }

        onWheelUp: {
            player.changeVolume(plasmoid.configuration.volumeStep / 100, true);
        }

        onWheelDown: {
            player.changeVolume(-plasmoid.configuration.volumeStep / 100, true);
        }
    }

    HoverHandler {
        id: panelHoverHandler
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    GridLayout {
        id: grid

        columns: horizontal ? grid.children.length : 1
        rows: horizontal ? 1 : grid.children.length
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        anchors.leftMargin: horizontal ? lengthMargin: 0
        anchors.rightMargin: horizontal ? lengthMargin : 0
        anchors.bottomMargin: horizontal ? 0: lengthMargin
        anchors.topMargin: horizontal ? 0 : lengthMargin
        anchors.fill: parent

        PanelIcon {
            id: panelIcon
            visible: plasmoid.configuration.iconInPanel

            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            size: compact.iconSize
            icon: plasmoid.configuration.panelIcon
            imageUrl: player.artUrl
            imageRadius: plasmoid.configuration.albumCoverRadius
            fallbackToIconWhenImageNotAvailable: plasmoid.configuration.fallbackToIconWhenArtNotAvailable
            type: {
                if (!plasmoid.configuration.useAlbumCoverAsPanelIcon) {
                    return PanelIcon.Type.Icon;
                }
                return PanelIcon.Type.Image;
            }
        }

        // This item is used to fill the available space when the song text is not enabled.
        Item {
            visible: !compact.showSongInfo && !compact.showLyrics && fillAvailableSpace
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        GridLayout {
            id: panelTextGrid
            visible: compact.showSongInfo || compact.showLyrics
            columns: horizontal && panelTextLineCount === 1 && panelTextMode === 2 ? 2 : 1
            rows: horizontal && panelTextLineCount === 1 && panelTextMode === 2 ? 1 : 2
            rowSpacing: panelTextMode === 2 && panelTextLineCount === 2 ? 0 : Kirigami.Units.smallSpacing
            readonly property bool combinedTwoLines: panelTextMode === 2 && panelTextLineCount === 2
            readonly property real panelLineHeight: Math.max(Kirigami.Units.gridUnit, baseFont.pixelSize * 1.35)
            readonly property real configuredTextWidth: Math.max(1, plasmoid.configuration.maxSongWidthInPanel)
            readonly property real lyricWidth: Math.min(lyricsView.contentImplicitWidth, configuredTextWidth)
            readonly property real songWidth: Math.min(songAndArtistText.implicitWidth, configuredTextWidth)
            readonly property real stableWidth: {
                let width = 0
                if (panelTextHoverSwap && panelTextMode !== 2) {
                    width = Math.max(songWidth, lyricWidth)
                } else if (compact.showSongInfo && compact.showLyrics) {
                    width = panelTextLineCount === 1
                        ? songWidth + lyricWidth + Kirigami.Units.smallSpacing
                        : Math.max(songWidth, lyricWidth)
                } else {
                    width = compact.showLyrics ? lyricWidth : songWidth
                }
                return Math.min(width, configuredTextWidth)
            }
            Layout.preferredWidth: horizontal && songGrid.useFixedWidth
                ? songGrid.fxdWidth
                : horizontal && !compact.fillAvailableSpace && compact.panelTextStableWidthActive
                    ? stableWidth : -1
            Layout.minimumWidth: horizontal && songGrid.useFixedWidth
                ? songGrid.fxdWidth : 0
            Layout.maximumWidth: horizontal && songGrid.useFixedWidth
                ? songGrid.fxdWidth
                : horizontal && !compact.fillAvailableSpace ? configuredTextWidth : -1
            Layout.preferredHeight: horizontal && combinedTwoLines ? panelLineHeight * 2 : -1
            Layout.fillHeight: !combinedTwoLines || fillAvailableSpace
            Layout.fillWidth: !horizontal || (fillAvailableSpace && !songGrid.useFixedWidth)
                || (horizontal && panelTextMode === 2)
            Layout.alignment: horizontal
                ? (panelTextMode >= 2 ? Qt.AlignVCenter : songGrid.textAlignment | Qt.AlignVCenter)
                : Qt.AlignHCenter | songGrid.textAlignment
            GridLayout {
            id: songGrid
            visible: compact.showSongInfo

            columns: horizontal ? songGrid.children.length : 1
            rows: horizontal ? 1 : songGrid.children.length

            readonly property int textAlignment: plasmoid.configuration.songTextAlignment
            readonly property int fxdWidth: plasmoid.configuration.songTextFixedWidth + 2 * Kirigami.Units.smallSpacing
            readonly property bool useFixedWidth: plasmoid.configuration.useSongTextFixedWidth
            readonly property int length: horizontal ? width : height

            Layout.preferredWidth: horizontal && useFixedWidth && !fillAvailableSpace
                    && !(panelTextMode === 2 && panelTextLineCount === 1) ? fxdWidth : -1
            Layout.preferredHeight: !horizontal && useFixedWidth && !fillAvailableSpace ? fxdWidth : -1
            Layout.fillHeight: !panelTextGrid.combinedTwoLines || fillAvailableSpace
            Layout.fillWidth: !horizontal || fillAvailableSpace
                || (horizontal && panelTextMode === 2)
            Layout.alignment: horizontal
                ? (panelTextMode === 2 ? Qt.AlignVCenter : songGrid.textAlignment | Qt.AlignVCenter)
                : Qt.AlignHCenter | songGrid.textAlignment

            Item {
                readonly property bool fill: [Qt.AlignRight, Qt.AlignCenter].includes(songGrid.textAlignment)
                Layout.fillHeight: !horizontal && fill
                Layout.fillWidth: horizontal && fill
            }

            Item {
                id: songAndArtistTextColumn
                Layout.fillHeight: horizontal
                Layout.fillWidth: !horizontal || (horizontal && panelTextMode === 2)
                Layout.preferredHeight: !horizontal ? songAndArtistText.width : null
                Layout.preferredWidth: horizontal ? songAndArtistText.width : null
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                SongAndArtistText {
                    id: songAndArtistText

                    anchors.centerIn: parent
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                    rotation: {
                        if (horizontal) return 0
                        if (widget.location === PlasmaCore.Types.LeftEdge) return -90
                        if (widget.location === PlasmaCore.Types.RightEdge) return 90
                    }

                    maxWidth: {
                        if (fillAvailableSpace || songGrid.useFixedWidth || panelTextMode === 2) {
                            return songGrid.length
                        }
                        return plasmoid.configuration.maxSongWidthInPanel
                    }
                    scrollingBehaviour: plasmoid.configuration.textScrollingBehaviour
                    scrollingSpeed: plasmoid.configuration.textScrollingSpeed
                    scrollingResetOnPause: plasmoid.configuration.textScrollingResetOnPause
                    scrollingEnabled: plasmoid.configuration.textScrollingEnabled
                    titlePosition: panelTextGrid.combinedTwoLines
                        ? SongAndArtistText.TextPosition.FirstLine
                        : plasmoid.configuration.titlePosition
                    artistsPosition: panelTextGrid.combinedTwoLines
                        ? SongAndArtistText.TextPosition.FirstLine
                        : plasmoid.configuration.artistsPosition
                    albumPosition: panelTextGrid.combinedTwoLines
                        ? SongAndArtistText.TextPosition.FirstLine
                        : plasmoid.configuration.albumPosition
                    hideAlbumForSingles: plasmoid.configuration.compactHideAlbumForSingles
                    forcePauseScrolling: {
                        if (!plasmoid.configuration.pauseTextScrollingWhileMediaIsNotPlaying) {
                            return false
                        }
                        return player.playbackStatus !== Mpris.PlaybackStatus.Playing
                    }
                    textFont: baseFont
                    textColor: foregroundColor
                    title: player.title
                    artists: player.artists
                    album: player.album
                    textAlignment: songGrid.textAlignment
                    truncateStyle: plasmoid.configuration.compactTruncatedTextStyle
                    opacity: player.playbackStatus === Mpris.PlaybackStatus.Playing ? 1.0 : 0.75
                }
            }

            Item {
                readonly property bool fill: [Qt.AlignLeft, Qt.AlignCenter].includes(songGrid.textAlignment)
                Layout.fillHeight: !horizontal && fill
                Layout.fillWidth: horizontal && fill
            }

            }

            Item {
                id: panelLyrics
                visible: compact.showLyrics
                Layout.fillWidth: true
                Layout.fillHeight: !panelTextGrid.combinedTwoLines || fillAvailableSpace
                Layout.minimumWidth: 0
                Layout.minimumHeight: 0
                Layout.alignment: horizontal
                    ? (panelTextMode >= 2 ? Qt.AlignVCenter : songGrid.textAlignment | Qt.AlignVCenter)
                    : Qt.AlignHCenter | songGrid.textAlignment
                Layout.preferredWidth: compact.horizontal && !songGrid.useFixedWidth && !compact.fillAvailableSpace
                    ? Math.min(Math.max(1, compact.miniLyricsMode ? lyricsView.contentImplicitWidth : lyricsView.implicitWidth),
                               Math.max(1, plasmoid.configuration.maxSongWidthInPanel))
                    : -1
                Layout.preferredHeight: compact.horizontal
                    ? Math.max(Kirigami.Units.gridUnit, baseFont.pixelSize * 1.35) * (compact.miniLyricsMode ? 3 : 1)
                    : Math.max(Kirigami.Units.gridUnit, baseFont.pixelSize * 1.35) * (compact.panelTextMode === 2 ? 1 : compact.panelTextLineCount)

                PanelLyricLine {
                    id: lyricsView
                    anchors.fill: parent
                    visible: !compact.miniLyricsMode
                    lines: lyricsManager.lines
                    lineTimestamps: lyricsManager.lineTimestamps
                    currentLine: lyricsManager.currentLine
                    currentLineDuration: lyricsManager.currentLineDuration
                    horizontalAlignment: songGrid.textAlignment
                    textFont: baseFont
                    textColor: foregroundColor
                    animationMode: compact.panelLyricsAnimation
                    animationColor: foregroundColor
                    seekEnabled: false
                    onSeekRequested: (timestamp) => player.setPosition(timestamp * 1000)
                }

                MiniLyrics {
                    id: miniLyricsView
                    anchors.fill: parent
                    visible: compact.miniLyricsMode
                    lines: lyricsManager.lines
                    lineTimestamps: lyricsManager.lineTimestamps
                    currentLine: lyricsManager.currentLine
                    currentLineDuration: lyricsManager.currentLineDuration
                    horizontalAlignment: compact.miniLyricsMode ? compact.miniLyricsAlignment : songGrid.textAlignment
                    textFont: baseFont
                    textColor: foregroundColor
                    animationMode: compact.panelLyricsAnimation
                    animationColor: foregroundColor
                    scrollingEnabled: compact.miniLyricsMode
                    seekEnabled: compact.miniLyricsMode && compact.miniLyricsClickable && player.canSeek
                    onSeekRequested: (timestamp) => player.setPosition(timestamp * 1000)
                }

                TapHandler {
                    enabled: compact.miniLyricsMode && !compact.miniLyricsClickable
                    acceptedButtons: Qt.LeftButton
                    onTapped: widget.expanded = true
                }

                // Keep panel volume handling from seeing wheel events over lyrics.
                WheelHandler {
                    onWheel: (wheel) => {
                        if (compact.miniLyricsMode) {
                            miniLyricsView.scrollByWheel(wheel.angleDelta.y || -wheel.angleDelta.x)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: compact.miniLyricsMode && !compact.miniLyricsClickable
                    acceptedButtons: Qt.LeftButton
                    onClicked: widget.expanded = !widget.expanded
                }
            }
        }

        GridLayout {
            columns: horizontal ? grid.children.length : 1
            rows: horizontal ? 1 : grid.children.length
            columnSpacing: spaceBetweenControlsInPanel ? Kirigami.Units.smallSpacing : 0
            rowSpacing: spaceBetweenControlsInPanel ? Kirigami.Units.smallSpacing : 0

            Layout.fillHeight: horizontal
            Layout.fillWidth: !horizontal
            Layout.alignment : Qt.AlignVCenter | Qt.AlignHCenter

            PlasmaComponents3.ToolButton {
                visible: plasmoid.configuration.skipBackwardControlInPanel
                Layout.alignment : Qt.AlignVCenter | Qt.AlignHCenter

                enabled: player.canGoPrevious
                icon.name: "media-skip-backward"
                icon.color: foregroundColor
                implicitWidth: compact.controlsSize
                implicitHeight: compact.controlsSize
                onClicked: player.previous()
            }

            PlasmaComponents3.ToolButton {
                visible: plasmoid.configuration.playPauseControlInPanel
                Layout.alignment : Qt.AlignVCenter | Qt.AlignHCenter

                enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                implicitWidth: compact.controlsSize
                implicitHeight: compact.controlsSize
                icon.name: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "media-playback-pause" : "media-playback-start"
                icon.color: foregroundColor
                onClicked: player.playPause()
            }

            PlasmaComponents3.ToolButton {
                visible: plasmoid.configuration.skipForwardControlInPanel
                Layout.alignment : Qt.AlignVCenter | Qt.AlignHCenter

                enabled: player.canGoNext
                implicitWidth: compact.controlsSize
                implicitHeight: compact.controlsSize
                icon.name: "media-skip-forward"
                icon.color: foregroundColor
                onClicked: player.next()
            }
        }
    }
}
