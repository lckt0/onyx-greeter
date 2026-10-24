#!/usr/bin/env bash
# Onyx — install the login screen theme and the matching lock-screen backdrop.
#
#   ./install.sh              install both halves and select them
#   ./install.sh --sddm       login screen only
#   ./install.sh --lock       lock screen only
#   ./install.sh --no-select  install the files, leave the current selection
#   ./install.sh --no-appearance
#                             skip handing the greeter your colours and icons
#
# Besides the two theme packages this touches exactly two selection keys, and
# the sddm user's own profile under /var/lib/sddm (colours, icons, Plasma
# style) so the login screen is dressed like your session. Both config files
# there are backed up next to themselves before the first write.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

THEME_ID="onyx"
WALLPAPER_ID="org.lckt0.onyx"
SDDM_DIR="/usr/share/sddm/themes/${THEME_ID}"
SDDM_CONF="/etc/sddm.conf.d/kde_settings.conf"
WALLPAPER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/${WALLPAPER_ID}"
LOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/kscreenlockerrc"

CAPTION="${ONYX_CAPTION:-$(cat /etc/hostname 2>/dev/null || uname -n)}"

do_sddm=1
do_lock=1
do_select=1
do_appearance=1
for arg in "$@"; do
    case "$arg" in
        --sddm)          do_lock=0 ;;
        --lock)          do_sddm=0 ;;
        --no-select)     do_select=0 ;;
        --no-appearance) do_appearance=0 ;;
        -h|--help)       sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)               echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

say() { printf '  %s\n' "$*"; }

