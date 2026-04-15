#!/usr/bin/env python3

import os
import secrets
import sys
from urllib.parse import unquote, urlparse

import dbus
import dbus.mainloop.glib
from gi.repository import GLib


DESKTOP_DEST = "org.freedesktop.portal.Desktop"
DESKTOP_PATH = "/org/freedesktop/portal/desktop"
FILE_CHOOSER_IFACE = "org.freedesktop.portal.FileChooser"
REQUEST_IFACE = "org.freedesktop.portal.Request"


def make_request_path(bus: dbus.bus.BusConnection, token: str) -> str:
    sender = bus.get_unique_name().lstrip(":").replace(".", "_")
    return f"/org/freedesktop/portal/desktop/request/{sender}/{token}"


def image_filters() -> dbus.Array:
    patterns = ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif"]
    entries = dbus.Array(
        [dbus.Struct((dbus.UInt32(0), dbus.String(pattern))) for pattern in patterns],
        signature="(us)",
    )
    return dbus.Array(
        [dbus.Struct((dbus.String("Images"), entries))],
        signature="(sa(us))",
    )


def decode_file_uri(uri: str) -> str:
    parsed = urlparse(uri)
    if parsed.scheme != "file":
        return ""
    return unquote(parsed.path)


def main() -> int:
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    loop = GLib.MainLoop()

    token = f"qswallpaper{secrets.token_hex(8)}"
    expected_path = make_request_path(bus, token)
    result = {"code": 2}

    def finish(code: int) -> None:
        result["code"] = code
        if loop.is_running():
            loop.quit()

    def on_response(response: int, results: dbus.Dictionary) -> None:
        if int(response) != 0:
            finish(int(response))
            return

        uris = [str(uri) for uri in results.get("uris", [])]
        for uri in uris:
            path = decode_file_uri(uri)
            if path:
                print(path, flush=True)
        finish(0 if uris else 1)

    receiver = bus.add_signal_receiver(
        on_response,
        signal_name="Response",
        dbus_interface=REQUEST_IFACE,
        path=expected_path,
    )

    home_dir = os.path.expanduser("~")
    options = {
        "handle_token": dbus.String(token),
        "accept_label": dbus.String("Add"),
        "modal": dbus.Boolean(True),
        "multiple": dbus.Boolean(True),
        "filters": image_filters(),
        "current_folder": dbus.ByteArray(os.fsencode(home_dir) + b"\0"),
    }

    try:
        chooser = dbus.Interface(
            bus.get_object(DESKTOP_DEST, DESKTOP_PATH),
            FILE_CHOOSER_IFACE,
        )
        handle = str(chooser.OpenFile("", "Add Wallpapers", options))
    except dbus.DBusException as exc:
        print(f"[Portal] {exc.get_dbus_message()}", file=sys.stderr)
        bus.remove_signal_receiver(receiver)
        return 2

    if handle != expected_path:
        bus.remove_signal_receiver(receiver)
        receiver = bus.add_signal_receiver(
            on_response,
            signal_name="Response",
            dbus_interface=REQUEST_IFACE,
            path=handle,
        )

    GLib.timeout_add_seconds(300, lambda: (finish(2), False)[1])
    loop.run()
    bus.remove_signal_receiver(receiver)
    return int(result["code"])


if __name__ == "__main__":
    sys.exit(main())
