/*
    Onyx — on-screen keyboard, whichever way this Plasma provides it.

    Plasma 6.7 ships VirtualKeyboardLoader in org.kde.breeze.components; 6.8
    dropped it and leaves the keyboard to KWin. The 6.7 path is tried first
    because on 6.8 it fails cleanly at load time ("not a type"), which is the
    signal to fall back to KWin.

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

Loader {
    id: osk

    property Item screenRoot
    property Item mainStack
    property Item mainBlock
    property Item passwordField

    readonly property bool keyboardActive: item ? item.keyboardActive : false
    readonly property bool available: item ? item.available : false

    function showHide() {
        if (item) {
            item.showHide();
        }
    }

    source: "OnScreenKeyboardLegacy.qml"

    onStatusChanged: {
        if (status === Loader.Error && source.toString().indexOf("Legacy") !== -1) {
            source = "OnScreenKeyboardKWin.qml";
        }
    }

    onLoaded: {
        if (item.screenRoot !== undefined) {
            item.screenRoot = Qt.binding(() => osk.screenRoot);
            item.mainStack = Qt.binding(() => osk.mainStack);
            item.mainBlock = Qt.binding(() => osk.mainBlock);
            item.passwordField = Qt.binding(() => osk.passwordField);
        }
    }
}