if (( do_sddm )); then
    echo "Login screen"
    sudo install -d -m 0755 "$SDDM_DIR"
    # *.qml includes Backdrop.qml, a symlink into shared/ that install dereferences.
    sudo install -m 0644 "$here"/sddm/*.qml "$SDDM_DIR/"
    sudo install -m 0644 "$here"/sddm/metadata.desktop "$SDDM_DIR/"
    [[ -f "$here/sddm/preview.png" ]] && sudo install -m 0644 "$here/sddm/preview.png" "$SDDM_DIR/"

    # theme.conf carries the caption, so write it rather than copy it.
    sudo install -m 0644 "$here"/sddm/theme.conf "$SDDM_DIR/"
    sudo sed -i "s|^caption=.*|caption=${CAPTION}|" "$SDDM_DIR/theme.conf"
    say "installed  $SDDM_DIR"

    if (( do_select )); then
        sudo kwriteconfig6 --file "$SDDM_CONF" --group Theme --key Current "$THEME_ID"
        say "selected   $SDDM_CONF  [Theme] Current=$THEME_ID"
        say "takes effect at the next login screen"
    fi
fi

# The greeter runs as the sddm user, out of its own profile, so it cannot see
# anything in a 0700 home directory. Copy the three appearance packages the
# lock screen uses into that profile and point the greeter at them; without
# this the login screen falls back to stock Breeze and the two screens stop
# matching.
if (( do_sddm && do_appearance )); then
    echo "Greeter appearance"
    sddm_home="/var/lib/sddm"
    sddm_conf="$sddm_home/.config"
    sddm_data="$sddm_home/.local/share"

    user_scheme="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)"
    user_icons="$(kreadconfig6 --file kdeglobals --group Icons --key Theme)"
    user_style="$(kreadconfig6 --file plasmarc --group Theme --key name)"
    user_font="$(kreadconfig6 --file kdeglobals --group General --key font)"

    for f in kdeglobals plasmarc; do
        # /var/lib/sddm is 0750 sddm:sddm: test as root, or both tests fail
        # silently and no backup is ever taken.
        if sudo test -f "$sddm_conf/$f" && ! sudo test -f "$sddm_conf/$f.onyx-backup"; then
            sudo cp -a "$sddm_conf/$f" "$sddm_conf/$f.onyx-backup"
            say "backed up  $sddm_conf/$f.onyx-backup"
        fi
    done

    # Colour scheme: only a file in a readable place counts.
    scheme_file="$HOME/.local/share/color-schemes/${user_scheme}.colors"
    if [[ -n "$user_scheme" && -f "$scheme_file" ]]; then
        sudo install -d -m 0755 "$sddm_data/color-schemes"
        sudo install -m 0644 "$scheme_file" "$sddm_data/color-schemes/"
        say "copied     ${user_scheme}.colors"
    fi
    if [[ -n "$user_scheme" ]]; then
        sudo kwriteconfig6 --file "$sddm_conf/kdeglobals" --group General --key ColorScheme "$user_scheme"
        say "colours    $user_scheme"
    fi

    # The accent colour is a separate key that Plasma paints over the scheme.
    # Without it the greeter draws Breeze blue focus rings on a scheme whose
    # own DecorationFocus is blue, while the lock screen draws them white.
    user_accent="$(kreadconfig6 --file kdeglobals --group General --key AccentColor)"
    if [[ -n "$user_accent" ]]; then
        sudo kwriteconfig6 --file "$sddm_conf/kdeglobals" --group General --key AccentColor "$user_accent"
        sudo kwriteconfig6 --file "$sddm_conf/kdeglobals" --group General --key LastUsedCustomAccentColor "$user_accent"
        say "accent     $user_accent"
    fi
    user_hash="$(kreadconfig6 --file kdeglobals --group General --key ColorSchemeHash)"
    [[ -n "$user_hash" ]] && sudo kwriteconfig6 --file "$sddm_conf/kdeglobals" --group General --key ColorSchemeHash "$user_hash"

    # Plasma style, if it lives in the home directory rather than /usr/share.
    style_dir="$HOME/.local/share/plasma/desktoptheme/$user_style"
    if [[ -n "$user_style" && -d "$style_dir" ]]; then
        sudo install -d -m 0755 "$sddm_data/plasma/desktoptheme"
        sudo cp -aT "$style_dir" "$sddm_data/plasma/desktoptheme/$user_style"
        say "copied     plasma style $user_style"
    fi
    if [[ -n "$user_style" ]]; then
        sudo kwriteconfig6 --file "$sddm_conf/plasmarc" --group Theme --key name "$user_style"
        say "style      $user_style"
    fi

    # Icons: Papirus and friends are installed system-wide, so only the key
    # needs setting. Copy it over if it turns out to be a home-directory theme.
    icon_dir="$HOME/.local/share/icons/$user_icons"
    if [[ -n "$user_icons" && ! -d "/usr/share/icons/$user_icons" && -d "$icon_dir" ]]; then
        sudo install -d -m 0755 "$sddm_data/icons"
        sudo cp -aT "$icon_dir" "$sddm_data/icons/$user_icons"
        say "copied     icon theme $user_icons"
    fi
    if [[ -n "$user_icons" ]]; then
        sudo kwriteconfig6 --file "$sddm_conf/kdeglobals" --group Icons --key Theme "$user_icons"
        say "icons      $user_icons"
    fi

    [[ -n "$user_font" ]] && sudo kwriteconfig6 --file "$sddm_conf/kdeglobals" --group General --key font "$user_font"

    sudo chown -R sddm:sddm "$sddm_conf" "$sddm_data" 2>/dev/null || true
fi

if (( do_lock )); then
    echo "Lock screen"
    install -d -m 0755 "$WALLPAPER_DIR/contents/ui" "$WALLPAPER_DIR/contents/config"
    install -m 0644 "$here"/wallpaper/metadata.json "$WALLPAPER_DIR/"
    install -m 0644 "$here"/wallpaper/contents/ui/*.qml "$WALLPAPER_DIR/contents/ui/"
    install -m 0644 "$here"/wallpaper/contents/config/main.xml "$WALLPAPER_DIR/contents/config/"
    sed -i "s|<default>.*</default>|<default>${CAPTION}</default>|" \
        "$WALLPAPER_DIR/contents/config/main.xml"
    # Only the Caption entry has a text default; put the boolean back.
    sed -i "/name=\"ShowCaption\"/,/<\/entry>/ s|<default>.*</default>|<default>true</default>|" \
        "$WALLPAPER_DIR/contents/config/main.xml"
    say "installed  $WALLPAPER_DIR"

    if (( do_select )); then
        kwriteconfig6 --file "$LOCK_CONF" --group Greeter --key WallpaperPlugin "$WALLPAPER_ID"
        kwriteconfig6 --file "$LOCK_CONF" \
            --group Greeter --group Wallpaper --group "$WALLPAPER_ID" --group General \
            --key Caption "$CAPTION"
        say "selected   $LOCK_CONF  [Greeter] WallpaperPlugin=$WALLPAPER_ID"
        say "takes effect at the next lock"
    fi
fi

echo
echo "Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme $SDDM_DIR"
echo "  loginctl lock-session"
