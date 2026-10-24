#!/usr/bin/env bash
# Onyx — remove both halves and put the previous selections back.
#
#   ./uninstall.sh [sddm-theme-to-restore]     (default: breeze)
set -euo pipefail

RESTORE_THEME="${1:-breeze}"
SDDM_DIR="/usr/share/sddm/themes/onyx"
SDDM_CONF="/etc/sddm.conf.d/kde_settings.conf"
WALLPAPER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/org.lckt0.onyx"
LOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/kscreenlockerrc"

if [[ "$(kreadconfig6 --file "$SDDM_CONF" --group Theme --key Current 2>/dev/null)" == "onyx" ]]; then
    sudo kwriteconfig6 --file "$SDDM_CONF" --group Theme --key Current "$RESTORE_THEME"
    echo "  restored   [Theme] Current=$RESTORE_THEME"
fi
sudo rm -rf "$SDDM_DIR"
echo "  removed    $SDDM_DIR"

if [[ "$(kreadconfig6 --file "$LOCK_CONF" --group Greeter --key WallpaperPlugin 2>/dev/null)" == "org.lckt0.onyx" ]]; then
    kwriteconfig6 --file "$LOCK_CONF" --group Greeter --key WallpaperPlugin org.kde.image
    echo "  restored   [Greeter] WallpaperPlugin=org.kde.image"
fi
rm -rf "$WALLPAPER_DIR"
echo "  removed    $WALLPAPER_DIR"

# Put the greeter's own profile back the way install.sh found it.
SDDM_CONF_DIR="/var/lib/sddm/.config"
for f in kdeglobals plasmarc; do
    if sudo test -f "$SDDM_CONF_DIR/$f.onyx-backup"; then
        sudo mv "$SDDM_CONF_DIR/$f.onyx-backup" "$SDDM_CONF_DIR/$f"
        echo "  restored   $SDDM_CONF_DIR/$f"
    fi
done
# The copies themselves are harmless, but leaving them would be litter.
sudo rm -rf /var/lib/sddm/.local/share/color-schemes \
            /var/lib/sddm/.local/share/plasma/desktoptheme \
            /var/lib/sddm/.local/share/icons
echo "  removed    appearance packages copied into /var/lib/sddm"
