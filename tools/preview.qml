/*
    Onyx — offline preview.

    Stands in for everything SDDM injects into a greeter (sddm, userModel,
    sessionModel, screenModel, keyboard, config) so the theme can be looked at,
    and photographed, without taking over a real screen. The fake sddm.login()
    replays a howdy conversation: a scan, a rejection, then the failure.

        qml6 tools/preview.qml                      # on screen
        qml6 tools/preview.qml -- --grab /tmp/onyx.png   # snapshot, then quit

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window

Window {
    id: win

    width: 1600
    height: 900
    visible: true
    color: "black"
    title: "Onyx preview"

    /* ---- the objects SDDM would provide ------------------------------- */

    QtObject {
        id: config

        readonly property string caption: "host"
        readonly property string showCaption: "true"
        readonly property string showClock: "true"
        readonly property string showFaceUnlock: "true"
    }

    ListModel {
        id: screenModel

        Component.onCompleted: append({ geometry: Qt.rect(0, 0, win.width, win.height) })
    }

    ListModel {
        id: userModel

        property int lastIndex: 0
        property string lastUser: "user"
        property int disableAvatarsThreshold: 7
        property bool containsAllUsers: true

        ListElement {
            name: "user"
            realName: "User"
            icon: ""
            needsPassword: true
        }
    }

    ListModel {
        id: sessionModel

        property int lastIndex: 0

        ListElement { name: "Plasma (Wayland)"; file: "plasmawayland.desktop"; comment: "" }
        ListElement { name: "Plasma (X11)"; file: "plasma.desktop"; comment: "" }
    }

    QtObject {
        id: keyboard

        property var layouts: [{ shortName: "us", longName: "English (US)" }]
        property int currentLayout: 0
    }

    QtObject {
        id: sddm

        readonly property bool canSuspend: true
        readonly property bool canHibernate: false
        readonly property bool canReboot: true
        readonly property bool canPowerOff: true
        readonly property string hostName: "host"

        signal loginFailed()
        signal loginSucceeded()
        signal informationMessage(string message)

        function login(user, password, session) {
            conversation.secretGiven = password.length > 0;
            conversation.step = 0;
            conversation.restart();
        }

        function suspend() { console.log("suspend()"); }
        function reboot() { console.log("reboot()"); }
        function powerOff() { console.log("powerOff()"); }
        function hibernate() { console.log("hibernate()"); }
    }

    /* A face scan the way pam_howdy runs one, with detection_notice on. */
    Timer {
        id: conversation

        property int step: 0
        property bool secretGiven: false

        interval: 1200
        repeat: true
        onTriggered: {
            step += 1;
            if (step === 1) {
                sddm.informationMessage("Scanning face…");
            } else if (step === 2) {
                sddm.informationMessage(secretGiven
                    ? "Face verification skipped: password given"
                    : "Face verification failed: camera image too dark");
            } else {
                running = false;
                sddm.loginFailed();
            }
        }
    }

    /* ---- the theme itself --------------------------------------------- */

    Loader {
        id: themeLoader

        anchors.fill: parent
        source: Qt.resolvedUrl("../sddm/Main.qml")

        onStatusChanged: {
            if (status === Loader.Error) {
                console.log("theme failed to load");
            }
        }
    }

    /* ---- offscreen snapshot ------------------------------------------- */

    readonly property string grabPath: {
        const args = Qt.application.arguments;
        const i = args.indexOf("--grab");
        return (i >= 0 && i + 1 < args.length) ? args[i + 1] : "";
    }

    /* When photographing, start a face scan first so the status line is in the
       picture — that path is the whole point of the theme. */
    Timer {
        interval: 900
        running: win.grabPath.length > 0
        onTriggered: sddm.login("user", "")
    }

    Timer {
        interval: 2600
        running: win.grabPath.length > 0
        onTriggered: win.contentItem.grabToImage(function(result) {
            result.saveToFile(win.grabPath);
            Qt.quit();
        })
    }
}
