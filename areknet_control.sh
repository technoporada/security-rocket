#!/bin/bash

# Sprawdzenie, czy 'dialog' jest zainstalowany
if ! command -v dialog &> /dev/null; then
    echo "Narzędzie 'dialog' nie jest zainstalowane. Instalowanie..."
    sudo apt-get update && sudo apt-get install -y dialog
    clear
fi

# Główna pętla menu
while true; do
    choice=$(dialog --clear --backtitle "AREKNET - GŁÓWNE CENTRUM DOWODZENIA" \
                    --title "MENU GŁÓWNE" \
                    --menu "Wybierz moduł:" 15 60 4 \
                    "1" "Hardening Systemu (Automatyczny)" \
                    "2" "Zarządzanie Firewallem (Interaktywne TUI)" \
                    "3" "Audyt i Narzędzia Systemowe (CLI)" \
                    "0" "Wyjście" 2>&1 >/dev/tty)

    if [ -z "$choice" ]; then
        break
    fi

    case "$choice" in
        1)
            mode=$(dialog --title "Tryb Hardeningu" --inputbox "Wybierz tryb: 'oneclick' lub 'hardcore'" 8 60 2>&1 >/dev/tty)
            if [ -n "$mode" ]; then
                clear
                echo "Uruchamianie modułu Hardeningu w trybie: $mode"
                bash ./apply_and_verify.sh "$mode"
                echo -e "\nZakończono. Naciśnij Enter, aby wrócić do menu..."
                read -r
            fi
            ;;
        2)
            bash ./areknet_firewall_menu.sh
            ;;
        3)
            clear
            bash ./areknet_system_utils.sh
            clear
            ;;
        0)
            break
            ;;
    esac
done

clear
echo "AREKNET zakończył działanie."
