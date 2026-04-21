#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# Download and install k9s TUI

curl -sS https://webi.sh/k9s | sh
source ~/.config/envman/PATH.env

# Copy k9s to /usr/local/bin for sudo access
sudo cp ~/.local/bin/k9s /usr/local/bin/k9s
sudo chmod +x /usr/local/bin/k9s