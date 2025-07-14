#!/usr/bin/env bash

set -e  # Прекратить выполнение при ошибке

PROGRESS_FILE="./.install_progress"
STEP=0
if [ -f "$PROGRESS_FILE" ]; then
  STEP=$(cat "$PROGRESS_FILE")
fi

echo "=== Начинаем установку dotfiles и настройку Fedora ==="

# Подготовка
if [ "$STEP" -lt 1 ]; then
    echo "Обновление пакетов и подключение репозиториев..."
    sudo dnf clean 
    sudo dnf makecache
    sudo dnf update -y
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y linux-firmware
    sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers xorg-x11-drv-amdgpu
    echo "=== Обновление и подключение прошло успешно ==="
    echo 1 > "$PROGRESS_FILE"
fi

if [ "$STEP" -lt 2 ]; then
    echo "Установка нужных пакетов..."
    sudo dnf install -y xorg-x11-server-Xwayland
    sudo dnf install -y xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs
    xdg-user-dirs-update --force
    sudo dnf install -y sway swaylock wofi waybar xdg-desktop-portal-wlr xdg-desktop-portal wl-clipboard grim slurp mako flatpak easyeffects qbittorrent lollypop tmux neovim python3-neovim fzf zoxide alacritty nmcli htop firefox polkit lxqt-policykit
    sudo dnf install -y dnf-plugins-core
    sudo dnf copr enable lihaohong/yazi
    sudo dnf install -y yazi
    
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak update --user
    
    sudo dnf install -y pipewire pipewire-pulseaudio pipewire-alsa pipewire-jack-audio-connection-kit wireplumber pipewire-utils
    systemctl --user enable pipewire
    systemctl --user enable wireplumber
    systemctl --user start pipewire wireplumber
    
    #Hiddify
    curl -L -o hiddify.rpm https://github.com/hiddify/hiddify-app/releases/download/v2.0.5/Hiddify-rpm-x64.rpm
    sudo dnf install -y ./hiddify.rpm
    rm -f hiddify.rpm
    
    #Onlyoffice
    curl -L -o onlyoffice.rpm https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm
    sudo dnf install -y ./onlyoffice.rpm
    rm -f onlyoffice.rpm
    
    #Obsidian
    flatpak install --user -y flathub md.obsidian.Obsidian
    
    #Telegram
    flatpak install --user -y flathub org.telegram.desktop
    
    #OBS Studio
    flatpak install --user -y flathub com.obsproject.Studio
    
    #Foliate
    flatpak install --user -y flathub com.github.johnfactotum.Foliate
    
    #Virtual Machine Manager
    sudo dnf install -y @virtualization
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
    echo 2 > "$PROGRESS_FILE"
fi

# Настройка bash
if [ "$STEP" -lt 3 ]; then
    echo "Настройка .bashrc..."
    cp -v ./bash/.bashrc ~/.bashrc
    echo "=== Bash конфиг применен ==="
    echo 3 > "$PROGRESS_FILE"
fi

