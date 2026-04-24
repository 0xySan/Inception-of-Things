#!/bin/bash
# ===============================================================
#  EEEEE    M   M     A     I    L        L        EEEEE    TTTTT
#  E        MM MM    A A    I    L        L        E          T
#  EEEE     M M M   AAAAA   I    L        L        EEEE       T
#  E        M   M   A   A   I    L        L        E          T
#  EEEEE    M   M   A   A   I    LLLLL    LLLLL    EEEEE      T
# ===============================================================

# ===============================================================
# Information
# ===============================================================

BG_WHITE="\t\033[48;2;255;255;255m"
FG_BLACK="\033[38;2;0;0;0m"
RESET="\033[0m"

note() { echo -e "${BG_WHITE}${FG_BLACK} $*${RESET}"; }
ARGOCD_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "To retrieve")
GITLAB_PASSWORD=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "To retrieve")
echo ""
note "╔════════════════════════════════════════════════════════════╗ "
note "║          ✅ Installation Successful!                       ║ "
note "╠════════════════════════════════════════════════════════════╣ "
note "║  📊 SERVICES                                               ║ "
note "║  ├─ ArgoCD:        http://argocd.localhost                 ║ "
note "║  ├─ Application:   http://localhost                        ║ "
note "║  ├─ GitLab:        http://gitlab.localhost                 ║ "
note "║  └─ K3D Cluster:   inception-of-things (3 nodes)           ║ "
note "║                                                            ║ "
note "║  🔑 AUTHENTICATION                                         ║ "
note "║  ├─ Username:      admin                                   ║ "
note "║  └─ Password:      ${ARGOCD_PASSWORD}                        ║ "
note "║  ├─ GitLab user:   root                                    ║ "
note "║  └─ GitLab pass:   ${GITLAB_PASSWORD}                       ║ "
note "║                                                            ║ "
note "║  🛠️  USEFUL COMMANDS                                        ║ "
note "║  ├─ kubectl:       sudo kubectl get pods -A                ║ "
note "║  ├─ k9s (TUI):     sudo k9s                                ║ "
note "║  ├─ Uninstall:     bash Scripts/uninstall.sh               ║ "
note "║  └─ Refresh:       kubectl get cronjob,jobs,pods -n argocd ║ "
note "╚════════════════════════════════════════════════════════════╝ "
echo ""
