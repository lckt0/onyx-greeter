/*
    Onyx — on-screen keyboard for Plasma 6.7 (Qt Virtual Keyboard).

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.breeze.components

Item {
    id: legacy

    property Item screenRoot
    property Item mainStack
    property Item mainBlock
    property Item passwordField

    readonly property bool keyboardActive: loader.keyboardActive
    readonly property bool available: loader.status === Loader.Ready

    function showHide() {
        passwordField.forceActiveFocus();
        loader.showHide();
    }

    VirtualKeyboardLoader {
        id: loader

        screenRoot: legacy.screenRoot
        mainStack: legacy.mainStack
        mainBlock: legacy.mainBlock
        passwordField: legacy.passwordField
    }
}
