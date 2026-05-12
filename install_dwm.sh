#!/bin/sh
set -eu

CONFIG_DIR="$HOME/config"
SRC_DIR="$HOME/src"
USERNAME="${USER:?USER not set}"

sudo xbps-install -Sy \
    xorg base-devel libX11-devel libXft-devel libXinerama-devel \
    font-firacode alacritty fastfetch htop xmirror void-repo-nonfree \
    dbus dumb_runtime_dir pipewire wireplumber pavucontrol curl wget xbanish \
    >/dev/null 2>&1

mkdir -p "$SRC_DIR"
for d in dmenu-5.4 dwm-6.8 st-0.9.3; do
    rm -rf "$SRC_DIR/$d"
    cp -a "$CONFIG_DIR/$d" "$SRC_DIR/$d"
done

for name in dmenu-5.4 dwm-6.8 st-0.9.3; do
    cd "$SRC_DIR/$name"
    [ -f config.h ] || cp config.def.h config.h
    sudo make clean install >/dev/null 2>&1
done

sudo mkdir -p /etc/sv/agetty-tty1
printf 'if [ -x /sbin/agetty ] || [ -x /bin/agetty ]; then\n    if [ "${tty}" = "tty1" ]; then\n        GETTY_ARGS="--autologin '\''%s'\'' --noclear"\n    fi\nfi\nBAUD_RATE=38400\nTERM_NAME=linux\n' "$USERNAME" \
    | sudo tee /etc/sv/agetty-tty1/conf >/dev/null

cat > "$HOME/.xinitrc" <<'EOF'
setxkbmap -layout us,ru -option grp:alt_shift_toggle
#xrandr --output DisplayPort-0 --mode 1920x1080 --rate 144
xbanish &
exec dwm
EOF

cat > "$HOME/.bash_profile" <<'EOF'
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
EOF

cat > "$HOME/.bashrc" <<'EOF'
[[ $- != *i* ]] && return
PS1='\[\e[32m\]\W \$\[\e[0m\] '
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# sudo mkdir -p /etc/pipewire/pipewire.conf.d
# sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
# sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

# sudo vi /etc/pam.d/system-login
# session  optional  pam_dumb_runtime_dir.so

# sudo mkdir -p /run/user
# sudo chmod 0755 /run/user
EOF
