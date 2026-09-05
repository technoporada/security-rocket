#!/bin/bash

# Sprawdzenie, czy 'dialog' jest zainstalowany
if ! command -v dialog &> /dev/null; then
    echo "Narzędzie 'dialog' nie jest zainstalowane. Instalowanie..."
    sudo apt-get update && sudo apt-get install -y dialog
    clear
fi

# Funkcja pomocy
function show_help() {
    HELP_TEXT="Firewall to cyfrowy strażnik Twojego komputera. UFW (Uncomplicated Firewall) to narzędzie, które nim zarządza.\n\n--- POJĘCIA ---\n\n🔹 PORT: Wyobraź sobie, że Twój komputer ma tysiące ponumerowanych drzwi. Każde drzwi (port) są przeznaczone dla konkretnej usługi (np. port 80 dla stron WWW, port 22 dla SSH).\n\n🔹 REGUŁA (ALLOW / DENY):\n- ALLOW: Otwierasz konkretne drzwi (port) dla określonego rodzaju ruchu.\n- DENY: Zamykasz konkretne drzwi (port).\n\n🔹 PROFIL STANDARD (Deny In / Allow Out):\nDomyślnie wszystkie drzwi wejściowe są zamknięte. Nikt nie wejdzie, jeśli nie jest zaproszony (brak reguły ALLOW). Ale programy z Twojego komputera mogą swobodnie wychodzić na zewnątrz (np. przeglądarka WWW). To bezpieczny, zrównoważony wybór.\n\n🔹 PROFIL AGRESYWNY (Deny In / Deny Out):\nWszystkie drzwi, zarówno wejściowe, jak i WYJŚCIOWE, są domyślnie zamknięte. Maksymalne bezpieczeństwo. Programy nie połączą się z internetem, dopóki nie stworzysz dla nich konkretnej reguły ALLOW na wyjście. Używaj, gdy wiesz, co robisz."

    dialog --backtitle "AREKNET - Pomoc" --title "Wyjaśnienie pojęć" --msgbox "$HELP_TEXT" 30 80
}

# Główna pętla menu
while true; do
    choice=$(dialog --clear --backtitle "AREKNET - Centrum Zarządzania Siecią" \
                    --title "MENU FIREWALLA (UFW)" \
                    --menu "Wybierz opcję:" 20 70 12 \
                    "1" "Status UFW (prosty)" \
                    "2" "Status UFW (szczegółowy, numerowany)" \
                    "3" "Włącz UFW" \
                    "4" "Wyłącz UFW (niezalecane)" \
                    "5" "RESETUJ UFW (usuwa wszystkie reguły!)" \
                    "6" "Dodaj regułę ALLOW" \
                    "7" "Dodaj regułę DENY" \
                    "8" "Usuń regułę" \
                    "9" "Zastosuj profil STANDARD" \
                    "10" "Zastosuj profil AGRESYWNY" \
                    "H" "POMOC / Wyjaśnienie pojęć" \
                    "0" "Powrót do menu głównego" 2>&1 >/dev/tty)

    if [ -z "$choice" ]; then
        break
    fi

    case "$choice" in
        1)
            sudo ufw status | dialog --title "Status UFW" --programbox 20 70
            ;;
        2)
            sudo ufw status numbered | dialog --title "Status UFW (szczegółowy)" --programbox 20 70
            ;;
        3)
            sudo ufw --force enable | dialog --title "Włączanie UFW" --programbox 10 70
            dialog --title "Info" --msgbox "UFW zostało włączone." 8 40
            ;;
        4)
            sudo ufw disable | dialog --title "Wyłączanie UFW" --programbox 10 70
            dialog --title "Info" --msgbox "UFW zostało wyłączone." 8 40
            ;;
        5)
            dialog --title "POTWIERDZENIE" --yesno "Czy na pewno chcesz zresetować UFW? To usunie WSZYSTKIE reguły!" 8 60
            response=$?
            if [ $response -eq 0 ]; then
                sudo ufw --force reset | dialog --title "Resetowanie UFW" --programbox 10 70
                dialog --title "Info" --msgbox "UFW zostało zresetowane." 8 40
            else
                dialog --title "Info" --msgbox "Anulowano." 8 40
            fi
            ;;
        6)
            rule=$(dialog --title "Dodaj regułę ALLOW" --inputbox "Podaj port/protokół dozwolony (np. 8080/tcp):" 8 60 2>&1 >/dev/tty)
            if [ -n "$rule" ]; then
                sudo ufw allow "$rule"
                dialog --title "Info" --infobox "Dodano regułę: allow $rule" 5 40
                sleep 2
            fi
            ;;
        7)
            rule=$(dialog --title "Dodaj regułę DENY" --inputbox "Podaj port/protokół blokowany (np. 3306):" 8 60 2>&1 >/dev/tty)
            if [ -n "$rule" ]; then
                sudo ufw deny "$rule"
                dialog --title "Info" --infobox "Dodano regułę: deny $rule" 5 40
                sleep 2
            fi
            ;;
        8)
            (sudo ufw status numbered) > /tmp/ufw_status.txt
            dialog --title "Aktualne reguły" --textbox /tmp/ufw_status.txt 20 70
            rm /tmp/ufw_status.txt
            
            num=$(dialog --title "Usuń regułę" --inputbox "Podaj numer reguły do usunięcia:" 8 60 2>&1 >/dev/tty)
            if [ -n "$num" ]; then
                yes | sudo ufw delete "$num" > /dev/null 2>&1
                dialog --title "Info" --infobox "Wysłano polecenie usunięcia reguły numer $num." 5 50
                sleep 2
            fi
            ;;
        9)
            bash ./ufw_manager.sh standard | dialog --title "Aplikowanie profilu STANDARD" --programbox 20 70
            ;;
        10)
            bash ./ufw_manager.sh aggressive | dialog --title "Aplikowanie profilu AGRESYWNY" --programbox 20 70
            ;;
        H)
            show_help
            ;;
        0)
            break
            ;;
    esac
done

clear
