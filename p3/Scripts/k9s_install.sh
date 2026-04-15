#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Téléchargement et installation du tui K9S en mode admin

curl -sS https://webi.sh/k9s | sh
source ~/.config/envman/PATH.env

# Copier k9s vers /usr/local/bin pour accès sudo
sudo cp ~/.local/bin/k9s /usr/local/bin/k9s
sudo chmod +x /usr/local/bin/k9s