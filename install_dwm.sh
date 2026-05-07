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
  alacritty

# === РАСПАКОВКА ИСХОДНИКОВ ===
msg "Extracting sources"
mkdir -p "$SRC_DIR"

for archive in dmenu-5.4.tar.gz dwm-6.8.tar.gz st-0.9.3.tar.gz; do
  dir="${archive%.tar.gz}"
  target="$SRC_DIR/$dir"
  if [ -d "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
    msg "$dir already exists"
  else
    mkdir -p "$target"
    tar -xzf "$CONFIG_DIR/$archive" -C "$target" --strip-components=1
  fi
done

# === СБОРКА DMENU ===
msg "Building dmenu"
(
  cd "$SRC_DIR/dmenu-5.4"
  [ -f config.h ] || cp config.def.h config.h
  sudo make clean install
)

# === СБОРКА DWM ===
msg "Building dwm"
(
  cd "$SRC_DIR/dwm-6.8"
  if [ -f "$CONFIG_DIR/dwm.config.h" ]; then
    cp "$CONFIG_DIR/dwm.config.h" config.h
    msg "Applied dwm.config.h"
  else
    [ -f config.h ] || cp config.def.h config.h
  fi
  sudo make clean install
)

# === СБОРКА ST ===
msg "Building st"
(
  cd "$SRC_DIR/st-0.9.3"
  [ -f config.h ] || cp config.def.h config.h
  sudo make clean install
)

# === АВТОЛОГИН НА TTY1 ===
msg "Configuring autologin"
sudo tee /etc/sv/agetty-tty1/conf >/dev/null <<EOF
if [ -x /sbin/agetty ] || [ -x /bin/agetty ]; then
    if [ "\${tty}" = "tty1" ]; then
        GETTY_ARGS="--autologin $USERNAME --noclear"
    fi
fi
BAUD_RATE=38400
TERM_NAME=linux
EOF

# === ФАЙЛЫ ОБОЛОЧКИ ===
msg "Creating .xinitrc"
if [ ! -f "$HOME/.xinitrc" ]; then
  cat >"$HOME/.xinitrc" <<'EOF'
#!/bin/sh
exec dwm
EOF
  chmod +x "$HOME/.xinitrc"
else
  msg ".xinitrc already exists"
fi

msg "Creating .bash_profile"
if [ ! -f "$HOME/.bash_profile" ]; then
  cat >"$HOME/.bash_profile" <<'EOF'
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
EOF
else
  msg ".bash_profile already exists"
fi

msg "Creating .bashrc"
if [ ! -f "$HOME/.bashrc" ]; then
  cat >"$HOME/.bashrc" <<'EOF'
[[ $- != *i* ]] && return
PS1='\[\e[32m\]\W \$\[\e[0m\] '

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
else
  msg ".bashrc already exists"
fi

# === ПЕРЕЗАПУСК AGETTY ===
msg "Restarting agetty-tty1"
sudo sv restart agetty-tty1 || msg "Could not restart agetty; reboot later"

echo ''
msg "Installation complete. Reboot: sudo reboot"
