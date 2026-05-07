#!/bin/sh
set -eu

# === НАСТРОЙКИ ===
CONFIG_DIR="$HOME/config"
SRC_DIR="$HOME/src"
USERNAME="${USER:?USER not set}"

msg() { printf '==> %s\n' "$1"; }

# === ПРОВЕРКА ФАЙЛОВ ===
for f in "$CONFIG_DIR/dmenu-5.4.tar.gz" "$CONFIG_DIR/dwm-6.8.tar.gz" "$CONFIG_DIR/st-0.9.3.tar.gz"; do
  [ -f "$f" ] || {
    echo "ERROR: $f not found" >&2
    exit 1
  }
done

# === УСТАНОВКА ПАКЕТОВ ===
msg "Installing packages"
sudo xbps-install -Sy \
  xorg-minimal \
  xinit \
  xauth \
  base-devel \
  bash \
  libX11-devel \
  libXft-devel \
  libXinerama-devel \
  font-firacode \
  alacritty \
  fastfetch \
  mesa-dri \
  htop \
  xmirror \
  void-repo-nonfree \
  vulkan-loader \
  mesa-vulkan-radeon \
  xf86-video-amdgpu \
  mesa-vaapi \
  pam_rundir

# === РАСПАКОВКА ИСХОДНИКОВ ===
msg "Extracting sources"
mkdir -p "$SRC_DIR"

for archive in dmenu-5.4.tar.gz dwm-6.8.tar.gz st-0.9.3.tar.gz; do
  dir="${archive%.tar.gz}"
  target="$SRC_DIR/$dir"
  rm -rf "$target" # Насильно удаляем
  mkdir -p "$target"
  tar -xzf "$CONFIG_DIR/$archive" -C "$target" --strip-components=1
done

# === СБОРКА DMENU ===
msg "Building dmenu"
rm -rf "$SRC_DIR/dmenu-5.4/config.h"
cd "$SRC_DIR/dmenu-5.4"
cp config.def.h config.h
sudo make clean install

# === СБОРКА DWM ===
msg "Building dwm"
rm -rf "$SRC_DIR/dwm-6.8/config.h"
cd "$SRC_DIR/dwm-6.8"
if [ -f "$CONFIG_DIR/dwm.config.h" ]; then
  cp "$CONFIG_DIR/dwm.config.h" config.h
  msg "Applied dwm.config.h"
else
  cp config.def.h config.h
fi
sudo make clean install

# === СБОРКА ST ===
msg "Building st"
rm -rf "$SRC_DIR/st-0.9.3/config.h"
cd "$SRC_DIR/st-0.9.3"
cp config.def.h config.h
sudo make clean install

# === АВТОЛОГИН НА TTY1 ===
msg "Configuring autologin"
echo 'if [ -x /sbin/agetty ] || [ -x /bin/agetty ]; then
    if [ "${tty}" = "tty1" ]; then
        GETTY_ARGS="--autologin '$USERNAME' --noclear"
    fi
fi
BAUD_RATE=38400
TERM_NAME=linux' | sudo tee /etc/sv/agetty-tty1/conf >/dev/null

# === ФАЙЛЫ ОБОЛОЧКИ - НАСИЛЬНАЯ ЗАПИСЬ ===
msg "Forcing .xinitrc"
cat >"$HOME/.xinitrc" <<'EOF'
#!/bin/sh
exec dwm
EOF
chmod +x "$HOME/.xinitrc"

msg "Forcing .bash_profile"
cat >"$HOME/.bash_profile" <<'EOF'
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
EOF

msg "Forcing .bashrc"
cat >"$HOME/.bashrc" <<'EOF'
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
# Добавьте эту строку в конец секции session
# session    optional    pam_rundir.so
EOF
