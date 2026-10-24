/*
    Onyx — shared backdrop.

    This one file is the entire visual bond between the login screen and the
    lock screen. It is installed twice, byte for byte:

      /usr/share/sddm/themes/onyx/Backdrop.qml
      ~/.local/share/plasma/wallpapers/org.lckt0.onyx/contents/ui/Backdrop.qml

    Everything it draws is derived from the screen rectangle alone — no font
    metrics, no grid units, no knowledge of the widgets in front of it — so the
    two screens cannot drift out of alignment no matter which greeter is
    hosting it.

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

Item {
    id: backdrop

    /* Caption printed inside the top-left corner, usually the host name. */
    property string caption: ""
    property bool showCaption: true

    /* Pure black: this panel is OLED, so the ground is genuinely unlit. */
    readonly property color ground: "#000000"
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.08)
    readonly property color tickColor: Qt.rgba(1, 1, 1, 0.28)
    readonly property color captionColor: Qt.rgba(1, 1, 1, 0.30)

    /* Frame inset and tick length track the short edge, clamped so the motif
       keeps its proportions from 1366x768 up to 4K. */
    readonly property real inset: Math.max(16, Math.min(52, Math.round(Math.min(width, height) * 0.028)))
    readonly property real tickLength: Math.max(18, Math.min(56, Math.round(Math.min(width, height) * 0.030)))
    readonly property real hair: 1
    readonly property real tickWeight: 2

    Rectangle {
        anchors.fill: parent
        color: backdrop.ground
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: backdrop.inset
        color: "transparent"
        border.width: backdrop.hair
        border.color: backdrop.hairline
    }

    /* Four L-shaped corner ticks, brighter than the frame they sit on.
       index: 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right. */
    Repeater {
        model: 4

        delegate: Item {
            id: corner

            required property int index

            readonly property bool atRight: index % 2 === 1
            readonly property bool atBottom: index >= 2
            readonly property real cx: atRight ? frame.x + frame.width : frame.x
            readonly property real cy: atBottom ? frame.y + frame.height : frame.y

            Rectangle {
                x: corner.atRight ? corner.cx - width : corner.cx
                y: corner.cy - backdrop.tickWeight / 2
                width: backdrop.tickLength
                height: backdrop.tickWeight
                color: backdrop.tickColor
            }

            Rectangle {
                x: corner.cx - backdrop.tickWeight / 2
                y: corner.atBottom ? corner.cy - height : corner.cy
                width: backdrop.tickWeight
                height: backdrop.tickLength
                color: backdrop.tickColor
            }
        }
    }

    Text {
        visible: backdrop.showCaption && text.length > 0
        text: backdrop.caption
        color: backdrop.captionColor
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: 9
        font.letterSpacing: 1.6
        renderType: Text.NativeRendering
        anchors.left: frame.left
        anchors.top: frame.top
        anchors.leftMargin: backdrop.tickLength + Math.round(backdrop.inset * 0.5)
        anchors.topMargin: Math.round(backdrop.inset * 0.45)
    }
}
