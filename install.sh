#!/usr/bin/env bash

set -euo pipefail

PROGRESS_FILE="./.install_progress"
STEP=0
if [ -f "$PROGRESS_FILE" ]; then
  STEP="$(cat "$PROGRESS_FILE")"
fi

echo "=== Начинаем установку dotfiles и настройку Debian + Sway ==="

BASE_PACKAGES=(
  sway swaybg swaylock swayidle
  waybar wofi mako
  grim slurp wl-clipboard
  alacritty foot
  lxqt-policykit
  network-manager
  xdg-desktop-portal
  xdg-desktop-portal-wlr
  xdg-desktop-portal-gtk
  pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse
  polkit
  dbus dbus-user-session
  libgl1-mesa-dri
  mesa-vulkan-drivers
  mesa-utils
  vulkan-tools
  git curl wget unzip htop tmux vim lf
  bluez bluez-tools
  brightnessctl playerctl pavucontrol
  libnotify-bin
  fonts-roboto fonts-dejavu fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji
  xwayland
)

OPTIONAL_GUI_PACKAGES=(
  network-manager-applet
)

OPTIONAL_APPS_APT=(
  cmus
  kdenlive
)

echo "Текущий шаг: $STEP"

# 1. Базовое обновление
if [ "$STEP" -lt 1 ]; then
  echo "Обновление системы..."
  sudo apt update
  sudo apt full-upgrade -y
  sudo apt install -y ca-certificates gnupg apt-transport-https
  echo "=== Обновление завершено ==="
  echo 1 > "$PROGRESS_FILE"
fi

# 2. Установка базового набора под sway
if [ "$STEP" -lt 2 ]; then
  echo "Установка базовых пакетов..."
  sudo apt install -y "${BASE_PACKAGES[@]}"
  echo "=== Базовые пакеты установлены ==="
  echo 2 > "$PROGRESS_FILE"
fi

# 3. Опциональные GUI-пакеты
if [ "$STEP" -lt 3 ]; then
  echo "Установка опциональных GUI-пакетов..."
  sudo apt install -y "${OPTIONAL_GUI_PACKAGES[@]}"
  echo "=== Опциональные GUI-пакеты установлены ==="
  echo 3 > "$PROGRESS_FILE"
fi

# 4. Приложения из apt
if [ "$STEP" -lt 4 ]; then
  echo "Установка приложений из apt..."
  sudo apt install -y "${OPTIONAL_APPS_APT[@]}"
  echo "=== Приложения из apt установлены ==="
  echo 4 > "$PROGRESS_FILE"
fi

# 5. Signal из официального репозитория
if [ "$STEP" -lt 5 ]; then
  echo "Установка Signal Desktop..."
  wget -O- https://updates.signal.org/desktop/apt/keys.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

  wget -O /tmp/signal-desktop.sources \
    https://updates.signal.org/static/desktop/apt/signal-desktop.sources

  sudo sed \
    's#Signed-By=#Signed-By=/usr/share/keyrings/signal-desktop-keyring.gpg#' \
    /tmp/signal-desktop.sources \
    | sudo tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null

  sudo apt update
  sudo apt install -y signal-desktop
  rm -f /tmp/signal-desktop.sources
  echo "=== Signal Desktop установлен ==="
  echo 5 > "$PROGRESS_FILE"
fi

# 6. REAPER из официального архива Cockos
if [ "$STEP" -lt 6 ]; then
  echo "Установка REAPER..."
  mkdir -p /tmp/reaper-install
  cd /tmp/reaper-install

  REAPER_URL="$(curl -fsSL https://www.reaper.fm/download.php \
    | grep -oE 'https://download.cockos.com/reaper[0-9a-zA-Z._-]+_linux_x86_64.tar.xz' \
    | head -n1)"

  if [ -n "${REAPER_URL:-}" ]; then
    wget -O reaper.tar.xz "$REAPER_URL"
    tar -xf reaper.tar.xz
    cd reaper_linux_x86_64
    sudo ./install-reaper.sh --install /opt --integrate-desktop
    cd ~
    rm -rf /tmp/reaper-install
    echo "=== REAPER установлен ==="
  else
    echo "!!! Не удалось определить ссылку на REAPER автоматически"
    echo "!!! Установи REAPER вручную с https://www.reaper.fm/download.php"
  fi

  echo 6 > "$PROGRESS_FILE"
fi

# 7. Настройка bash
if [ "$STEP" -lt 7 ]; then
  echo "Настройка .bashrc..."
  cp -v ./bash/.bashrc ~/.bashrc
  echo "=== Bash конфиг применен ==="
  echo 7 > "$PROGRESS_FILE"
fi