# Установка шрифтов
if [ "$STEP" -lt 4 ]; then
    echo "Установка шрифтов..."
    mkdir -p ~/.local/share/fonts
    cp -rv ./fonts/* ~/.local/share/fonts/
    fc-cache -f -v  # Обновление кэша шрифтов
    echo "=== Шрифты готовы для выбора в Tweaks ==="
    echo 4 > "$PROGRESS_FILE"
fi

# Настройка alacritty и tmux
if [ "$STEP" -lt 5 ]; then
    echo "Настройка alacritty..."
    mkdir -p ~/.config/alacritty
    cp -rv ./alacritty/* ~/.config/alacritty/
    echo "=== Alacritty настроен  ==="
    echo "Настройка tmux..."
    mkdir -p ~/.config/tmux/
    cp -rv ./tmux/* ~/.config/tmux/
    echo 5 > "$PROGRESS_FILE"
fi

# Обновление GRUB
if [ "$STEP" -lt 6 ]; then
    echo "=== Настройка параметров GRUB... ==="
    sudo tee /etc/default/grub > /dev/null <<EOF
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_DISABLE_SUBMENU=y
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
EOF

# Генерируем новый конфиг grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    echo "=== GRUB настроен ==="
    echo 6 > "$PROGRESS_FILE"
fi

# Автостарт приложений
if [ "$STEP" -lt 7 ]; then
    echo "Настройка автозапуска..."
    mkdir -p ~/.config/autostart
    # EasyEffects service (фоновый режим)
    cat > ~/.config/autostart/easyeffects-service.desktop <<EOF
[Desktop Entry]
Name=Easy Effects
Comment=Easy Effects Service
Exec=easyeffects --gapplication-service
Icon=com.github.wwmm.easyeffects
StartupNotify=false
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF

    # Hiddify GUI
    cat > ~/.config/autostart/hiddify.desktop <<EOF
[Desktop Entry]
Type=Application
Version=2.0.5+20005
Name=Hiddify
GenericName=Hiddify
GenericName=Hiddify
Icon=hiddify
Exec=hiddify %U
Keywords=Hiddify;Proxy;VPN;V2ray;Nekoray;Xray;Psiphon;OpenVPN;
StartupNotify=true
X-GNOME-Autostart-enabled=true
EOF
    echo "=== Приложения поставлены в автозапуск ==="
    echo 7 > "$PROGRESS_FILE"
fi

# Настройка pipewire для аудиокарты
if [ "$STEP" -lt 8 ]; then
    echo "Настройка pipewire под аудиокарту Audient iD4 Mk2..."
    mkdir -p ~/.config/pipewire
    cp ./sound/pipewire.conf ~/.config/pipewire/pipewire.conf
    echo "=== Аудиокарта настроена ==="
    echo 8 > "$PROGRESS_FILE"
fi

# Настройка firefox
if [ "$STEP" -lt 9 ]; then
    echo "Настройка firefox..."

    # Запускаем Firefox в фоне (без UI, с флагом no-remote и профилем по умолчанию)
    firefox --headless &
    FIREFOX_PID=$!

    # Ждём несколько секунд, чтобы профиль создался
    sleep 10

    # Завершаем Firefox
    kill $FIREFOX_PID
    wait $FIREFOX_PID 2>/dev/null || true

    FIREFOX_PROFILE_DIR=$(awk -F= '/^\[Profile[0-9]+\]/{p=0}
                                  /^Name=default-release$/{p=1}
                                  p && /^Path=/{print $2; exit}' ~/.mozilla/firefox/profiles.ini)

    FIREFOX_PROFILE_PATH="$HOME/.mozilla/firefox/$FIREFOX_PROFILE_DIR"
    PREFS_FILE="$FIREFOX_PROFILE_PATH/prefs.js"

    if [ -f "$PREFS_FILE" ]; then
      echo "🛠  Вписываю настройки в $PREFS_FILE"
      cat >> "$PREFS_FILE" <<EOF

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
      echo "!!! prefs.js не найден. Возможно, Firefox не запускался !!!"
    fi
    echo 9 > "$PROGRESS_FILE"
fi

# Перенос картинок
if [ "$STEP" -lt 10 ]; then
    echo "Перенос картинок..."
    cp -r ./pics/* ~/Pictures
    echo "=== Картинки перемещены  ==="
    echo 10 > "$PROGRESS_FILE"
fi

# Настройка docker + podman
if [ "$STEP" -lt 11 ]; then
    echo "Настройка docker + podman..."
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo dnf install -y podman
    echo "=== Docker и podamn настроены  ==="
    echo 11 > "$PROGRESS_FILE"                                               fi

# Настройка Sway
if [ "$STEP" -lt 12 ]; then
    echo "Настройка Sway..."
    mkdir -p ~/.config/sway
    cp -r ./sway/* ~/.configesway/
    echo "=== Sway настроен  ==="
    echo 12 > "$PROGRESS_FILE"
fi


echo "Установка завершена. Перезагружаем систему через 10 секунд..."
echo "Для отмены нажмите Ctrl+C"
sleep 10
sudo systemctl reboot
