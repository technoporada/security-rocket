#!/bin/bash

LOG_FILE="reinstall_log_$(date +%Y%m%d_%H%M%S).log"

echo "!!! WAŻNE: Przed uruchomieniem tego skryptu wykonaj kopię zapasową systemu !!!" | tee -a "$LOG_FILE"
echo "Ten skrypt spróbuje przeinstalować kluczowe komponenty systemowe." | tee -a "$LOG_FILE"
echo "Naciśnij ENTER, aby kontynuować, lub CTRL+C, aby anulować." | tee -a "$LOG_FILE"
read

echo "Rozpoczynam reinstalację kluczowych komponentów..." | tee -a "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "--------------------------------------------------" | tee -a "$LOG_FILE"

# 1. Aktualizacja list pakietów
echo -e "\n### Aktualizacja list pakietów ###" | tee -a "$LOG_FILE"
sudo apt update | tee -a "$LOG_FILE"

# 2. Reinstalacja środowiska Cinnamon
echo -e "\n### Reinstalacja środowiska Cinnamon ###" | tee -a "$LOG_FILE"
sudo apt install --reinstall -y mint-meta-cinnamon cinnamon-session cinnamon | tee -a "$LOG_FILE"

# 3. Reinstalacja pakietów GStreamer i VA-API
echo -e "\n### Reinstalacja pakietów GStreamer i VA-API ###" | tee -a "$LOG_FILE"
sudo apt install --reinstall -y libgstreamer1.0-0 gstreamer1.0-vaapi gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good | tee -a "$LOG_FILE"

# 4. Reinstalacja sterowników grafiki Intel (Mesa VA-API drivers i xserver-xorg-video-intel)
echo -e "\n### Reinstalacja sterowników grafiki Intel ###" | tee -a "$LOG_FILE"
sudo apt install --reinstall -y mesa-va-drivers intel-media-va-driver xserver-xorg-video-intel | tee -a "$LOG_FILE"

# 5. Reinstalacja zramswap
echo -e "\n### Reinstalacja zramswap ###" | tee -a "$LOG_FILE"
sudo apt install --reinstall -y zram-config | tee -a "$LOG_FILE"

# 6. Czyszczenie pakietów
echo -e "\n### Czyszczenie pakietów ###" | tee -a "$LOG_FILE"
sudo apt autoremove -y | tee -a "$LOG_FILE"
sudo apt autoclean | tee -a "$LOG_FILE"

echo -e "\n--------------------------------------------------" | tee -a "$LOG_FILE"
echo "Reinstalacja zakończona. Wyniki zapisano w: $LOG_FILE" | tee -a "$LOG_FILE"
echo "!!! WAŻNE: Po zakończeniu działania skryptu, proszę uruchomić ponownie komputer. !!!" | tee -a "$LOG_FILE"
