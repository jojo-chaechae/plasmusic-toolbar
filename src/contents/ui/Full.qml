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

    enum AlbumCoverAlignment {
        Top,
        Middle,
        Bottom
    }

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
    property int albumCoverVerticalAlignment: plasmoid.configuration.fullAlbumCoverVerticalAlignment
    property int albumCoverPadding: plasmoid.configuration.fullAlbumCoverPadding
    // Horizontal padding for the content components (text, slider, volume, controls).
    property int contentPadding: plasmoid.configuration.fullViewContentPadding
    property int contentBottomPadding: plasmoid.configuration.fullViewContentPaddingBottom
    property bool progressBarVisible: plasmoid.configuration.fullViewProgressBarVisible
    property bool volumeControlVisible: plasmoid.configuration.fullViewVolumeControlVisible
    property bool shuffleVisible: plasmoid.configuration.fullViewShuffleVisible
    property bool playbackControlsVisible: plasmoid.configuration.fullViewPlaybackControlsVisible
    property bool loopVisible: plasmoid.configuration.fullViewLoopVisible
    property bool playbackControlsFitWidth: plasmoid.configuration.fullViewPlaybackControlsFillWidth
    property bool songTextVisible: plasmoid.configuration.fullViewSongTextVisible
    property int songTextAlignment: plasmoid.configuration.fullViewSongTextAlignment
    property bool lyricsVisible: plasmoid.configuration.fullViewLyricsVisible
    property int lyricsLineCount: plasmoid.configuration.fullViewLyricsLineCount
    // Vertical order of the content rows (any permutation of: song, progress, volume, controls, lyrics)
    readonly property var contentOrder: {
        const order = plasmoid.configuration.fullViewVerticalOrder.split(",").filter(key => key)
        if (!order.includes("lyrics")) order.push("lyrics")
        return order
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
    readonly property real naturalThumbHeight: thumbnailVisible && thumbnailContainer.imageRatio > 0
        ? effectiveMinWidth / thumbnailContainer.imageRatio
        : 0
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

        spacing: 0
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

        Rectangle {
            id: thumbnailContainer
            visible: thumbnailVisible
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            Layout.minimumHeight: 0
            // Use the actual image aspect ratio, fallback to square if not loaded yet
            readonly property real imageRatio: albumArtNormal.implicitWidth > 0 && albumArtNormal.implicitHeight > 0
                ? albumArtNormal.implicitWidth / albumArtNormal.implicitHeight
                : 1.0
            // Preferred height is stable (not tied to the current width) so the popup height
            // stays independent of the width. Extra vertical space is absorbed here.
            Layout.preferredHeight: root.naturalThumbHeight
            color: 'transparent'

            PlasmaComponents3.ToolTip {
                id: raisePlayerTooltip
                anchors.centerIn: parent
                text: player.canRaise ? i18n("Bring player to the front") : i18n("This player can't be raised")
                visible: !plasmoid.configuration.hideCanBeRaisedTooltip && coverMouseArea.containsMouse
            }

            MouseArea {
                id: coverMouseArea
                anchors.fill: parent
                cursorShape: player.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (player.canRaise) player.raise()
                }
                hoverEnabled: true
            }

            ImageWithPlaceholder {
                visible: !albumCoverBackground
                id: albumArtNormal
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real padding: root.albumCoverPadding
                readonly property real availWidth: Math.max(0, thumbnailContainer.width - 2 * padding)
                readonly property real availHeight: Math.max(0, thumbnailContainer.height - 2 * padding)
                // Fit the artwork to the padded container while honoring the chosen vertical alignment.
                readonly property real fittedWidth: availWidth > 0
                    ? Math.min(availWidth, availHeight * thumbnailContainer.imageRatio)
                    : 0
                readonly property real fittedHeight: availHeight > 0
                    ? Math.min(availHeight, availWidth / thumbnailContainer.imageRatio)
                    : 0
                width: fittedWidth
                height: fittedHeight
                y: root.albumCoverVerticalAlignment === Full.AlbumCoverAlignment.Top
                    ? padding
                    : root.albumCoverVerticalAlignment === Full.AlbumCoverAlignment.Bottom
                        ? thumbnailContainer.height - padding - height
                        : padding + (availHeight - height) / 2
                fillMode: Image.PreserveAspectFit

                placeholderSource: albumPlaceholder
                imageSource: player.artUrl

                layer.enabled: root.fullAlbumCoverRounded && root.albumCoverRadius > 0
                layer.effect: OpacityMask {
					maskSource: Item {
						width: albumArtNormal.width
						height: albumArtNormal.height
						Rectangle {
							anchors.fill: parent
							radius: albumCoverRadius
						}
					}
				}
            }
        }

        Repeater {
            model: root.contentOrder
            delegate: Loader {
                visible: item ? item.visible : true
                Layout.fillWidth: true
                Layout.leftMargin: root.contentPadding
                Layout.rightMargin: root.contentPadding
                Layout.topMargin: modelData === "song" ? 5 : modelData === "volume" ? 10 : 0
                sourceComponent: root.contentComponent(modelData)
            }
        }

        // Bottom padding for the content
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.contentBottomPadding
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
        id: lyricsComponent
        MiniLyrics {
            visible: root.lyricsVisible && lyricsManager.lines.length > 0
            lines: lyricsManager.lines
            currentLine: lyricsManager.currentLine
            lineCount: root.lyricsLineCount
            textFont: baseFont
            textColor: root.useAlbumContrastText ? imageColors.fgColor : Kirigami.Theme.textColor
            scrollingEnabled: widget.expanded
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
        case "lyrics": return lyricsComponent;
        }
        return null;
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
