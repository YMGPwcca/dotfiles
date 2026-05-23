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
    readonly property bool pamActive: pam.active
    property bool _isAborting: false
    property var debugLogs: []
    signal debugLogAdded(string msg)

    function logDebug(msg, colorName) {
        const time = new Date().toLocaleTimeString();
        let formatted = `[${time}] ${msg}`;
        if (colorName) {
            formatted = `<font color="${colorName}">${formatted}</font>`;
        } else {
            formatted = `<font color="#c0caf5">${formatted}</font>`;
        }
        console.log(`[Lock Debug] ${msg}`);
        const newLogs = debugLogs.concat([formatted]);
        if (newLogs.length > 100) {
            newLogs.shift();
        }
        debugLogs = newLogs;
        debugLogAdded(formatted);
    }

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
            root.logDebug(`Response required: ${pam.responseRequired}`, "#7aa2f7");
            if (pam.responseRequired && root._pendingPassword !== "") {
                root.logDebug("Responding to prompt with pending password", "#7aa2f7");
                pam.respond(root._pendingPassword);
                root._pendingPassword = "";
            }
        }

        onPamMessage: {
            const cleanMsg = pam.message.trim();
            root.logDebug(`PAM Message: "${cleanMsg}" (isError: ${pam.messageIsError})`, pam.messageIsError ? "#f7768e" : "#e0af68");
            if (cleanMsg !== "" && !pam.responseRequired) {
                root.pamMessage = cleanMsg;
                root.pamMessageIsError = pam.messageIsError;
            }
        }

        onCompleted: result => {
            root.authenticating = false;
            root._pendingPassword = "";
            root.logDebug(`PAM completed with result: ${PamResult.toString(result)}`, result === PamResult.Success ? "#9ece6a" : "#f7768e");

            if (result === PamResult.Success) {
                console.log("[Lock] Authentication successful");
                root.failed = false;
                root.failMessage = "";
                root.pamMessage = "";
                root._isAborting = false;
                root.authSucceeded();
            } else {
                console.log("[Lock] Authentication finished with result:", PamResult.toString(result));
                if (root._isAborting) {
                    root.logDebug("Abort flag was active, trigger restart timer without failed state", "#7aa2f7");
                    root._isAborting = false;
                    if (root.locked) {
                        pamRestartTimer.start();
                    }
                } else {
                    root.failed = true;
                    root.failMessage = "Authentication failed";
                    // Restart PAM for prompt retry if still locked
                    if (root.locked) {
                        pamRestartTimer.start();
                    }
                }
            }
        }

        onError: error => {
            root.authenticating = false;
            root._pendingPassword = "";
            root.logDebug(`PAM error: ${PamError.toString(error)}`, "#f7768e");
            console.log("[Lock] PAM error:", PamError.toString(error));
            if (root._isAborting) {
                root._isAborting = false;
                if (root.locked) {
                    pamRestartTimer.start();
                }
            } else {
                root.failed = true;
                root.failMessage = "Authentication error";
                if (root.locked) {
                    pamRestartTimer.start();
                }
            }
        }
    }

    Timer {
        id: pamRestartTimer
        interval: 1000 // 1s delay to let fprintd release the device cleanly
        repeat: false
        onTriggered: {
            if (root.locked) {
                root.logDebug("pamRestartTimer fired, restarting PAM", "#7aa2f7");
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
            root.logDebug("lock() screen initiated", "#7aa2f7");
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
            root.logDebug("unlock() screen initiated", "#9ece6a");
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
        root.logDebug(`tryUnlock() password submit, pam.active: ${pam.active}, responseRequired: ${pam.responseRequired}`, "#7aa2f7");
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
        root.logDebug(`restartAuth() manual restart, pam.active: ${pam.active}`, "#7aa2f7");
        console.log("[Lock] Manually restarting PAM authentication");
        pamRestartTimer.stop();
        if (pam.active) {
            root._isAborting = true;
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
