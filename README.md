Скачать на флешку минимальный образ:
https://download.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-42-1.1.iso

0) mkdir -p ~/repositories/
1) git clone https://github.com/Yaquochi/sway-machine.git
2) cd dotfiles
3) sudo chmod +x install.sh
4) ./install.sh

После входа в сессию sway выполнить:
xdg-user-dirs-update --force
cp -r ~/sway-machine/pics/* ~/Pictures

Добавить в easyeffects конфиг с эквалайзером

Если нужен docker или podman, можно включить через sudo systemctl start dockre/podman

--------------------------------------------

Далее речь пройдет про ускорение системы и автозагрузку
Следующие команды запустят тесты на загрузку системы и покажут время
systemd-analyze
systemd-analyze critical-chain
systemd-analyze blame | head -n 20

sudo systemctl enable docker.socket #если нужен docker, но не хочется ставить в автозагрузку
sudo systemctl enable docker.service #полная автозагрузка docker

--------------------------------------------

