#!/bin/bash

LOG_FILE="system_check_$(date +%Y%m%d_%H%M%S).log"
echo "Rozpoczynam sprawdzanie systemu Linux Mint..." | tee -a "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "--------------------------------------------------" | tee -a "$LOG_FILE"

echo -e "\n### Sprawdzanie użycia dysku ###" | tee -a "$LOG_FILE"
df -h | tee -a "$LOG_FILE"

echo -e "\n### Sprawdzanie użycia pamięci ###" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"

echo -e "\n### Sprawdzanie statusu usług systemowych (failed) ###" | tee -a "$LOG_FILE"
systemctl --failed | tee -a "$LOG_FILE"

echo -e "\n### Ostatnie błędy w logach systemowych (journalctl -p err -b) ###" | tee -a "$LOG_FILE"
journalctl -p err -b | tee -a "$LOG_FILE"

echo -e "\n### Sprawdzanie statusu pakietów (broken) ###" | tee -a "$LOG_FILE"
dpkg --audit | tee -a "$LOG_FILE"

echo -e "\n### Sprawdzanie dostępnych aktualizacji ###" | tee -a "$LOG_FILE"
apt list --upgradable | tee -a "$LOG_FILE"

echo -e "\n--------------------------------------------------" | tee -a "$LOG_FILE"
echo "Sprawdzanie zakończone. Wyniki zapisano w: $LOG_FILE" | tee -a "$LOG_FILE"
