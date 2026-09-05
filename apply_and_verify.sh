#!/bin/bash
# apply_and_verify.sh
# Uwaga: ten skrypt uruchamia wybraną wersję hardeningu (oneclick | hardcore),
# wykonuje testy, analizuje, robi rollback w razie krytycznego błędu.
set -euo pipefail
MODE="${1:-}"
LOGDIR="$HOME/.local/share/hardening_runs"
mkdir -p "$LOGDIR"
RUN="$LOGDIR/apply_$(date +%Y%m%d_%H%M%S).log"
echo "APPLY & VERIFY START $(date)" | tee "$RUN"

if [[ "$MODE" != "oneclick" && "$MODE" != "hardcore" ]]; then
  echo "Użycie: $0 {oneclick|hardcore}" | tee -a "$RUN"
  exit 2
fi

# 1) preflight
echo "1) Preflight check..." | tee -a "$RUN"
bash ./preflight_check.sh 2>&1 | tee -a "$RUN"

# 2) uruchom wybrany hardening
echo "2) Uruchamiam $MODE ..." | tee -a "$RUN"
if [ "$MODE" = "oneclick" ]; then
  bash ./oneclick_harden.sh 2>&1 | tee -a "$RUN"
else
  if [ -f ./OLD/hardcore_extreme.sh ]; then
    bash ./OLD/hardcore_extreme.sh 2>&1 | tee -a "$RUN"
  else
    echo "UWAGA: brak ./OLD/hardcore_extreme.sh - pomijam tryb hardcore" | tee -a "$RUN"
  fi
fi

# krótkie opóźnienie, dać systemowi czas na reload usług
sleep 2

# 3) Testy podstawowe (ss, ufw)
echo "3) Testy: ss -tulpn i ufw status" | tee -a "$RUN"
ss -tulpn | tee -a "$RUN"
sudo ufw status verbose | tee -a "$RUN"

# 4) Testy łączności (ważne)
# Sprawdzimy: czy SSH lokalnie działa, czy HTTP/HTTPS wychodzą działają (curl test)
echo "4) Testy łączności" | tee -a "$RUN"
SSH_OK=0
if ss -tulpn | grep -q ":22 "; then
  echo "  SSH w nasłuchu (lokalnie) - OK" | tee -a "$RUN"
  SSH_OK=1
else
  echo "  WARNING: SSH nie nasłuchuje na 22" | tee -a "$RUN"
fi

# Test HTTP(S) wychodząco - próbujemy połączyć z example.com:80 i :443
HTTP_OK=0
if command -v curl >/dev/null 2>&1; then
  echo "  Curl test HTTP" | tee -a "$RUN"
  if curl -Is --max-time 5 http://example.com >/dev/null 2>&1; then
    echo "   HTTP OK" | tee -a "$RUN"
    HTTP_OK=1
  else
    echo "   HTTP FAIL (może deny outgoing?)" | tee -a "$RUN"
  fi
  echo "  Curl test HTTPS" | tee -a "$RUN"
  if curl -Is --max-time 5 https://example.com >/dev/null 2>&1; then
    echo "   HTTPS OK" | tee -a "$RUN"
    HTTP_OK=1
  else
    echo "   HTTPS FAIL (może deny outgoing?)" | tee -a "$RUN"
  fi
else
  echo "  curl nie zainstalowany, pomijam test HTTP/HTTPS" | tee -a "$RUN"
fi

# 5) Analiza wyników i decyzja
echo "5) Analiza wyników..." | tee -a "$RUN"
# Krytyczne: SSH nie działa lub (w trybie oneclick) brak dostępu do sieci podstawowej?
CRIT=0
if [ "$SSH_OK" -eq 0 ]; then
  echo "  CRITICAL: SSH brak - wymagana natychmiastowa reakcja" | tee -a "$RUN"
  CRIT=1
fi

# W hardcore: brak HTTP/HTTPS to przewidywane jeśli deny outgoing, więc nie traktujemy jako CRIT
if [ "$MODE" = "oneclick" ]; then
  if [ "$HTTP_OK" -eq 0 ]; then
    echo "  WARNING: W trybie oneclick HTTP/HTTPS nie działają - sprawdź reguły wychodzące" | tee -a "$RUN"
  fi
fi

# Jeśli krytyczne, wykonaj rollback
if [ "$CRIT" -eq 1 ]; then
  echo "6) WYKRYTO PROBLEM KRYTYCZNY - wykonuję rollback (ufw reset + przywrócenie sshd_config)" | tee -a "$RUN"
  sudo ufw --force reset | tee -a "$RUN" || true
  # Przywróć backupy sshd_config utworzone przez oneclick_harden.sh
  for f in ~/.local/share/hardening_runs/sshd_config.bak.*; do
    if [ -f "$f" ]; then
      echo "  Przywracam $f do /etc/ssh/sshd_config" | tee -a "$RUN"
      sudo cp "$f" /etc/ssh/sshd_config 2>/dev/null || true
    fi
  done
  # Przywróć reguły UFW z backupów utworzonych przez oneclick_harden.sh
  for f in ~/.local/share/hardening_runs/ufw_user.rules.bak.*; do
    if [ -f "$f" ]; then
      echo "  Przywracam $f do /etc/ufw/user.rules" | tee -a "$RUN"
      sudo cp "$f" /etc/ufw/user.rules 2>/dev/null || true
    fi
  done
  # Przywróć sysctl z backupów utworzonych przez oneclick_harden.sh
  for f in ~/.local/share/hardening_runs/sysctl_99-hardening.bak.*; do
    if [ -f "$f" ]; then
      echo "  Przywracam $f do /etc/sysctl.d/99-hardening.conf" | tee -a "$RUN"
      sudo cp "$f" /etc/sysctl.d/99-hardening.conf 2>/dev/null || true
    fi
  done
  sudo -n systemctl reload sshd 2>/dev/null || sudo service ssh reload 2>/dev/null || true
  echo "Rollback wykonany. Sprawdź log: $RUN" | tee -a "$RUN"
  exit 3
fi

# 7) Zapis końcowy i zamknięcie
echo "7) Wszystko OK (lub akceptowalny stan dla hardcore). Zapisuję log: $RUN" | tee -a "$RUN"
echo "$(date --iso-8601=seconds) - wykonałem: $MODE" >> "$LOGDIR/history.txt"
echo "Koniec." | tee -a "$RUN"