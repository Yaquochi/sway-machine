1) git clone https://github.com/Yaquochi/dotfiles.git
2) cd dotfiles
3) sudo chmod +x install.sh
4) ./install.sh

Добавить в easyeffects конфиг с эквалайзером
--------------------------------------------

Далее речь пройдет про ускорение системы и автозагрузку
Следующие команды запустят тесты на загрузку системы и покажут время
systemd-analyze
systemd-analyze critical-chain
systemd-analyze blame | head -n 20

sudo systemctl enable docker.socket #если нужен docker, но не хочется ставить в автозагрузку
sudo systemctl enable docker.service #полная автозагрузка docker
