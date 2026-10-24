/*
    Onyx — lock-screen backdrop.

    A wallpaper plugin is the one surface Plasma 6 lets a theme paint on the
    lock screen without replacing the shell package that owns the unlock
    widget. It draws the same Backdrop.qml the SDDM theme draws, so the two
    screens share their ground, their frame and their corner marks; the unlock
    widget on top stays Plasma's own, coloured by the active colour scheme.

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    Backdrop {
        anchors.fill: parent
        caption: root.configuration.Caption
        showCaption: root.configuration.ShowCaption
    }
}
