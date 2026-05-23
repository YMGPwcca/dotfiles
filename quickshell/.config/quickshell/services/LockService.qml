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
    readonly property string fingerprintPamConfig: "login"
    readonly property string fingerprintPamConfigDir: "/etc/pam.d"
    readonly property string passwordPamConfig: "password"
    readonly property string passwordPamConfigDir: Quickshell.configDir + "/pam.d"
    property bool _isAborting: false
    property bool _restartAfterAbort: false
    property bool _startPasswordAfterAbort: false
    property string _currentPamConfig: ""
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

    function startPam(configName: string) {
        root._currentPamConfig = configName;
        pam.configDirectory = configName === root.passwordPamConfig ? root.passwordPamConfigDir : root.fingerprintPamConfigDir;
        pam.config = configName;
        root.logDebug(`Starting PAM config: ${configName} from ${pam.configDirectory}`, "#7aa2f7");
        const started = pam.start();
        if (!started)
            root.logDebug(`Failed to start PAM config: ${configName}`, "#f7768e");
        return started;
    }

    PamContext {
        id: pam
        config: root.fingerprintPamConfig
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
            root.logDebug(`PAM completed with result: ${PamResult.toString(result)}`, result === PamResult.Success ? "#9ece6a" : "#f7768e");

            if (root._isAborting) {
                root.logDebug("Abort flag was active, completing without auth result", "#7aa2f7");
                const shouldRestart = root._restartAfterAbort;
                const shouldStartPassword = root._startPasswordAfterAbort;
                root._isAborting = false;
                root._restartAfterAbort = false;
                root._startPasswordAfterAbort = false;
                if (!shouldStartPassword)
                    root._pendingPassword = "";
                if (root.locked) {
                    if (shouldRestart)
                        pamRestartTimer.start();
                    else if (shouldStartPassword)
                        root.startPam(root.passwordPamConfig);
                }
            } else if (result === PamResult.Success) {
                console.log("[Lock] Authentication successful");
                root._pendingPassword = "";
                root.failed = false;
                root.failMessage = "";
                root.pamMessage = "";
                root._isAborting = false;
                root.authSucceeded();
            } else {
                root._pendingPassword = "";
                console.log("[Lock] Authentication finished with result:", PamResult.toString(result));
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
            root.logDebug(`PAM error: ${PamError.toString(error)}`, "#f7768e");
            console.log("[Lock] PAM error:", PamError.toString(error));
            if (root._isAborting) {
                const shouldRestart = root._restartAfterAbort;
                const shouldStartPassword = root._startPasswordAfterAbort;
                root._isAborting = false;
                root._restartAfterAbort = false;
                root._startPasswordAfterAbort = false;
                if (!shouldStartPassword)
                    root._pendingPassword = "";
                if (root.locked) {
                    if (shouldRestart)
                        pamRestartTimer.start();
                    else if (shouldStartPassword)
                        root.startPam(root.passwordPamConfig);
                }
            } else {
                root._pendingPassword = "";
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
                root.passwordRequested = false;
                root._isAborting = false;
                root._restartAfterAbort = false;
                root._startPasswordAfterAbort = false;
                root.startPam(root._currentPamConfig !== "" ? root._currentPamConfig : root.fingerprintPamConfig);
            }
        }
    }

    Timer {
        id: pamAbortSettleTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!root._isAborting || root._restartAfterAbort)
                return;
            if (pam.active) {
                start();
                return;
            }
            root.logDebug("PAM abort settled", "#7aa2f7");
            root._isAborting = false;
            root._restartAfterAbort = false;
            if (root._startPasswordAfterAbort && root.locked) {
                root._startPasswordAfterAbort = false;
                root.startPam(root.passwordPamConfig);
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
            pamMessageIsError = false;
            passwordRequested = false;
            authenticating = false;
            _pendingPassword = "";
            _isAborting = false;
            _restartAfterAbort = false;
            _startPasswordAfterAbort = false;
            _currentPamConfig = "";
            pamRestartTimer.stop();
            pamAbortSettleTimer.stop();
            root.startPam(root.fingerprintPamConfig);
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
            pamAbortSettleTimer.stop();
            passwordRequested = false;
        }
    }

    function tryUnlock(password: string) {
        if (!locked)
            return;
        if (root._isAborting) {
            if (root._restartAfterAbort) {
                root.logDebug("Ignoring password submit while fingerprint restart is pending", "#e0af68");
                return;
            }
            if (_pendingPassword === "")
                root.logDebug("Queueing password submit until PAM abort settles", "#e0af68");
            _pendingPassword = password;
            root._startPasswordAfterAbort = true;
            pamAbortSettleTimer.start();
            return;
        }

        if (pam.active && !pam.responseRequired) {
            if (_pendingPassword === "")
                root.logDebug("Queueing password until PAM requests a response", "#e0af68");
            _pendingPassword = password;
            failed = false;
            failMessage = "";
            pamMessage = "";
            pamMessageIsError = false;
            passwordRequested = false;
            return;
        }

        root.logDebug(`tryUnlock() password submit, pam.active: ${pam.active}, responseRequired: ${pam.responseRequired}`, "#7aa2f7");
        console.log("[Lock] Submitting password to PAM");
        _pendingPassword = password;
        pamRestartTimer.stop();
        if (pam.responseRequired) {
            pam.respond(password);
            _pendingPassword = "";
        } else if (!pam.active) {
            root.startPam(root.passwordPamConfig);
        }
        failed = false;
        failMessage = "";
        pamMessage = "";
        pamMessageIsError = false;
        passwordRequested = false;
    }

    function stopAuth() {
        if (!locked)
            return;
        root.logDebug(`stopAuth() stopping PAM, pam.active: ${pam.active}`, "#7aa2f7");
        console.log("[Lock] Stopping PAM authentication");
        pamRestartTimer.stop();
        failed = false;
        failMessage = "";
        pamMessage = "";
        pamMessageIsError = false;
        passwordRequested = false;
        _pendingPassword = "";
        root._restartAfterAbort = false;
        root._startPasswordAfterAbort = false;
        root._currentPamConfig = "";
        if (pam.active) {
            root._isAborting = true;
            pam.abort();
            pamAbortSettleTimer.start();
        } else {
            root._isAborting = false;
        }
    }

    function restartAuth() {
        if (!locked)
            return;
        root.logDebug(`restartAuth() manual restart, pam.active: ${pam.active}`, "#7aa2f7");
        console.log("[Lock] Manually restarting PAM authentication");
        pamRestartTimer.stop();
        pamAbortSettleTimer.stop();
        if (pam.active) {
            root._isAborting = true;
            root._restartAfterAbort = true;
            root._startPasswordAfterAbort = false;
            pam.abort();
            pamRestartTimer.start();
        } else {
            root._isAborting = false;
            root._restartAfterAbort = false;
            root._startPasswordAfterAbort = false;
            root.startPam(root.fingerprintPamConfig);
        }
        failed = false;
        failMessage = "";
        pamMessage = "";
        pamMessageIsError = false;
        passwordRequested = false;
    }
}
