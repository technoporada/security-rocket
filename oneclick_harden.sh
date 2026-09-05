#!/bin/bash
# oneclick_harden.sh
# Bezpieczny one-click hardening (SSH->klucze, AppArmor, sysctl, AIDE, UFW minimal)
set -euo pipefail

LOGDIR="$HOME/.local/share/hardening_runs"
mkdir -p "$LOGDIR"
RUNFILE="$LOGDIR/oneclick_$(date +%Y%m%d_%H%M%S).log"

echo "=== One-Click Hardening START ===" | tee "$RUNFILE"

# Backup ważnych plików
echo "Backup konfiguracji..." | tee -a "$RUNFILE"
sudo cp /etc/ssh/sshd_config "${LOGDIR}/sshd_config.bak.$(date +%s)" || true
sudo cp /etc/ufw/user.rules "${LOGDIR}/ufw_user.rules.bak.$(date +%s)" 2>/dev/null || true
sudo cp /etc/sysctl.d/99-hardening.conf "${LOGDIR}/sysctl_99-hardening.bak.$(date +%s)" 2>/dev/null || true

# 1) SSH hardening: wymusz klucze, wyłącz root i hasła
echo "→ SSH: Inteligentne wymuszanie logowania kluczem, wyłączanie haseł i root loginu" | tee -a "$RUNFILE"

# 1a) Bezpiecznik: jeśli NIE ma żadnego uprawnionego klucza, nie wyłączaj haseł
#     (inaczej ryzyko trwałego lockoutu SSH).
HAVE_KEY=0
for akf in "$HOME/.ssh/authorized_keys" /root/.ssh/authorized_keys; do
    if [ -s "$akf" ] 2>/dev/null; then
        HAVE_KEY=1
        break
    fi
done
if [ "$HAVE_KEY" -eq 0 ]; then
    echo "ABORT: brak kluczy w authorized_keys. Nie wyłączam logowania hasłem." | tee -a "$RUNFILE"
    echo "Najpierw dodaj klucz (ssh-copy-id) i uruchom ponownie." | tee -a "$RUNFILE"
    exit 3
fi
echo "OK: klucze znalezione, można bezpiecznie wyłączyć hasła." | tee -a "$RUNFILE"

# Ustaw PasswordAuthentication no
if sudo grep -qE "^\s*PasswordAuthentication\s+no\s*$" /etc/ssh/sshd_config; then
    echo "OK: PasswordAuthentication jest już ustawione na 'no'." | tee -a "$RUNFILE"
else
    echo "MODYFIKACJA: Ustawiam 'PasswordAuthentication no'." | tee -a "$RUNFILE"
    sudo sed -i.bak -r 's/^\s*#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# Ustaw PermitRootLogin no
if sudo grep -qE "^\s*PermitRootLogin\s+no\s*$" /etc/ssh/sshd_config; then
    echo "OK: PermitRootLogin jest już ustawione na 'no'." | tee -a "$RUNFILE"
else
    echo "MODYFIKACJA: Ustawiam 'PermitRootLogin no'." | tee -a "$RUNFILE"
    sudo sed -i.bak -r 's/^\s*#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' /etc/ssh/sshd_config
fi

# Ustaw PubkeyAuthentication yes
if sudo grep -qE "^\s*PubkeyAuthentication\s+yes\s*$" /etc/ssh/sshd_config; then
    echo "OK: PubkeyAuthentication jest już ustawione na 'yes'." | tee -a "$RUNFILE"
else
    echo "MODYFIKACJA: Ustawiam 'PubkeyAuthentication yes'." | tee -a "$RUNFILE"
    sudo sed -i.bak -r 's/^\s*#?\s*PubkeyAuthentication\s+.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
fi

sudo systemctl reload sshd 2>/dev/null || sudo service ssh reload 2>/dev/null || true

# 2) AppArmor: włącz i ustaw enforce tam, gdzie to możliwe
echo "→ AppArmor: włączanie" | tee -a "$RUNFILE"
sudo systemctl enable --now apparmor || true
# Nie przymuszamy wszystkich profilów — tylko włączamy serwis
aa_status_output=$(sudo aa-status 2>&1) || aa_status_output=""
echo "$aa_status_output" >> "$RUNFILE"

# 3) Sysctl hardening
echo "→ Sysctl: ustawianie podstawowego hardeningu" | tee -a "$RUNFILE"
cat <<'EOF' | sudo tee /etc/sysctl.d/99-hardening.conf
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_forward = 0
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
kernel.dmesg_restrict = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF
sudo sysctl --system >> "$RUNFILE" 2>&1 || true

# 4) UFW minimal (profil standard)
echo "→ UFW: uruchamianie profilu 'standard'" | tee -a "$RUNFILE"
bash ./ufw_manager.sh standard 2>&1 | tee -a "$RUNFILE"

# 5) AIDE instalacja i inicjalizacja
echo "→ Instalacja AIDE (integrity check)" | tee -a "$RUNFILE"
sudo apt update -qq
sudo apt install -y aide >/dev/null 2>&1 || true
if [ -f /var/lib/aide/aide.db.new ]; then
  echo "AIDE DB exists; skipping init" | tee -a "$RUNFILE"
else
  sudo aideinit >> "$RUNFILE" 2>&1 || true
  sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null || true
fi

echo "=== One-Click Hardening DONE ===" | tee -a "$RUNFILE"
echo "Log zapisany w: $RUNFILE"
