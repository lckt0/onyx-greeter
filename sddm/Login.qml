/*
    Onyx — the prompt block of the login screen.

    Deliberately the same shape as the lock screen's MainBlock.qml: a
    SessionManagementScreen carrying the avatar list, one status line, a
    password field and a round submit button, in that order.

    SPDX-FileCopyrightText: 2026 lckt0
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

import org.kde.breeze.components

SessionManagementScreen {
    id: root

    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList
    property string lastUserName
    property bool loginScreenUiVisible: false

    /* Set by Main.qml while PAM is working. */
    property bool authenticating: false

    property real fontSize: Kirigami.Theme.defaultFont.pointSize

    // The y position that should stay visible when the on-screen keyboard is up
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    signal loginRequest(string username, string password)

    /* Dim the avatar row while the scan runs, so it is obvious that something
       is happening even before PAM has said anything. A Binding element cannot
       live here: this component's default property is a list of Items. */
    onAuthenticatingChanged: userList.opacity = authenticating ? 0.75 : 1

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = "";
        }
    }

    onUserSelected: {
        // Not startLogin(): this signal is also wired to the Escape key.
        passwordBox.clear();
        focusFirstVisibleFormControl();
    }

    QQC2.StackView.onActivating: {
        // Controls are not visible yet at this point.
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible ? passwordBox : loginButton));
        // TabFocusReason so the submit button picks up the visual highlight.
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    function currentUserName() {
        return showUsernamePrompt ? userNameInput.text : userList.selectedUser;
    }

    function startLogin() {
        // Partly cosmetic, but mainly a workaround for QTBUG-55460: closing the
        // app with a focused TextField can crash.
        loginButton.forceActiveFocus();
        root.loginRequest(currentUserName(), passwordBox.text);
    }

    /* Face unlock: hand PAM an empty secret so pam_howdy, which sits in front
       of pam_unix as `sufficient`, gets its turn. Kept as an explicit action
       rather than something that fires on its own — a failed scan falls
       through to pam_unix and pam_faillock counts it. */
    function startFaceLogin() {
        passwordBox.clear();
        loginButton.forceActiveFocus();
        root.loginRequest(currentUserName(), "");
    }

    PlasmaComponents3.TextField {
        id: userNameInput

        font.pointSize: root.fontSize + 1
        Layout.fillWidth: true

        text: root.lastUserName
        visible: root.showUsernamePrompt
        // With a username prompt present it takes focus first, otherwise the
        // password field does.
        focus: root.showUsernamePrompt && !root.lastUserName
        placeholderText: "Username"

        onAccepted: {
            if (root.loginScreenUiVisible) {
                passwordBox.forceActiveFocus();
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaExtras.PasswordField {
            id: passwordBox

            font.pointSize: root.fontSize + 1
            Layout.fillWidth: true

            placeholderText: "Password"
            focus: !root.showUsernamePrompt || root.lastUserName
            visible: root.showUsernamePrompt || root.userList.currentItem.needsPassword

            // SDDM does not load the Breeze icon set, so the reveal action
            // would render as a blank square.
            rightActions: []

            onAccepted: {
                if (root.loginScreenUiVisible) {
                    root.startLogin();
                }
            }

            Keys.onEscapePressed: mainStack.currentItem.forceActiveFocus()

            // Empty field plus left/right walks the user list. This cannot live
            // in Keys.onLeftPressed, or it never reaches the field.
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && !text) {
                    root.userList.decrementCurrentIndex();
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Right && !text) {
                    root.userList.incrementCurrentIndex();
                    event.accepted = true;
                }
            }

            Connections {
                target: sddm
                function onLoginFailed() {
                    passwordBox.selectAll();
                    passwordBox.forceActiveFocus();
                }
            }
        }

        PlasmaComponents3.Button {
            id: loginButton

            Accessible.name: "Log in"
            Layout.preferredHeight: passwordBox.implicitHeight
            Layout.preferredWidth: text.length === 0 ? loginButton.Layout.preferredHeight : -1

            icon.name: text.length === 0 ? (root.LayoutMirroring.enabled ? "go-previous" : "go-next") : ""
            text: root.showUsernamePrompt || root.userList.currentItem.needsPassword ? "" : "Log In"

            onClicked: root.startLogin()
            Keys.onEnterPressed: clicked()
            Keys.onReturnPressed: clicked()
        }
    }
}
