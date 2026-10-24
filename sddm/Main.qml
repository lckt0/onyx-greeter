/*
    Onyx — SDDM greeter.

    Built on org.kde.breeze.components, the same QML module the Plasma lock
    screen is built on, so the avatar, the clock, the action buttons and the
    rejected-password animation are literally the same widgets on both screens
    rather than a lookalike. Colours come from the active colour scheme
    (BreezeTrueBlack), which the lock screen reads too.

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kirigami as Kirigami

import org.kde.breeze.components

Item {
    id: root

    width: 1600
    height: 900

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    /* Accumulated status line shown above the password field. Face-recognition
       progress from pam_howdy arrives here through sddm.informationMessage,
       which is the same channel and the same position the lock screen uses. */
    property string notificationMessage

    /* True from the moment credentials are handed to PAM until it answers.
       While it is set the status line is left alone: a face scan takes a few
       seconds and its progress must not be wiped by the idle reset timer. */
    property bool authenticating: false

    function handleMessage(msg) {
        if (!msg) {
            return;
        }
        if (!root.notificationMessage) {
            root.notificationMessage = msg;
        } else if (root.notificationMessage.includes(msg)) {
            userListComponent.playHighlightAnimation();
        } else {
            root.notificationMessage += "\n" + msg;
        }
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Repeater {
        model: screenModel

        Backdrop {
            x: geometry.x
            y: geometry.y
            width: geometry.width
            height: geometry.height
            caption: config.caption
            showCaption: config.showCaption === "true"
        }
    }

    RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: mainStack
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1
            || userListComponent.mainPasswordBox.text.length > 0
            || inputPanel.keyboardActive
            || root.authenticating

        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true
        onPositionChanged: uiVisible = true
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: event => {
            uiVisible = true;
            event.accepted = false;
        }

        /* Idle: everything but the clock steps back. The lock screen does the
           same thing after ten seconds; a login screen is looked at, not sat
           in front of, so it gets a minute. */
        Timer {
            id: fadeoutTimer
            running: true
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    userListComponent.mainPasswordBox.showPassword = false;
                    loginScreenRoot.uiVisible = false;
                }
            }
        }

        Clock {
            id: clock
            visible: y > 0 && config.showClock === "true"
            anchors.horizontalCenter: parent.horizontalCenter
            /* Same expression the lock screen uses, so the clock lands on the
               same baseline on both screens. */
            y: (userListComponent.userList.y + mainStack.y) / 2 - height / 2
            Layout.alignment: Qt.AlignBaseline
        }

        QQC2.StackView {
            id: mainStack

            anchors {
                left: parent.left
                right: parent.right
            }
            height: root.height + Kirigami.Units.gridUnit * 3

            opacity: loginScreenRoot.uiVisible ? 1 : 0
            visible: opacity > 0
            enabled: !root.authenticating
            hoverEnabled: loginScreenRoot.uiVisible ? undefined : false
            focus: true

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.veryLongDuration
                    easing.type: Easing.InOutQuad
                }
            }

            /* SDDM can leave the window itself unfocused even once the right
               item inside it has focus; nudge it after the window is up. */
            Timer {
                running: true
                repeat: false
                interval: 200
                onTriggered: mainStack.forceActiveFocus()
            }

            initialItem: Login {
                id: userListComponent

                userListModel: userModel
                loginScreenUiVisible: loginScreenRoot.uiVisible
                authenticating: root.authenticating
                userListCurrentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                lastUserName: userModel.lastUser
                showUserList: {
                    if (!userListModel.hasOwnProperty("count")
                        || !userListModel.hasOwnProperty("disableAvatarsThreshold")) {
                        return false;
                    }
                    if (userListModel.count === 0) {
                        return false;
                    }
                    if (userListModel.hasOwnProperty("containsAllUsers") && !userListModel.containsAllUsers) {
                        return false;
                    }
                    return userListModel.count <= userListModel.disableAvatarsThreshold;
                }

                notificationMessage: {
                    const parts = [];
                    if (capsLockState.locked) {
                        parts.push("Caps Lock is on");
                    }
                    if (root.notificationMessage) {
                        parts.push(root.notificationMessage);
                    }
                    return parts.join(" • ");
                }

                actionItemsVisible: !inputPanel.keyboardActive
                actionItems: [
                    ActionButton {
                        icon.name: "camera-web"
                        text: "Face Unlock"
                        visible: config.showFaceUnlock === "true"
                        enabled: !root.authenticating
                        /* Deliberate, never automatic. Handing PAM an empty
                           password is a real authentication attempt: if the
                           scan fails it falls through to pam_unix and
                           pam_faillock counts it. See README. */
                        onClicked: userListComponent.startFaceLogin()
                    },
                    ActionButton {
                        icon.name: "system-suspend"
                        text: "Sleep"
                        onClicked: sddm.suspend()
                        enabled: sddm.canSuspend
                    },
                    ActionButton {
                        icon.name: "system-reboot"
                        text: "Restart"
                        onClicked: sddm.reboot()
                        enabled: sddm.canReboot
                    },
                    ActionButton {
                        icon.name: "system-shutdown"
                        text: "Shut Down"
                        onClicked: sddm.powerOff()
                        enabled: sddm.canPowerOff
                    },
                    ActionButton {
                        icon.name: "system-user-prompt"
                        text: "Other…"
                        onClicked: mainStack.push(userPromptComponent)
                        visible: !userListComponent.showUsernamePrompt
                    }
                ]

                onLoginRequest: (username, password) => {
                    root.notificationMessage = "";
                    root.authenticating = true;
                    if (password.length === 0) {
                        // pam_howdy is what an empty secret is for; say so
                        // before PAM gets around to printing anything.
                        root.handleMessage("Looking for your face…");
                    }
                    sddm.login(username, password, sessionButton.currentIndex);
                }
            }

            readonly property real zoomFactor: 1.5

            popEnter: Transition {
                ScaleAnimator { from: mainStack.zoomFactor; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
            popExit: Transition {
                ScaleAnimator { from: 1; to: 1 / mainStack.zoomFactor; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
            pushEnter: Transition {
                ScaleAnimator { from: 1 / mainStack.zoomFactor; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
            pushExit: Transition {
                ScaleAnimator { from: 1; to: mainStack.zoomFactor; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
        }

        VirtualKeyboardLoader {
            id: inputPanel

            z: 1

            screenRoot: root
            mainStack: mainStack
            mainBlock: userListComponent
            passwordField: userListComponent.mainPasswordBox
        }

        Component {
            id: userPromptComponent

            Login {
                showUsernamePrompt: true
                notificationMessage: root.notificationMessage
                loginScreenUiVisible: loginScreenRoot.uiVisible
                authenticating: root.authenticating
                fontSize: Kirigami.Theme.defaultFont.pointSize + 2

                /* The user list is the point of the login screen; this branch
                   is the manual fallback, so it carries no avatars. */
                userListModel: QtObject {
                    readonly property string name: "Log in as a different user"
                    readonly property string iconSource: ""
                }

                onLoginRequest: (username, password) => {
                    root.notificationMessage = "";
                    root.authenticating = true;
                    if (password.length === 0) {
                        // pam_howdy is what an empty secret is for; say so
                        // before PAM gets around to printing anything.
                        root.handleMessage("Looking for your face…");
                    }
                    sddm.login(username, password, sessionButton.currentIndex);
                }

                actionItems: [
                    ActionButton {
                        icon.name: "go-previous"
                        text: "Back"
                        onClicked: mainStack.pop()
                    }
                ]
            }
        }

        /* Keep in sync with the lock screen footer: same controls, same order,
           same corner. */
        RowLayout {
            id: footer

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.smallSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            opacity: loginScreenRoot.uiVisible ? 1 : 0
            enabled: !root.authenticating

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.veryLongDuration
                    easing.type: Easing.InOutQuad
                }
            }

            PlasmaComponents3.ToolButton {
                id: virtualKeyboardButton

                text: "Virtual Keyboard"
                icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                visible: inputPanel.status === Loader.Ready
                onClicked: {
                    userListComponent.mainPasswordBox.forceActiveFocus();
                    inputPanel.showHide();
                }

                Layout.fillHeight: true
            }

            KeyboardButton {
                id: keyboardButton

                onKeyboardLayoutChanged: userListComponent.mainPasswordBox.forceActiveFocus()

                Layout.fillHeight: true
            }

            SessionButton {
                id: sessionButton

                onSessionChanged: userListComponent.mainPasswordBox.forceActiveFocus()

                Layout.fillHeight: true
            }

            Item {
                Layout.fillWidth: true
            }

            Battery {}
        }
    }

    Connections {
        target: sddm

        /* Everything PAM says on its way through — including every line
           pam_howdy prints while it looks for a face. */
        function onInformationMessage(message) {
            root.handleMessage(message);
        }

        function onLoginFailed() {
            root.authenticating = false;
            root.handleMessage("Login failed");
            rejectPasswordAnimation.start();
        }

        function onLoginSucceeded() {
            root.authenticating = false;
            // SDDM kills the greeter at some arbitrary point after this, so
            // nothing here is guaranteed to finish.
            mainStack.opacity = 0;
            footer.opacity = 0;
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.restart();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 4000
        /* Never clear mid-scan: pam_howdy is allowed four seconds per attempt
           and its progress line is the only feedback there is. */
        onTriggered: {
            if (root.authenticating) {
                notificationResetTimer.restart();
            } else {
                root.notificationMessage = "";
            }
        }
    }
}
