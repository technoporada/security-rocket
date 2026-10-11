#!/bin/bash
# system_audit.sh
# Zbiera stan systemu do jednego pliku. Tylko odczyt — nie zmienia niczego.
#
# Wynik trafi do /tmp/system_audit_<data>.txt i zawiera między innymi
# logi logowania, zawartość .ssh i listę plików zmienionych w /etc.
# To są dane wrażliwe: nie wklejaj tego pliku do repozytorium ani na czat.

set -uo pipefail

OUTPUT="${1:-/tmp/system_audit_$(date +%Y%m%d_%H%M%S).txt}"

echo "=== AUDYT SYSTEMU: $(date) ===" > "$OUTPUT"
echo "Wynik: $OUTPUT" >&2

{
  echo; echo "--- WHO ---";        who
  echo; echo "--- LOGOWANI ---";  w
  echo; echo "--- OSTATNIE LOGOWANIA ---"; last -n 20
  echo; echo "--- LOGINY ---";    lastlog 2>/dev/null | head -n 20
  echo; echo "--- PROCESY (50) ---"; ps aux --sort=-%cpu | head -n 50
  echo; echo "--- PORTY ---";     ss -tunap 2>/dev/null
  echo; echo "--- SOCKETY (50) ---"; lsof -i -P -n 2>/dev/null | head -n 50

  echo; echo "--- KONTO UYTKOWNIKOW ---"
  getent passwd | awk -F: '$3 >= 1000 {print $1, "uid="$3, "home="$6}'

  echo; echo "--- CRONTAB ---"
  for u in $(cut -f1 -d: /etc/passwd); do
    c=$(sudo -n crontab -u "$u" -l 2>/dev/null)
    [ -n "$c" ] && { echo "== $u =="; echo "$c"; }
  done
  ls -la /etc/cron.* /var/spool/cron/crontabs 2>/dev/null

  echo; echo "--- USLUGI URUCHOMIONE ---"; systemctl list-units --type=service --state=running 2>/dev/null
  echo; echo "--- USLUGI WLACZONE ---";   systemctl list-unit-files 2>/dev/null | grep enabled

  echo; echo "--- AUTH.LOG (ostatnie bledne logowania) ---"
  sudo -n grep -iE "failed|invalid|authentication error" /var/log/auth.log 2>/dev/null | tail -n 100

  echo; echo "--- ZMIENIONE PLIKI W /etc (7 dni) ---"
  sudo -n find /etc -type f -mtime -7 2>/dev/null | head -n 200

  echo; echo "--- KLUCZE SSH (NAZWY, NIE TREŚĆ) ---"
  sudo -n find /root/.ssh /home/*/.ssh -name '*.pub' -exec ls -la {} \; 2>/dev/null
} >> "$OUTPUT" 2>&1

echo "Gotowe. Plik z danymi wrażliwymi: $OUTPUT" >&2
echo "Przejrzyj go, potem usuń:  rm $OUTPUT" >&2
