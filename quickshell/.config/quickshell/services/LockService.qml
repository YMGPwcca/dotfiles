pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pam

Singleton {
    id: root

    // ========================================================================
    // PROPERTIES
    // ========================================================================

    property bool locked: false
    property bool authenticating: false
    property bool failed: false
    property string failMessage: ""
    property string pamMessage: ""
    property bool pamMessageIsError: false
    property bool passwordRequested: false

    signal authSucceeded

    // ========================================================================
    // PAM AUTHENTICATION
    // ========================================================================

    property string _pendingPassword: ""

    PamContext {
        id: pam
        config: "login"
        user: Quickshell.env("USER")

        onResponseRequiredChanged: {
            root.passwordRequested = pam.responseRequired;
            if (pam.responseRequired && root._pendingPassword !== "") {
                pam.respond(root._pendingPassword);
                root._pendingPassword = "";
            }
        }

        onPamMessage: {
            const cleanMsg = pam.message.trim();
            if (cleanMsg !== "" && !pam.responseRequired) {
                root.pamMessage = cleanMsg;
                root.pamMessageIsError = pam.messageIsError;
            }
        }

        onCompleted: result => {
            root.authenticating = false;
            root._pendingPassword = "";

            if (result === PamResult.Success) {
                console.log("[Lock] Authentication successful");
                root.failed = false;
                root.failMessage = "";
                root.pamMessage = "";
                root.authSucceeded();
            } else {
                console.log("[Lock] Authentication failed:", PamResult.toString(result));
                root.failed = true;
                root.failMessage = "Authentication failed";
                // Restart PAM for prompt retry if still locked
                if (root.locked) {
                    pamRestartTimer.start();
                }
            }
        }

        onError: error => {
            root.authenticating = false;
            root._pendingPassword = "";
            console.log("[Lock] PAM error:", PamError.toString(error));
            root.failed = true;
            root.failMessage = "Authentication error";
            if (root.locked) {
                pamRestartTimer.start();
            }
        }
    }

    Timer {
        id: pamRestartTimer
        interval: 1000 // 1s delay to let fprintd release the device cleanly
        repeat: false
        onTriggered: {
            if (root.locked) {
                console.log("[Lock] Restarting PAM after delay");
                root.failed = false;
                root.failMessage = "";
                root.pamMessage = "";
                root.pamMessageIsError = false;
                pam.start();
            }
        }
    }

    // ========================================================================
    // PUBLIC FUNCTIONS
    // ========================================================================

    function lock() {
        if (!locked) {
            console.log("[Lock] Locking screen");
            locked = true;
            failed = false;
            failMessage = "";
            pamMessage = "";
            authenticating = false;
            _pendingPassword = "";
            pamRestartTimer.stop();
            pam.start();
        }
    }

    function unlock() {
        if (locked) {
            console.log("[Lock] Unlocking screen");
            // Only set locked = false here. Do NOT reset failed/failMessage/etc
            // because that triggers signals on the LockScreen which is being
            // destroyed (causes "invalid context" warning). State is reset in lock().
            locked = false;
            pamRestartTimer.stop();
        }
    }

    function tryUnlock(password: string) {
        if (!locked)
            return;
        console.log("[Lock] Submitting password to PAM");
        _pendingPassword = password;
        pamRestartTimer.stop();
        if (pam.responseRequired) {
            pam.respond(password);
            _pendingPassword = "";
        } else if (!pam.active) {
            pam.start();
        }
        failed = false;
        failMessage = "";
        pamMessage = "";
        pamMessageIsError = false;
    }

    function restartAuth() {
        if (!locked)
            return;
        console.log("[Lock] Manually restarting PAM authentication");
        pamRestartTimer.stop();
        if (pam.active) {
            pam.abort();
        } else {
            pam.start();
        }
        failed = false;
        failMessage = "";
        pamMessage = "";
        pamMessageIsError = false;
    }
}
