#!/bin/bash
# ufw_manager.sh
# Reguly UFW dla systemu, ktory ma dzialac.
#
# Jedyna regula: system musi dzialac. Ten skrypt NIE moze zablokowac ruchu
# wychodzacego — na maszynie zdalnej odcięcie wychodzacego oznacza utrate
# dostepu do SSH, a na VPS u providera utrate jedynego kanalu, przez ktory
# ktos moze wejsc. Tryb "aggressive" (deny outgoing) byl w tym repo i usuniety
# 2026-10-11. Jesli chcesz blokowac wychodzace, zrob to recznie i wtedy
# sprawdz, czy masz drugi sposob wejscia na maszyne.

set -euo pipefail

echo "--- UFW Manager ---"

echo "Resetowanie UFW do stanu poczatkowego..."
sudo ufw --force reset

echo "Konfiguracja regul (loopback, SSH, HTTP/S, Ollama)..."
sudo ufw allow in on lo
sudo ufw allow out on lo
sudo ufw allow ssh      # 22
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow from 127.0.0.1 to any port 11434 proto tcp # Ollama

# Deny wchodzace, allow wychodzace. To jest jedyna sensowna konfiguracja
# dla maszyny, z ktorej ktos korzysta.
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Blokowanie znanych niebezpiecznych portow (NetBIOS, SMB, RPC)..."
MALICIOUS_IN=(137:139/udp 137:139/tcp 445/tcp 135/tcp 23/tcp 21/tcp 20/tcp 161:162/udp 1900/udp 3306/tcp 1433/tcp 3389/tcp)
for p in "${MALICIOUS_IN[@]}"; do
    sudo ufw deny in $p
done

echo "Blokowanie portow malware (C2)..."
MALICIOUS_C2=(4444 5555 6667 12345 31337 1337 27444 27374 50000)
for p in "${MALICIOUS_C2[@]}"; do
    sudo ufw deny proto tcp to any port "$p"
    sudo ufw deny proto udp to any port "$p"
done

echo "Blokowanie multicast (mDNS, SSDP)..."
sudo ufw deny out to 224.0.0.251 port 5353 proto udp
sudo ufw deny out to 239.255.255.250 port 1900 proto udp

echo "Wlaczanie UFW i logowania..."
sudo ufw --force enable
sudo ufw logging on

echo "Konfiguracja UFW skonczona."
sudo ufw status numbered

echo ""
echo "Regula wychodzaca: allow. Jesli zmienisz to recznie na deny,"
echo "upewnij sie, ze masz inny dostep do tej maszyny niz SSH."
