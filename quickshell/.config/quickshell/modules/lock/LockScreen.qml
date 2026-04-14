pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs.config
import qs.services

WlSessionLock {
    id: root
    property string authMode: "fingerprint"
    property bool fingerprintActive: false
    property bool fingerprintAvailable: true
    property string fingerprintHint: "Touch fingerprint sensor or enter password"
    property int fingerprintRetryCount: 0
    property string fingerprintState: "idle"

    // Set locked on creation — NOT bound to LockService.locked
    // This avoids the race condition where Loader destruction and protocol
    // unlock happen simultaneously
    locked: true

    onLockStateChanged: {
        // Protocol unlock complete → defer LockService.unlock() to the next
        // event loop so surface destruction finishes cleanly before the Loader
        // tries to destroy this component (avoids "invalid context" warning)
        if (!locked)
            Qt.callLater(LockService.unlock);
    }

    WlSessionLockSurface {
        color: Config.backgroundColor

        Component.onCompleted: {
            passwordInput.forceActiveFocus();
            if (root.fingerprintAvailable)
                root.authMode = "fingerprint";
            else
                root.authMode = "password";
            if (root.authMode === "fingerprint")
                fingerprintStartupTimer.start();
        }

        Component.onDestruction: {
            fingerprintRetryTimer.stop();
            fingerprintStartupTimer.stop();
            if (fingerprintProc.running)
                fingerprintProc.running = false;
        }

        function startFingerprintVerify() {
            if (!root.locked || LockService.authenticating || !root.fingerprintAvailable || root.authMode !== "fingerprint")
                return;
            
            // Stop existing process if running
            if (fingerprintProc.running)
                return;
            
            root.fingerprintActive = true;
            root.fingerprintRetryCount++;
            root.fingerprintHint = "Scanning... (attempt #" + root.fingerprintRetryCount + ")";
            root.fingerprintState = "scanning";
            fingerprintProc.running = true;
        }

        Process {
            id: fingerprintProc
            command: ["fprintd-verify", Quickshell.env("USER")]
            
            onRunningChanged: {}

            stdout: SplitParser {
                onRead: data => {
                    const line = data.trim();
                    if (line === "")
                        return;

                    if (line.indexOf("verify-match") !== -1) {
                        root.fingerprintHint = "✓ Fingerprint accepted";
                        root.fingerprintActive = false;
                        root.fingerprintState = "success";
                        fingerprintRetryTimer.stop();
                        if (fingerprintProc.running)
                            fingerprintProc.running = false;
                        LockService.unlockWithBiometric();
                        return;
                    }

                    if (line.indexOf("verify-no-match") !== -1) {
                        root.fingerprintHint = "✗ No match. Try again (attempt #" + (root.fingerprintRetryCount + 1) + ")";
                        root.fingerprintState = "error";
                    }
                    
                    // Capture other status messages from fprintd-verify
                    if (line.indexOf("finger on") !== -1 || line.indexOf("Remove") !== -1) {
                        root.fingerprintHint = line;
                    }
                }
            }

            stderr: SplitParser {
                onRead: data => {
                    const line = data.trim();
                    if (line === "")
                        return;

                    if (line.indexOf("No devices available") !== -1 || line.indexOf("not available") !== -1 || line.indexOf("command not found") !== -1) {
                        root.fingerprintAvailable = false;
                        root.fingerprintActive = false;
                        root.fingerprintHint = "Fingerprint unavailable, use password";
                        root.fingerprintState = "unavailable";
                        fingerprintRetryTimer.stop();
                        if (root.authMode === "fingerprint")
                            root.authMode = "password";
                    }
                }
            }

            onExited: code => {
                root.fingerprintActive = false;
                if (root.fingerprintState !== "success" && root.fingerprintState !== "unavailable" && root.fingerprintState !== "error")
                    root.fingerprintState = "idle";

                // Only restart timer if still locked, fingerprint available, and not authenticating
                if (root.locked && root.fingerprintAvailable && !LockService.authenticating && root.authMode === "fingerprint") {
                    fingerprintRetryTimer.start();
                }
            }
        }

        Timer {
            id: fingerprintStartupTimer
            interval: 300
            repeat: false
            onTriggered: {
                startFingerprintVerify();
            }
        }

        Timer {
            id: fingerprintRetryTimer
            interval: 1200
            repeat: false
            onTriggered: {
                startFingerprintVerify();
            }
        }


        // Capture clicks to refocus the hidden password input
        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }

        // ====================================================================
        // MAIN CONTENT
        // ====================================================================

        Column {
            id: content
            anchors.centerIn: parent
            spacing: 8
            opacity: 0

            Component.onCompleted: fadeIn.start()

            NumberAnimation {
                id: fadeIn
                target: content
                property: "opacity"
                from: 0
                to: 1
                duration: Config.animDurationLong
                easing.type: Easing.OutCubic
            }

            // Clock
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: TimeService.format("HH:mm")
                font.family: Config.font
                font.pixelSize: 64
                font.bold: true
                color: Config.accentColor
            }

            // Date
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: TimeService.format("dddd, dd MMMM yyyy")
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
                color: Config.subtextColor
            }

            Item {
                width: 1
                height: 16
            }

            Row {
                id: authModeToggle
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                function setMode(mode) {
                    if (root.authMode === mode)
                        return;
                    root.authMode = mode;
                    if (mode === "password") {
                        fingerprintRetryTimer.stop();
                        fingerprintStartupTimer.stop();
                        if (fingerprintProc.running)
                            fingerprintProc.running = false;
                        root.fingerprintActive = false;
                        root.fingerprintState = "idle";
                        passwordInput.forceActiveFocus();
                    } else if (mode === "fingerprint" && root.fingerprintAvailable) {
                        fingerprintStartupTimer.restart();
                    }
                }

                Rectangle {
                    width: 132
                    height: 34
                    radius: Config.radius
                    color: root.authMode === "fingerprint" ? Config.accentColor : Config.surface0Color
                    border.width: 1
                    border.color: root.authMode === "fingerprint" ? Config.accentColor : Config.surface2Color

                    Text {
                        anchors.centerIn: parent
                        text: "Fingerprint"
                        color: root.authMode === "fingerprint" ? Config.backgroundColor : Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.fingerprintAvailable
                        onClicked: authModeToggle.setMode("fingerprint")
                    }
                }

                Rectangle {
                    width: 132
                    height: 34
                    radius: Config.radius
                    color: root.authMode === "password" ? Config.accentColor : Config.surface0Color
                    border.width: 1
                    border.color: root.authMode === "password" ? Config.accentColor : Config.surface2Color

                    Text {
                        anchors.centerIn: parent
                        text: "Password"
                        color: root.authMode === "password" ? Config.backgroundColor : Config.subtextColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: authModeToggle.setMode("password")
                    }
                }
            }

            Item {
                width: 1
                height: 12
            }

            Item {
                id: fingerprintIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                width: 112
                height: 112
                visible: root.authMode === "fingerprint" && root.fingerprintAvailable

                property color ringColor: {
                    if (root.fingerprintState === "error")
                        return Config.errorColor;
                    return Config.accentColor;
                }

                Image {
                    id: fingerprintSvg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    source: 'data:image/svg+xml;utf8,<svg viewBox="0 0 192 192" xmlns="http://www.w3.org/2000/svg" fill="none"><path fill="%23000000" stroke="%23000000" stroke-width="4" d="M140.424 38.019a3.6 3.6 0 0 1-1.777-.462C123.81 29.934 110.983 26.7 95.528 26.7c-15.223 0-29.75 3.619-42.964 10.857-1.854 1.001-4.172.308-5.254-1.54-1.005-1.848-.31-4.235 1.545-5.236C63.228 22.85 78.992 19 95.528 19c16.537 0 30.91 3.619 46.673 11.55 1.932 1.155 2.628 3.465 1.623 5.313-.695 1.386-1.932 2.156-3.4 2.156ZM29.846 78.444a4.036 4.036 0 0 1-2.24-.693c-1.624-1.232-2.165-3.619-.928-5.39 7.65-10.78 17.386-19.25 28.977-25.179 24.419-12.474 55.328-12.551 79.669-.077 11.591 5.929 21.327 14.245 28.977 25.025 1.237 1.694.773 4.158-.927 5.39-1.777 1.232-4.173.847-5.409-.77-6.955-9.856-15.764-17.479-26.196-22.792-22.177-11.319-50.536-11.319-72.636.077-10.51 5.39-19.319 13.09-26.273 22.715-.618 1.155-1.778 1.694-3.014 1.694Zm48.296 92.939c-1.005 0-1.932-.385-2.705-1.155-6.722-6.699-10.354-11.011-15.532-20.328-5.332-9.471-8.113-21.021-8.113-33.418 0-22.869 19.627-41.503 43.736-41.503 24.11 0 43.737 18.634 43.737 41.503 0 1.021-.407 2-1.132 2.722a3.87 3.87 0 0 1-5.464 0 3.844 3.844 0 0 1-1.131-2.722c0-18.634-16.15-33.803-36.01-33.803-19.859 0-36.01 15.169-36.01 33.803 0 11.088 2.474 21.329 7.187 29.568 4.946 8.932 8.346 12.705 14.296 18.711a3.943 3.943 0 0 1 0 5.467c-.927.77-1.855 1.155-2.86 1.155Zm55.405-14.245c-9.196 0-17.309-2.31-23.955-6.853-11.514-7.777-18.391-20.405-18.391-33.803 0-1.021.407-2 1.132-2.722a3.871 3.871 0 0 1 5.464 0 3.843 3.843 0 0 1 1.131 2.722c0 10.857 5.564 21.098 14.991 27.412 5.487 3.696 11.9 5.467 19.628 5.467 1.854 0 4.945-.231 8.036-.77 2.087-.385 4.173 1.001 4.482 3.157.386 2.002-1.005 4.081-3.168 4.466-4.405.847-8.268.924-9.35.924ZM118.015 173h-1.005c-12.286-3.542-20.323-8.085-28.745-16.324-10.819-10.626-16.769-24.948-16.769-40.194 0-12.474 10.664-22.638 23.8-22.638 13.137 0 23.801 10.164 23.801 22.638 0 8.239 7.341 14.938 16.072 14.938 8.887 0 16.073-6.699 16.073-14.938 0-29.029-25.114-52.591-56.023-52.591-21.945 0-42.191 12.166-51.077 31.031-3.014 6.237-4.56 13.552-4.56 21.56 0 6.006.541 15.477 5.178 27.797.773 2.002-.232 4.235-2.241 4.928-2.01.693-4.25-.308-4.946-2.233-3.863-10.087-5.64-20.174-5.64-30.492 0-9.24 1.777-17.633 5.254-24.948 10.277-21.483 33.073-35.42 58.032-35.42 35.082 0 63.751 27.027 63.751 60.291 0 12.474-10.664 22.638-23.801 22.638-13.136 0-23.8-10.164-23.8-22.638 0-8.239-7.186-14.938-16.073-14.938-8.886 0-16.072 6.699-16.072 14.938 0 13.167 5.1 25.487 14.45 34.727 7.341 7.238 14.373 11.242 25.268 14.168 2.086.616 3.246 2.772 2.705 4.774-.387 1.771-2.009 2.926-3.632 2.926Z"/></svg>'
                }

                ColorOverlay {
                    anchors.fill: fingerprintSvg
                    source: fingerprintSvg
                    color: fingerprintIndicator.ringColor
                }

                SequentialAnimation {
                    id: successPulse
                    running: root.fingerprintState === "success"
                    NumberAnimation { target: fingerprintIndicator; property: "scale"; to: 1.08; duration: 120; easing.type: Easing.OutBack }
                    NumberAnimation { target: fingerprintIndicator; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                }
            }

            // Password field
            Rectangle {
                id: passwordField
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280
                height: 44
                radius: Config.radius
                color: Config.surface0Color
                border.width: 2
                visible: root.authMode === "password"
                border.color: LockService.failed ? Config.errorColor : passwordInput.activeFocus ? Config.accentColor : Config.surface2Color

                Behavior on border.color {
                    ColorAnimation {
                        duration: Config.animDurationShort
                    }
                }

                // Shake offset (applied via transform to not affect layout)
                property real shakeX: 0
                transform: Translate {
                    x: passwordField.shakeX
                }

                // Password dots
                Row {
                    visible: !LockService.authenticating
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: passwordInput.text.length

                        Rectangle {
                            required property int index
                            readonly property bool isLast: index === passwordInput.text.length - 1
                            width: 10
                            height: 10
                            radius: width / 2
                            color: Config.accentColor
                            scale: isLast ? 0.5 : 1
                            opacity: isLast ? 1.0 : 0.8

                            Component.onCompleted: scale = isLast ? 1.2 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutBack
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Config.animDuration
                                }
                            }
                        }
                    }
                }

                // Placeholder / status text
                Text {
                    anchors.centerIn: parent
                    visible: (passwordInput.text.length === 0) || (LockService.authenticating)
                    text: LockService.authenticating ? "Verifying password..." : "Enter password..."
                    color: LockService.authenticating ? Config.accentColor : Config.mutedColor
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                }

                // Shake animation on auth failure
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation {
                        target: passwordField
                        property: "shakeX"
                        to: 12
                        duration: 40
                    }
                    NumberAnimation {
                        target: passwordField
                        property: "shakeX"
                        to: -10
                        duration: 40
                    }
                    NumberAnimation {
                        target: passwordField
                        property: "shakeX"
                        to: 8
                        duration: 40
                    }
                    NumberAnimation {
                        target: passwordField
                        property: "shakeX"
                        to: -6
                        duration: 40
                    }
                    NumberAnimation {
                        target: passwordField
                        property: "shakeX"
                        to: 0
                        duration: 40
                    }
                }
            }

            // Error text
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: LockService.failed && root.authMode === "password"
                text: LockService.failMessage
                color: Config.errorColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.authMode === "fingerprint" && !LockService.failed && root.fingerprintAvailable
                text: root.fingerprintHint
                color: root.fingerprintActive ? Config.accentColor : Config.subtextColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
            }

            // Username
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER")
                color: Config.subtextColor
                font.family: Config.font
                font.pixelSize: Config.fontSizeNormal
            }
        }


        // ====================================================================
        // HIDDEN PASSWORD INPUT
        // ====================================================================

        TextInput {
            id: passwordInput
            width: 1
            height: 1
            opacity: 0
            enabled: root.authMode === "password"
            echoMode: TextInput.Password
            focus: root.authMode === "password"

            Keys.onReturnPressed: submit()
            Keys.onEnterPressed: submit()

            function submit() {
                if (root.authMode !== "password")
                    return;
                if (!LockService.authenticating && text.length > 0) {
                    if (fingerprintProc.running)
                        fingerprintProc.running = false;
                    LockService.tryUnlock(text);
                }
            }
        }

        // ====================================================================
        // AUTH EVENT HANDLERS
        // ====================================================================

        Connections {
            id: lockServiceConn
            target: LockService

            function onAuthSucceeded() {
                passwordField.forceActiveFocus();
                fadeOut.start();
            }

            function onFailedChanged() {
                if (LockService.failed) {
                    shakeAnim.start();
                    passwordInput.clear();
                    if (root.fingerprintAvailable)
                        fingerprintRetryTimer.restart();
                }
            }
        }

        // Fade out → unlock sequence
        SequentialAnimation {
            id: fadeOut

            NumberAnimation {
                target: content
                property: "opacity"
                to: 0
                duration: Config.animDurationLong
                easing.type: Easing.OutCubic
            }

            ScriptAction {
                script: {
                    // Disconnect before unlocking to prevent signal handlers
                    // from firing during surface destruction
                    lockServiceConn.enabled = false;
                    root.locked = false;
                }
            }
        }
    }
}
