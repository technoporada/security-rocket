#!/bin/bash
# ufw_manager.sh
# Scentralizowany skrypt do zarzadzania profilami UFW.
# Uzycie: ./ufw_manager.sh {standard|aggressive}

set -euo pipefail

MODE="${1:-standard}"
CONFIRM="${2:-}"

echo "--- UFW Manager ---"
echo "Tryb: $MODE"

if [[ "$MODE" != "standard" && "$MODE" != "aggressive" ]]; then
    echo "Nieznany tryb: $MODE. Uzyj 'standard' lub 'aggressive'."
    exit 1
fi

if [[ "$MODE" == "aggressive" ]]; then
    echo "UWAGA: tryb AGGRESSIVE ustawia 'default deny outgoing' i odcyna"
    echo "       CALY ruch wychodzacy poza biallista (tylko DNS, SSH, HTTP/S)."
    echo "       Dostep do innych serwisow wychodzacych zostanie zablokowany."
    echo "       Aby kontynuowac, musisz przejsc do biallista potrzebne uslugi."
fi

if [[ "$CONFIRM" != "--yes" ]]; then
    read -r -p "Kontynuowac? Skrypt zresetuje reguly UFW. [tak/NIE]: " ANS
    if [[ "$ANS" != "tak" && "$ANS" != "t" && "$ANS" != "y" ]]; then
        echo "Anulowano."
        exit 1
    fi
fi

echo "Resetowanie UFW do stanu poczatkowego..."
sudo ufw --force reset

# Reguły wspólne dla obu trybów
echo "Konfiguracja podstawowych regul (loopback, SSH, HTTP/S)..."
sudo ufw allow in on lo
sudo ufw allow out on lo
sudo ufw allow ssh      # 22
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow from 127.0.0.1 to any port 11434 proto tcp # Ollama

if [[ "$MODE" == "standard" ]]; then
    echo "Tryb: STANDARD (deny in, allow out)"
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

elif [[ "$MODE" == "aggressive" ]]; then
    echo "Tryb: AGGRESSIVE (deny in, deny out)"
    echo "Otwieranie DNS (tcp/udp 53) zeby nie zgubic sieci..."
    sudo ufw allow out 53/tcp
    sudo ufw allow out 53/udp
    sudo ufw default deny incoming
    sudo ufw default deny outgoing
    
    echo "Blokowanie multicast (mDNS, SSDP)..."
    sudo ufw deny out to 224.0.0.251 port 5353 proto udp
    sudo ufw deny out to 239.255.255.250 port 1900 proto udp

else
    echo "Nieznany tryb: $MODE. Uzyj 'standard' lub 'aggressive'."
    exit 1
fi

echo "Wlaczanie UFW i logowania..."
sudo ufw --force enable
sudo ufw logging on

echo "Konfiguracja UFW skonczona. Tryb: $MODE"
sudo ufw status numbered
