/*
    Onyx — on-screen keyboard for Plasma 6.8 and later (KWin's input method).

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.workspace.keyboardlayout as Keyboards

Item {
    property Item screenRoot
    property Item mainStack
    property Item mainBlock
    property Item passwordField

    readonly property bool keyboardActive: Keyboards.KWinVirtualKeyboard.visible
    readonly property bool available: Keyboards.KWinVirtualKeyboard.available

    function showHide() {
        if (Keyboards.KWinVirtualKeyboard.visible) {
            Keyboards.KWinVirtualKeyboard.active = false;
        } else {
            // Focus first, or the keystrokes have nowhere to go.
            passwordField.forceActiveFocus();
            Keyboards.KWinVirtualKeyboard.forceActivate();
        }
    }
}