# 8. Установка пользовательских шрифтов
if [ "$STEP" -lt 8 ]; then
  echo "Установка пользовательских шрифтов..."
  mkdir -p ~/.local/share/fonts
  cp -rv ./fonts/* ~/.local/share/fonts/
  fc-cache -f -v
  echo "=== Пользовательские шрифты установлены ==="
  echo 8 > "$PROGRESS_FILE"
fi

# 9. Настройка alacritty, foot, vim, tmux, lf, k9s
if [ "$STEP" -lt 9 ]; then
  echo "Настройка alacritty..."
  mkdir -p ~/.config/alacritty
  cp -rv ./alacritty/* ~/.config/alacritty/

  echo "Настройка vim..."
  cp -v ./vim/.vimrc ~/.vimrc 2>/dev/null || true

  echo "Настройка tmux..."
  mkdir -p ~/.config/tmux
  cp -rv ./tmux/* ~/.config/tmux/

  echo "Настройка lf..."
  mkdir -p ~/.config/lf
  cp -rv ./lf/* ~/.config/lf/

  echo "Настройка k9s..."
  mkdir -p ~/.config/k9s
  cp -rv ./k9s/* ~/.config/k9s/ 2>/dev/null || true

  echo "=== Конфиги терминальных инструментов применены ==="
  echo 9 > "$PROGRESS_FILE"
fi

# 10. Перенос картинок
if [ "$STEP" -lt 10 ]; then
  echo "Перенос картинок..."
  mkdir -p ~/Pictures
  cp -rv ./pics/* ~/Pictures/
  echo "=== Картинки перемещены ==="
  echo 10 > "$PROGRESS_FILE"
fi

# 11. Настройка PipeWire
if [ "$STEP" -lt 11 ]; then
  echo "Настройка PipeWire..."
  mkdir -p ~/.config/pipewire
  cp -v ./sound/pipewire.conf ~/.config/pipewire/pipewire.conf 2>/dev/null || true

  systemctl --user daemon-reload || true
  systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

  echo "=== PipeWire настроен ==="
  echo 11 > "$PROGRESS_FILE"
fi

# 12. Включение NetworkManager и Bluetooth
if [ "$STEP" -lt 12 ]; then
  echo "Включение NetworkManager и Bluetooth..."
  sudo systemctl enable --now NetworkManager
  sudo systemctl enable --now bluetooth || true
  echo "=== Сетевые сервисы включены ==="
  echo 12 > "$PROGRESS_FILE"
fi

# 13. Настройка Firefox
if [ "$STEP" -lt 13 ]; then
  echo "Настройка Firefox..."
  FIREFOX_PROFILE_DIR=$(awk -F= '/^\[Profile[0-9]+\]/{p=0}
                                /^Name=default-release$/{p=1}
                                p && /^Path=/{print $2; exit}' ~/.mozilla/firefox/profiles.ini 2>/dev/null || true)

  FIREFOX_PROFILE_PATH="${HOME}/.mozilla/firefox/${FIREFOX_PROFILE_DIR}"
  PREFS_FILE="${FIREFOX_PROFILE_PATH}/prefs.js"

  if [ -f "$PREFS_FILE" ]; then
    cat >> "$PREFS_FILE" <<'EOF'

// --- custom hardening prefs ---
user_pref("browser.uidensity", 1);
user_pref("extensions.pocket.api", "");
user_pref("extensions.pocket.enabled", false);
user_pref("extensions.pocket.site", "");
user_pref("extensions.pocket.oAuthConsumerKey", "");
user_pref("full-screen-api.transition-duration.enter", "0");
user_pref("full-screen-api.transition-duration.leave", "0");
user_pref("full-screen-api.warning.timeout", 0);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.donottrackheader.enabled", true);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.cachedClientID", "");
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.previousBuildID", "");
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.server_owner", "");
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("datareporting.healthreport.infoURL", "");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.policy.firstRunURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.tabs.crashReporting.email", false);
user_pref("browser.tabs.crashReporting.emailMe", false);
user_pref("breakpad.reportURL", "");
user_pref("security.ssl.errorReporting.automatic", false);
user_pref("toolkit.crashreporter.infoURL", "");
user_pref("network.allow-experiments", false);
user_pref("dom.ipc.plugins.reportCrashURL", false);
user_pref("dom.ipc.plugins.flash.subprocess.crashreporter.enabled", false);
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.tabmanager.enabled", false);
EOF
    echo "=== Firefox настроен ==="
  else
    echo "!!! prefs.js не найден. Сначала один раз запусти Firefox"
  fi

  echo 13 > "$PROGRESS_FILE"
fi

# 14. Установка sway-конфигов из репозитория, если добавишь их позже
if [ "$STEP" -lt 14 ]; then
  echo "Подготовка каталогов sway..."
  mkdir -p ~/.config/sway ~/.config/waybar ~/.config/wofi ~/.config/mako

  # Раскомментируй, когда добавишь эти директории в репозиторий:
  # cp -rv ./sway/* ~/.config/sway/
  # cp -rv ./waybar/* ~/.config/waybar/
  # cp -rv ./wofi/* ~/.config/wofi/
  # cp -rv ./mako/* ~/.config/mako/

  echo "=== Каталоги sway подготовлены ==="
  echo 14 > "$PROGRESS_FILE"
fi

# 15. Автостарт PipeWire-приложений и desktop entries
if [ "$STEP" -lt 15 ]; then
  echo "Настройка автозапуска..."
  mkdir -p ~/.config/autostart

  cat > ~/.config/autostart/easyeffects-service.desktop <<EOF
[Desktop Entry]
Name=Easy Effects
Comment=Easy Effects Service
Exec=easyeffects --gapplication-service
StartupNotify=false
Terminal=false
Type=Application
EOF

  echo "=== Автозапуск настроен ==="
  echo 15 > "$PROGRESS_FILE"
fi

echo "=== Установка завершена ==="
echo "После входа в tty добавь в ~/.bash_profile или запускай вручную:"
echo '  [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ] && exec sway'
