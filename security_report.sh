#!/bin/bash
echo "===== SECURITY REPORT ====="
echo "Data: $(date)"
echo

echo "--- Aktywne porty TCP/UDP ---"
ss -tulpn
echo

echo "--- Status SSH ---"
systemctl is-active ssh && echo "SSH działa" || echo "SSH nie działa"
echo

echo "--- UFW ---"
sudo ufw status verbose
echo

echo "--- Usługi AppArmor ---"
systemctl is-active apparmor && echo "AppArmor aktywny" || echo "AppArmor nieaktywny"
echo

echo "--- AIDE ---"
if [ -x /usr/sbin/aide ]; then
    echo "AIDE zainstalowane. Status init:"
    sudo -n aide --check | head -20
else
    echo "AIDE nie jest zainstalowane"
fi
echo

echo "===== KONIEC RAPORTU ====="
