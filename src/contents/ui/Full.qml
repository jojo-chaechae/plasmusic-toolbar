import "./components"
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import Qt5Compat.GraphicalEffects


Item {
    id: root

    property string albumPlaceholder: plasmoid.configuration.albumPlaceholder
    property real volumeStep: plasmoid.configuration.volumeStep
    property bool albumCoverBackground: plasmoid.configuration.fullAlbumCoverAsBackground
    property bool albumCoverTintBackground: plasmoid.configuration.fullAlbumCoverTintBackground
    property real albumCoverTintOpacity: plasmoid.configuration.fullAlbumCoverTintOpacity
    property bool albumCoverTintGradient: plasmoid.configuration.fullAlbumCoverTintGradient
    property bool albumCoverTintUseContrastText: plasmoid.configuration.fullAlbumCoverTintUseContrastText
    // Manually control whether the text uses album-derived contrast colors when the tint is active
    readonly property bool useAlbumContrastText: albumCoverBackground || (albumCoverTintBackground && albumCoverTintUseContrastText)

    // Applies the configured tint opacity to a color
    function tintColor(c) {
        return Qt.rgba(c.r, c.g, c.b, albumCoverTintOpacity);
    }
    property bool thumbnailVisible: plasmoid.configuration.fullViewThumbnailVisible
    property bool showPinButton: plasmoid.configuration.showPinButton
    // Horizontal padding for the playback section components (text, slider, volume, controls).
    property int contentPadding: plasmoid.configuration.fullViewContentPadding
    property int contentVerticalPadding: plasmoid.configuration.fullViewContentPaddingVertical
    property int contentSpacing: plasmoid.configuration.fullViewContentSpacing
    property int mediaPadding: plasmoid.configuration.fullViewMediaPadding
    property int mediaSpacing: plasmoid.configuration.fullViewMediaSpacing
    property bool progressBarVisible: plasmoid.configuration.fullViewProgressBarVisible
    property bool volumeControlVisible: plasmoid.configuration.fullViewVolumeControlVisible
    property bool shuffleVisible: plasmoid.configuration.fullViewShuffleVisible
    property bool playbackControlsVisible: plasmoid.configuration.fullViewPlaybackControlsVisible
    property bool loopVisible: plasmoid.configuration.fullViewLoopVisible
    property bool playbackControlsFitWidth: plasmoid.configuration.fullViewPlaybackControlsFillWidth
    property bool songTextVisible: plasmoid.configuration.fullViewSongTextVisible
    property int songTextAlignment: plasmoid.configuration.fullViewSongTextAlignment
    property bool lyricsVisible: plasmoid.configuration.fullViewLyricsVisible
    property int lyricsAlignment: plasmoid.configuration.fullViewLyricsAlignment
    property int lyricsFontSize: plasmoid.configuration.fullViewLyricsFontSize
    property real lyricsLineSpacing: plasmoid.configuration.fullViewLyricsLineSpacing
    property int mediaPosition: plasmoid.configuration.fullViewMediaPosition
    property int mediaOrder: plasmoid.configuration.fullViewMediaOrder
    // Order of the playback section rows (any permutation of: song, progress, volume, controls)
    readonly property var contentOrder: {
        return plasmoid.configuration.fullViewVerticalOrder.split(",").filter(key => key && key !== "lyrics")
    }

    LyricsManager {
        id: lyricsManager
        enabled: root.lyricsVisible
        title: player.title
        artists: player.artists
        album: player.album
        songLength: player.songLength
        songPosition: player.songPosition
    }

    // The Full View max and min width is driven by config values. The window can be resized within these bounds; thumbnail and text adapt.
    readonly property int configMinWidth: plasmoid.configuration.fullViewMinWidth
    readonly property int maximumWidth: plasmoid.configuration.fullViewMaxWidth
    readonly property int configMinHeight: plasmoid.configuration.fullViewMinHeight
    readonly property int maximumHeight: plasmoid.configuration.fullViewMaxHeight
    property bool fullAlbumCoverRounded: plasmoid.configuration.fullAlbumCoverRounded
    property int albumCoverRadius: plasmoid.configuration.fullAlbumCoverRadius

    // Override min width if visible content (e.g. playback controls) needs more space
    readonly property int contentMinWidth: controlsMinWidth > 0 ? controlsMinWidth + 40 : 0
    readonly property int effectiveMinWidth: Math.min(Math.max(configMinWidth, contentMinWidth), maximumWidth)
    // Kept in sync with the playback controls' natural width by the controls component
    property int controlsMinWidth: 0

    // Stable (width-independent) preferred thumbnail height, referenced to the min width, so that
    // resizing the popup width doesn't drag the height along with it (the "aspect ratio lock").
    readonly property real mediaImageRatio: mediaTop.item ? mediaTop.item.imageRatio
        : mediaBottom.item ? mediaBottom.item.imageRatio : 1.0
    readonly property real naturalThumbHeight: thumbnailVisible && mediaImageRatio > 0
        ? effectiveMinWidth / mediaImageRatio
        : 0
    // The media artwork follows the current popup width. naturalThumbHeight remains
    // the width-independent floor used by the resize constraints below.
    readonly property real mediaArtHeight: {
        const mediaWidth = mediaPosition === 0 ? mediaTop.width : mediaBottom.width
        return thumbnailVisible && mediaImageRatio > 0 && mediaWidth > 0
            ? mediaWidth / mediaImageRatio
            : naturalThumbHeight
    }
    // Height floor that keeps the fixed content (everything except the flexible thumbnail) from clipping.
    readonly property real fixedContentHeight: Math.max(0, column.implicitHeight - naturalThumbHeight)

    Layout.minimumWidth: effectiveMinWidth
    Layout.maximumWidth: maximumWidth
    Layout.preferredWidth: effectiveMinWidth
    Layout.preferredHeight: column.implicitHeight
    Layout.minimumHeight: Math.max(configMinHeight, fixedContentHeight)
    Layout.maximumHeight: maximumHeight

    // Store the original theme colors (root keeps default Kirigami.Theme.inherit: true)
    readonly property color _originalTextColor: Kirigami.Theme.textColor
    readonly property color _originalHighlightColor: Kirigami.Theme.highlightColor

    Item {
        visible: albumCoverBackground && thumbnailVisible
        Layout.margins: 0
        anchors.centerIn: parent
        height: column.height
        width: column.width

        ImageWithPlaceholder {
            id: albumArtFull
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height * 0.7
            width: parent.width
            fillMode: Image.PreserveAspectCrop
            placeholderSource: albumPlaceholder
            imageSource: player.artUrl

            onStatusChanged: {
                if (status === Image.Ready) {
                    imageColors.update()
                }
            }

            Kirigami.ImageColors {
                id: imageColors
                source: albumArtFull
                readonly property color bgColor: average
                // Text derived from the album is always bright for readability.
                readonly property color fgColor: Kirigami.ColorUtils.tintWithAlpha(bgColor, "white", .8)
                readonly property color hlColor: Kirigami.ColorUtils.tintWithAlpha(bgColor, "white", .9)
            }

            layer.enabled: root.fullAlbumCoverRounded && root.albumCoverRadius > 0
			layer.effect: OpacityMask {
				maskSource: Item {
					width: albumArtFull.width
					height: albumArtFull.height
					Rectangle {
						anchors.fill: parent
						radius: albumCoverRadius
                        bottomRightRadius: 0
                        bottomLeftRadius: 0
					}
				}
			}
        }

        LinearGradient {
            id: mask
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: headerbar.visible ? imageColors.bgColor : "transparent" }   // Adjust top gradient when the player selector is visible
                GradientStop { position: 0.11; color: "transparent" }
                GradientStop { position: headerbar.visible ? 0.5 : 0.4; color: "transparent" }
                GradientStop { position: 0.7; color: imageColors.bgColor }
                GradientStop { position: 1; color: imageColors.bgColor }
            }
        }
    }

    // A subtle translucent tint derived from the album cover average color.
    // Optionally a vertical gradient generated from the album art colors.
    Rectangle {
        id: tintBackground
        visible: albumCoverTintBackground
        anchors.fill: parent
        gradient: albumCoverTintGradient ? tintGradient : flatGradient
    }

    Gradient {
        id: flatGradient
        GradientStop { position: 0.0; color: root.tintColor(imageColors.bgColor) }
        GradientStop { position: 1.0; color: root.tintColor(imageColors.bgColor) }
    }

    Gradient {
        id: tintGradient
        GradientStop { position: 0.0; color: root.tintColor(Kirigami.ColorUtils.tintWithAlpha(imageColors.bgColor, "white", 0.35)) }
        GradientStop { position: 0.5; color: root.tintColor(imageColors.bgColor) }
        GradientStop { position: 1.0; color: root.tintColor(Kirigami.ColorUtils.tintWithAlpha(imageColors.bgColor, "black", 0.35)) }
    }


    ColumnLayout {
        id: column

        spacing: root.contentSpacing
        anchors.fill: parent

        // Override theme ONLY for this layout and its children
        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: root.useAlbumContrastText ? imageColors.fgColor : root._originalTextColor
        Kirigami.Theme.highlightColor: root.useAlbumContrastText ? imageColors.hlColor : root._originalHighlightColor

        // Media Player Selector
        Rectangle {
            id: headerbar
            Layout.fillWidth: true
            visible: plasmoid.configuration.showPlayerSelector
                    && playerList.count > 2
                    && player.sourceIdentities == null

            color: root.useAlbumContrastText
                ? "transparent"
                : Kirigami.Theme.backgroundColor

            implicitHeight: Kirigami.Units.gridUnit * 2

            PlasmaComponents3.TabBar {
                id: playerSelector
                objectName: "playerSelector"
                anchors.fill: parent
                implicitHeight: contentHeight
                currentIndex: player.mpris2Model.currentIndex

                Repeater {
                    id: playerList
                    model: player.mpris2Model
                    delegate: PlasmaComponents3.TabButton {
                        required property string iconName
                        required property bool isMultiplexer
                        required property string identity
                        required property int index
                        anchors.top: parent?.top
                        anchors.bottom: parent?.bottom
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        icon.name: iconName
                        icon.height: Kirigami.Units.iconSizes.small
                        text: isMultiplexer ? i18nc("@action:button", "Choose player automatically") : identity

                        Accessible.onPressAction: clicked()
                        onClicked: {
                            player.mpris2Model.currentIndex = index;
                        }

                        PlasmaComponents3.ToolTip.text: text
                        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                        PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
                    }
                }
            }
        }

        Loader {
            id: mediaTop
            visible: root.mediaPosition === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: root.mediaPadding
            Layout.rightMargin: root.mediaPadding
            Layout.topMargin: root.mediaPadding
            Layout.bottomMargin: root.mediaPadding
            Layout.minimumHeight: 0
            Layout.preferredHeight: item ? item.implicitHeight : 0
            sourceComponent: root.mediaPosition === 0 ? mediaComponent : null
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.topMargin: root.contentVerticalPadding
            Layout.bottomMargin: root.contentVerticalPadding
            Layout.preferredHeight: implicitHeight
            Layout.minimumHeight: implicitHeight
            Layout.maximumHeight: implicitHeight
            spacing: root.contentSpacing

            Repeater {
                model: root.contentOrder
                delegate: Loader {
                    visible: root.contentItemVisible(modelData)
                    Layout.fillWidth: true
                    Layout.leftMargin: root.contentPadding
                    Layout.rightMargin: root.contentPadding
                    Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                    sourceComponent: root.contentComponent(modelData)
                }
            }
        }

        Loader {
            id: mediaBottom
            visible: root.mediaPosition === 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: root.mediaPadding
            Layout.rightMargin: root.mediaPadding
            Layout.topMargin: root.mediaPadding
            Layout.bottomMargin: root.mediaPadding
            Layout.minimumHeight: 0
            Layout.preferredHeight: item ? item.implicitHeight : 0
            sourceComponent: root.mediaPosition === 1 ? mediaComponent : null
        }

    }

    Component {
        id: songComponent
        SongAndArtistText {
            visible: root.songTextVisible
            textAlignment: root.songTextAlignment
            scrollingSpeed: plasmoid.configuration.fullViewTextScrollingSpeed
            title: player.title
            artists: player.artists
            album: player.album
            textFont: baseFont
            titlePosition: plasmoid.configuration.fullTitlePosition
            artistsPosition: plasmoid.configuration.fullArtistsPosition
            albumPosition: plasmoid.configuration.fullAlbumPosition
            hideAlbumForSingles: plasmoid.configuration.fullHideAlbumForSingles
            scrollingEnabled: widget.expanded
        }
    }

    Component {
        id: progressComponent
        TrackPositionSlider {
            visible: root.progressBarVisible
            songPosition: player.songPosition
            songLength: player.songLength
            playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
            enableChangePosition: player.canSeek
            onRequireChangePosition: (position) => {
                player.setPosition(position)
            }
            onRequireUpdatePosition: () => {
                player.updatePosition()
            }
        }
    }

    Component {
        id: volumeComponent
        VolumeBar {
            visible: root.volumeControlVisible
            volume: player.volume
            onSetVolume: (vol) => {
                player.setVolume(vol)
            }
            onVolumeUp: {
                player.changeVolume(volumeStep / 100, false)
            }
            onVolumeDown: {
                player.changeVolume(-volumeStep / 100, false)
            }
        }
    }

    Component {
        id: mediaComponent
        MediaContent {
            albumPlaceholder: root.albumPlaceholder
            artUrl: player.artUrl
            albumArtVisible: root.thumbnailVisible
            albumCoverBackground: root.albumCoverBackground
            albumCoverRounded: root.fullAlbumCoverRounded
            albumCoverRadius: root.albumCoverRadius
            albumArtHeight: root.mediaArtHeight
            canRaise: player.canRaise
            hideRaiseTooltip: plasmoid.configuration.hideCanBeRaisedTooltip
            lyricsVisible: root.lyricsVisible
            lyricsLines: lyricsManager.lines
            lyricsAvailable: lyricsManager.available
            currentLine: lyricsManager.currentLine
            currentLineDuration: lyricsManager.currentLineDuration
            lyricsAlignment: root.lyricsAlignment
            lyricsFontSize: root.lyricsFontSize
            lyricsLineSpacing: root.lyricsLineSpacing
            mediaSpacing: root.mediaSpacing
            textFont: baseFont
            lyricsTextColor: root.useAlbumContrastText ? imageColors.fgColor : Kirigami.Theme.textColor
            scrollingEnabled: widget.expanded
            mediaOrder: root.mediaOrder
            onRaiseRequested: {
                if (player.canRaise) player.raise()
            }
        }
    }

    Component {
        id: controlsComponent
        Item {
            visible: root.shuffleVisible || root.playbackControlsVisible || root.loopVisible
            implicitHeight: row.implicitHeight
            implicitWidth: row.implicitWidth
            RowLayout {
                id: row
                width: root.playbackControlsFitWidth ? parent.width : implicitWidth
                height: implicitHeight
                anchors.centerIn: parent

                CommandIcon {
                    visible: root.shuffleVisible
                    enabled: player.canChangeShuffle
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: "media-playlist-shuffle"
                    onClicked: player.setShuffle(player.shuffle === Mpris.ShuffleStatus.Off ? Mpris.ShuffleStatus.On : Mpris.ShuffleStatus.Off)
                    active: player.shuffle === Mpris.ShuffleStatus.On
                }

                CommandIcon {
                    visible: root.playbackControlsVisible
                    enabled: player.canGoPrevious
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: "media-skip-backward"
                    onClicked: player.previous()
                }

                CommandIcon {
                    visible: root.playbackControlsVisible
                    enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing ? player.canPause : player.canPlay
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.large
                    source: player.playbackStatus === Mpris.PlaybackStatus.Playing ? "media-playback-pause" : "media-playback-start"
                    onClicked: player.playPause()
                }

                CommandIcon {
                    visible: root.playbackControlsVisible
                    enabled: player.canGoNext
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: "media-skip-forward"
                    onClicked: player.next()
                }

                CommandIcon {
                    visible: root.loopVisible
                    enabled: player.canChangeLoopStatus
                    Layout.alignment: Qt.AlignHCenter
                    size: Kirigami.Units.iconSizes.medium
                    source: player.loopStatus === Mpris.LoopStatus.Track ? "media-playlist-repeat-song" : "media-playlist-repeat"
                    active: player.loopStatus != Mpris.LoopStatus.None
                    onClicked: () => {
                        let status = Mpris.LoopStatus.None;
                        if (player.loopStatus == Mpris.LoopStatus.None)
                            status = Mpris.LoopStatus.Track;
                        else if (player.loopStatus === Mpris.LoopStatus.Track)
                            status = Mpris.LoopStatus.Playlist;
                        player.setLoopStatus(status);
                    }
                }
            }

            // Keep the popup min-width in sync with the controls' natural width
            Binding {
                target: root
                property: "controlsMinWidth"
                value: row.implicitWidth
                when: root.shuffleVisible || root.playbackControlsVisible || root.loopVisible
            }
        }
    }

    function contentComponent(key) {
        switch (key) {
        case "song": return songComponent;
        case "progress": return progressComponent;
        case "volume": return volumeComponent;
        case "controls": return controlsComponent;
        }
        return null;
    }

    function contentItemVisible(key) {
        switch (key) {
        case "song": return root.songTextVisible;
        case "progress": return root.progressBarVisible;
        case "volume": return root.volumeControlVisible;
        case "controls": return root.shuffleVisible || root.playbackControlsVisible || root.loopVisible;
        }
        return false;
    }

    // Pin / keep-open button. When pinned the popup stays open on deactivation.
    CommandIcon {
        id: pinButton
        visible: root.showPinButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: 20
        size: Kirigami.Units.iconSizes.smallMedium
        source: widget.hideOnWindowDeactivate ? "pin" : "window-pin"
        active: !widget.hideOnWindowDeactivate
        onClicked: widget.hideOnWindowDeactivate = !widget.hideOnWindowDeactivate
    }
}
