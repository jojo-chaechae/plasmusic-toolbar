import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import Qt5Compat.GraphicalEffects

Item {
    id: root

    enum MediaOrder {
        AlbumArtFirst,
        LyricsFirst
    }

    property string albumPlaceholder: ""
    property string artUrl: ""
    property bool albumArtVisible: true
    property bool albumCoverBackground: false
    property bool albumCoverRounded: true
    property int albumCoverRadius: 6
    property bool canRaise: false
    property bool raiseOnAlbumArtClick: true
    property bool canSeek: false
    property bool hideRaiseTooltip: false

    property bool lyricsVisible: false
    property var lyricsLines: []
    property var lyricsTimestamps: []
    property bool lyricsAvailable: false
    property int currentLine: -1
    property int currentLineDuration: 0
    property int lyricsAlignment: Qt.AlignHCenter
    property int mediaSpacing: Kirigami.Units.smallSpacing
    property int lyricsFontSize: 0
    property real lyricsLineSpacing: 1.35
    property int lyricsAnimation: 0
    property color lyricsAnimationColor: Kirigami.Theme.highlightColor
    property font textFont: Kirigami.Theme.defaultFont
    property color lyricsTextColor: Kirigami.Theme.textColor
    property bool scrollingEnabled: true
    property int mediaOrder: MediaContent.MediaOrder.AlbumArtFirst

    signal raiseRequested()
    signal seekRequested(timestamp: double)

    readonly property bool hasLyrics: lyricsVisible && lyricsAvailable
    readonly property bool hasMedia: albumArtVisible || hasLyrics
    property real imageRatio: 1.0
    property real albumArtHeight: 0

    readonly property bool bothVisible: albumArtVisible && hasLyrics
    readonly property real lyricPixelSize: lyricsFontSize > 0 ? lyricsFontSize : textFont.pixelSize
    readonly property real minimumLyricsHeight: Math.max(Kirigami.Units.gridUnit, lyricPixelSize * lyricsLineSpacing)
    readonly property real albumArtAllocatedHeight: albumArtVisible ? albumArtHeight : 0
    readonly property real lyricsHeight: hasLyrics
        ? Math.max(minimumLyricsHeight, height - (albumArtVisible ? albumArtHeight + mediaSpacing : 0))
        : 0

    visible: hasMedia
    implicitHeight: bothVisible
        ? albumArtHeight + mediaSpacing + minimumLyricsHeight
        : albumArtVisible ? albumArtHeight : minimumLyricsHeight
    Layout.fillWidth: true
    Layout.minimumHeight: 0

    Loader {
        id: albumArtLoader
        visible: root.albumArtVisible
        x: 0
        y: root.mediaOrder === MediaContent.MediaOrder.AlbumArtFirst
            ? 0
            : root.hasLyrics ? root.lyricsHeight + root.mediaSpacing : 0
        width: root.width
        height: root.albumArtAllocatedHeight
        sourceComponent: albumArtComponent
    }

    Loader {
        id: lyricsLoader
        visible: root.hasLyrics
        x: 0
        y: root.mediaOrder === MediaContent.MediaOrder.LyricsFirst
            ? 0
            : root.albumArtVisible ? root.albumArtAllocatedHeight + root.mediaSpacing : 0
        width: root.width
        height: root.lyricsHeight
        sourceComponent: lyricsComponent
    }

    Component {
        id: albumArtComponent

        Item {
            id: albumArtItem
            anchors.fill: parent
            visible: root.albumArtVisible
            implicitHeight: root.albumArtHeight
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.albumArtHeight
            Layout.minimumHeight: 0

            PlasmaComponents3.ToolTip {
                anchors.centerIn: parent
                text: root.canRaise ? i18n("Bring player to the front") : i18n("This player can't be raised")
                visible: root.raiseOnAlbumArtClick && !root.hideRaiseTooltip && coverMouseArea.containsMouse
            }

            MouseArea {
                id: coverMouseArea
                anchors.fill: parent
                cursorShape: root.raiseOnAlbumArtClick && root.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
                hoverEnabled: true
                enabled: root.raiseOnAlbumArtClick
                onClicked: {
                    if (root.canRaise) root.raiseRequested()
                }
            }

            ImageWithPlaceholder {
                id: albumArt
                visible: !root.albumCoverBackground
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property real padding: 0
                readonly property real availWidth: Math.max(0, albumArtItem.width)
                readonly property real availHeight: Math.max(0, albumArtItem.height)
                readonly property real fittedWidth: availWidth > 0
                    ? Math.min(availWidth, availHeight * root.imageRatio)
                    : 0
                readonly property real fittedHeight: availHeight > 0
                    ? Math.min(availHeight, availWidth / root.imageRatio)
                    : 0

                width: fittedWidth
                height: fittedHeight
                y: (albumArtItem.height - height) / 2
                fillMode: Image.PreserveAspectFit
                placeholderSource: root.albumPlaceholder
                imageSource: root.artUrl

                Component.onCompleted: root.updateImageRatio(implicitWidth, implicitHeight)
                onImplicitWidthChanged: root.updateImageRatio(implicitWidth, implicitHeight)
                onImplicitHeightChanged: root.updateImageRatio(implicitWidth, implicitHeight)

                layer.enabled: root.albumCoverRounded && root.albumCoverRadius > 0
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: albumArt.width
                        height: albumArt.height
                        Rectangle {
                            anchors.fill: parent
                            radius: root.albumCoverRadius
                        }
                    }
                }
            }
        }
    }

    Component {
        id: lyricsComponent

        MiniLyrics {
            visible: root.hasLyrics
            lines: root.lyricsLines
            lineTimestamps: root.lyricsTimestamps
            currentLine: root.currentLine
            currentLineDuration: root.currentLineDuration
            horizontalAlignment: root.lyricsAlignment
            fontSize: root.lyricsFontSize
            lineSpacing: root.lyricsLineSpacing
            animationMode: root.lyricsAnimation
            animationColor: root.lyricsAnimationColor
            textFont: root.textFont
            textColor: root.lyricsTextColor
            scrollingEnabled: root.scrollingEnabled
            seekEnabled: root.canSeek
            onSeekRequested: (timestamp) => root.seekRequested(timestamp)
        }
    }

    function mediaComponent(key) {
        return key === "albumArt" ? albumArtComponent : lyricsComponent
    }

    function updateImageRatio(width, height) {
        if (width > 0 && height > 0) imageRatio = width / height
    }
}
