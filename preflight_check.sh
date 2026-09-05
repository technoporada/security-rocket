#!/bin/bash
# preflight_check.sh
set -euo pipefail
LOGDIR="$HOME/.local/share/hardening_runs"
mkdir -p "$LOGDIR"
OUT="$LOGDIR/preflight_$(date +%Y%m%d_%H%M%S).log"
echo "PRE-FLIGHT CHECK $(date)" | tee "$OUT"

# 1) Czy jest lokalny użytkownik i powłoka?
echo "User: $USER" | tee -a "$OUT"
echo "Shell: $SHELL" | tee -a "$OUT"

# 2) Czy jest klucz SSH w ~/.ssh (przed blokadą haseł!)?
echo "Sprawdzanie kluczy SSH..." | tee -a "$OUT"
if compgen -G "$HOME/.ssh/*.pub" > /dev/null; then
  echo "OK: znaleziono klucz publiczny ~/.ssh/*.pub" | tee -a "$OUT"
  ls -1 "$HOME/.ssh/"*.pub 2>/dev/null | tee -a "$OUT"
else
  echo "ERROR: Nie znaleziono klucza publicznego w ~/.ssh. Zrób to PRZED uruchomieniem hardeningu!" | tee -a "$OUT"
  exit 1
fi

# 3) Czy działasz zdalnie przez SSH? (ostrzegamy)
if [ -n "${SSH_CONNECTION:-}" ]; then
  echo "Uwaga: jesteś aktualnie połączony przez SSH. Skrypt ma mechanizmy rollback - jednak miej pod ręką fizyczny dostęp na wypadek problemów." | tee -a "$OUT"
fi

# 4) Backup ważnych plików konfiguracyjnych
BKP="$LOGDIR/preflight_backups_$(date +%s)"
mkdir -p "$BKP"
echo "Robię backup plików konfiguracyjnych do $BKP" | tee -a "$OUT"
sudo cp /etc/ssh/sshd_config "$BKP/sshd_config" 2>/dev/null || true
sudo cp /etc/ufw/user.rules "$BKP/ufw_user.rules" 2>/dev/null || true
sudo -n cp /etc/sysctl.d/99-hardening.conf "$BKP/sysctl_99-hardening.conf" 2>/dev/null || true

# 5) Snapshot obecnego stanu (ss, ufw, ip tables)
echo "Zrzut ss -tulpn" | tee -a "$OUT"
ss -tulpn | tee -a "$OUT"
echo "UFW status" | tee -a "$OUT"
sudo ufw status verbose | tee -a "$OUT" || true

echo "Preflight OK" | tee -a "$OUT"
echo "LOG: $OUT"
