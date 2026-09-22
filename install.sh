#!/bin/bash
# Install the Predator RGB keyboard tools. Re-running upgrades in place.
set -euo pipefail
[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"
cd "$(dirname "$0")"
install -d /usr/local/sbin
install -m 0755 predator-rgb-enable /usr/local/sbin/predator-rgb-enable
install -m 0755 predator-rgb /usr/local/bin/predator-rgb
[ -f predator-rgb-gui ] && install -m 0755 predator-rgb-gui /usr/local/bin/predator-rgb-gui
install -d -m 0755 /var/lib/predator-rgb
chown "${SUDO_USER:-root}" /var/lib/predator-rgb
install -m 0644 systemd/predator-rgb.service /etc/systemd/system/predator-rgb.service
[ -f systemd/predator-rgb.desktop ] && install -m 0644 systemd/predator-rgb.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable --now predator-rgb.service
echo "done - try: predator-rgb static green"
