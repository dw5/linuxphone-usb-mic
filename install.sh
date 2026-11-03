#!/bin/bash
# Install the USB Mic app for the current user, plus its root helper and polkit rule.
set -e
sudo -v
cd "$(dirname "$0")"
sudo install -D -m 755 usb-mic-helper /usr/local/libexec/usb-mic-helper
sudo install -D -m 644 local.usbmic.policy /usr/share/polkit-1/actions/local.usbmic.policy
install -D -m 755 usb-mic ~/.local/bin/usb-mic
# The session may not have ~/.local/bin on PATH, so point at the installed copy.
mkdir -p ~/.local/share/applications
sed "s|^Exec=.*|Exec=$HOME/.local/bin/usb-mic|" usb-mic.desktop > ~/.local/share/applications/local.UsbMic.desktop
install -D -m 644 usb-mic.svg ~/.local/share/icons/hicolor/scalable/apps/usb-mic.svg
gtk-update-icon-cache -q ~/.local/share/icons/hicolor 2>/dev/null || true
update-desktop-database -q ~/.local/share/applications 2>/dev/null || true
echo "Installed. Look for \"USB Mic\" in the app list."
