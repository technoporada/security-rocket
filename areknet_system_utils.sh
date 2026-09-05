#!/bin/bash

# Sprawdzenie, czy 'dialog' jest zainstalowany
if ! command -v dialog &> /dev/null;
then
    echo "Narzędzie 'dialog' nie jest zainstalowane. Instalowanie..."
    sudo apt-get update && sudo apt-get install -y dialog
    clear
fi

# --- FUNKCJE POMOCNICZE ---

install_package() {
    if ! command -v "$1" &> /dev/null;
then
        (sudo apt-get update && sudo apt-get install -y "$2") | dialog --title "Instalacja $2" --programbox 20 70
    fi
}

# Funkcja do uzyskiwania bardziej przyjaznych nazw procesów
get_friendly_process_name() {
    local cmd="$1"
    # Próba identyfikacji popularnych aplikacji
    if [[ "$cmd" == *"/opt/google/chrome"* ]]; then echo "Google Chrome"; return; fi
    if [[ "$cmd" == *"/usr/lib/firefox"* ]]; then echo "Firefox"; return; fi
    if [[ "$cmd" == *"/usr/bin/gnome-terminal"* ]]; then echo "Gnome Terminal"; return; fi
    if [[ "$cmd" == *"/usr/bin/cinnamon"* ]]; then echo "Cinnamon Desktop"; return; fi
    if [[ "$cmd" == *"/usr/lib/libreoffice"* ]]; then echo "LibreOffice"; return; fi
    if [[ "$cmd" == *"/usr/bin/code"* ]]; then echo "VS Code"; return; fi
    if [[ "$cmd" == *"/usr/bin/vlc"* ]]; then echo "VLC Media Player"; return; fi
    if [[ "$cmd" == *"/usr/bin/discord"* ]]; then echo "Discord"; return; fi
    if [[ "$cmd" == *"/usr/bin/spotify"* ]]; then echo "Spotify"; return; fi
    if [[ "$cmd" == *"/usr/bin/thunderbird"* ]]; then echo "Thunderbird"; return; fi
    if [[ "$cmd" == *"/usr/bin/gnome-shell"* ]]; then echo "GNOME Shell"; return; fi
    if [[ "$cmd" == *"/usr/bin/nemo"* ]]; then echo "Nemo File Manager"; return; fi
    if [[ "$cmd" == *"/usr/bin/xed"* ]]; then echo "Xed Text Editor"; return; fi
    if [[ "$cmd" == *"/usr/bin/mintupdate"* ]]; then echo "Mint Update Manager"; return; fi
    if [[ "$cmd" == *"/usr/bin/python3"* && "$cmd" == *"/usr/bin/gjs"* ]]; then echo "GJS Script"; return; fi
    
    # Fallback: wyodrębnij nazwę bazową lub skróć
    echo "$cmd" | awk '{print $1}' | xargs basename | cut -c 1-30
}

system_health_dashboard() {
    install_package bc bc # Potrzebne do obliczeń zmiennoprzecinkowych
    while true;
do
        # --- ZBIERANIE DANYCH ---
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' )
        ram_info=$(free -m | grep Mem)
        ram_total=$(echo $ram_info | awk '{print $2}' )
        ram_used=$(echo $ram_info | awk '{print $3}' )
        ram_percent=$(awk "BEGIN {printf \"%.0f\", ($ram_used/$ram_total)*100}")
        disk_usage=$(df -h / /home | tail -n +2)
        
        # Pobieranie procesów i formatowanie dla raportu
        top_cpu_raw=$(ps -eo pid,%cpu,cmd --sort=-%cpu | head -n 6 | tail -n +2)
        top_mem_raw=$(ps -eo pid,%mem,cmd --sort=-%mem | head -n 6 | tail -n +2)

        top_cpu_formatted=""
        while IFS= read -r line; do
            pid=$(echo "$line" | awk '{print $1}' )
            cpu=$(echo "$line" | awk '{print $2}' )
            cmd_raw=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')
            friendly_name=$(get_friendly_process_name "$cmd_raw")
            top_cpu_formatted+="PID: $pid, CPU: $cpu%%, Aplikacja: $friendly_name\n"
        done <<< "$top_cpu_raw"

        top_mem_formatted=""
        while IFS= read -r line; do
            pid=$(echo "$line" | awk '{print $1}' )
            mem=$(echo "$line" | awk '{print $3}' )
            cmd_raw=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')
            friendly_name=$(get_friendly_process_name "$cmd_raw")
            top_mem_formatted+="PID: $pid, RAM: $mem%%, Aplikacja: $friendly_name\n"
        done <<< "$top_mem_raw"

        # --- TWORZENIE RAPORTU ---
        report="PULPIT ZDROWIA SYSTEMU\n\n"
        report+="--- PROCESOR (CPU) ---\n"
        report+="Aktualne użycie: ${cpu_usage}%%\n"
        if (( $(echo "$cpu_usage > 90" | bc -l) )); then
            report+="UWAGA: Bardzo wysokie użycie CPU! Sprawdź poniższą listę procesów.\n"
        fi
        
        report+="\n--- PAMIĘĆ (RAM) ---\n"
        report+="Używana: ${ram_used}MB / ${ram_total}MB (${ram_percent}%%)\n"
        if (( $(echo "$ram_percent > 90" | bc -l) )); then
            report+="UWAGA: Mało wolnej pamięci RAM! Rozważ zamknięcie zbędnych aplikacji.\n"
        fi

        report+="\n--- DYSK TWARDY ---\n"
        report+="$disk_usage\n"

        report+="\n--- SUGESTIE: PROCESY DO OBSERWACJI ---\n\n"
        report+="Top 5 wg CPU:\n$top_cpu_formatted\n"
        report+="Top 5 wg RAM:\n$top_mem_formatted\n"

        # --- WYŚWIETLANIE ---
        dialog --backtitle "Pulpit Zdrowia Systemu" --title "Dashboard" --msgbox "$report" 40 90

        # --- MENU AKCJI ---
        action=$(dialog --backtitle "Pulpit Zdrowia Systemu" \
                        --title "Akcje" \
                        --menu "Co chcesz zrobić?" 15 60 4 \
                        "1" "Odśwież dane" \
                        "2" "Zabij proces (interaktywny wybór)" \
                        "3" "Uruchom htop (widok zaawansowany)" \
                        "0" "Powrót do menu" 2>&1 >/dev/tty)
        
        if [ -z "$action" ]; then break; fi

        case "$action" in
            1) continue ;; 
            2)
                # Generowanie listy procesów do zabicia
                process_list_raw=$(ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | tail -n +2)
                dialog_options=()
                while IFS= read -r line; do
                    pid=$(echo "$line" | awk '{print $1}' )
                    cpu=$(echo "$line" | awk '{print $2}' )
                    mem=$(echo "$line" | awk '{print $3}' )
                    cmd_raw=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')
                    friendly_name=$(get_friendly_process_name "$cmd_raw")
                    
                    # Format: "TAG" "ITEM"
                    dialog_options+=("$pid" "$friendly_name (CPU: $cpu%%, RAM: $mem%%)")
                done <<< "$process_list_raw"

                pid_to_kill=$(dialog --backtitle "Zabij proces" \
                                    --title "Wybierz proces do zabicia" \
                                    --menu "Wybierz proces z listy (strzałki, Enter):" 40 100 30 \
                                    "${dialog_options[@]}" 2>&1 >/dev/tty)
                
                if [ -n "$pid_to_kill" ]; then
                    dialog --title "POTWIERDZENIE" --yesno "Czy na pewno chcesz zabić proces o PID: $pid_to_kill?" 8 60
                    if [ $? -eq 0 ]; then
                        if sudo kill -9 "$pid_to_kill"; then
                            dialog --msgbox "Proces $pid_to_kill został zabity." 8 50
                        else
                            dialog --msgbox "Nie udało się zabić procesu $pid_to_kill. Sprawdź, czy PID jest poprawny i masz uprawnienia." 8 70
                        fi
                    fi
                                    fi
                                    ;;
                                3)
                                    install_package htop htop                clear
                echo "Uruchamianie htop... (naciśnij 'q', aby wyjść)"
                htop
                ;;
            0) break ;; 
esac
done
}

user_analysis() {
    (   echo "--- Użytkownicy z powłoką logowania (/bin/bash, /bin/sh itp.) ---"
        getent passwd | grep -E '/bin/(bash|sh|zsh)$' | cut -d: -f1 | sort
        echo -e "\n--- Użytkownicy w grupie 'sudo' ---"
        getent group sudo | cut -d: -f4
        echo -e "\n--- Ostatnie 20 logowań ---"
        last -n 20
    ) > /tmp/user_analysis.txt

    dialog --backtitle "Audyt i Narzędzia Systemowe" --title "Analiza Użytkowników i Dostępów" --textbox /tmp/user_analysis.txt 40 80
    rm /tmp/user_analysis.txt
}

show_network_config() {
    (
        echo "--- Konfiguracja interfejsów (ip a) ---"
        ip a
        echo -e "\n--- Aktualna konfiguracja DNS (/etc/resolv.conf) ---"
        cat /etc/resolv.conf
    ) | dialog --title "Konfiguracja Sieci i DNS" --programbox 30 90
}

change_dns() {
    DNS_CHOICE=$(dialog --backtitle "Zmiana DNS" \
        --title "Wybierz dostawcę DNS" \
        --menu "Wybierz nowe serwery DNS:" 15 60 4 \
        "1" "Google (8.8.8.8, 8.8.4.4)" \
        "2" "Cloudflare (1.1.1.1, 1.0.0.1)" \
        "3" "Quad9 (9.9.9.9, 149.112.112.112)" \
        "0" "Przywróć z kopii zapasowej" 2>&1 >/dev/tty)

    if [ -z "$DNS_CHOICE" ]; then return; fi

    if [ ! -f /etc/resolv.conf.areknet.bak ]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.areknet.bak
        dialog --title "Info" --infobox "Stworzono kopię zapasową /etc/resolv.conf.areknet.bak" 5 60
        sleep 2
    fi
    
    if command -v resolvectl &> /dev/null; then
        dialog --title "Ostrzeżenie" --msgbox "Wykryto systemd-resolved. Zmiany w /etc/resolv.conf mogą być tymczasowe. Prawidłowa, permanentna konfiguracja wymaga edycji /etc/systemd/resolved.conf." 10 70
    fi

    case "$DNS_CHOICE" in
        1)
            echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
            echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
            dialog --title "Sukces" --msgbox "Ustawiono DNS Google." 8 50
            ;;
        2)
            echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
            echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf > /dev/null
            dialog --title "Sukces" --msgbox "Ustawiono DNS Cloudflare." 8 50
            ;;
        3)
            echo "nameserver 9.9.9.9" | sudo tee /etc/resolv.conf > /dev/null
            echo "nameserver 149.112.112.112" | sudo tee -a /etc/resolv.conf > /dev/null
            dialog --title "Sukces" --msgbox "Ustawiono DNS Quad9." 8 50
            ;;
        0)
            if [ -f /etc/resolv.conf.areknet.bak ]; then
                sudo cp /etc/resolv.conf.areknet.bak /etc/resolv.conf
                dialog --title "Sukces" --msgbox "Przywrócono oryginalny plik resolv.conf." 8 60
            else
                dialog --title "Błąd" --msgbox "Nie znaleziono kopii zapasowej." 8 50
            fi
            ;;
    esac
}

network_dns_menu() {
    while true;
do
        NET_CHOICE=$(dialog --backtitle "Sieć i DNS" \
            --title "Menu Sieci i DNS" \
            --menu "Wybierz opcję:" 15 60 3 \
            "1" "Pokaż konfigurację IP i DNS" \
            "2" "Zmień serwery DNS" \
            "0" "Powrót" 2>&1 >/dev/tty)

        if [ -z "$NET_CHOICE" ]; then break; fi

        case "$NET_CHOICE" in
            1) show_network_config ;; 
            2) change_dns ;; 
            0) break ;; 
        esac
done
}

smart_cleaner() {
    cache_size=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}' )
    apt_size=$(du -sh /var/cache/apt 2>/dev/null | awk '{print $1}' )

    help_text="Linux używa wolnej pamięci RAM jako 'cache' (bufor) do przyspieszania operacji na plikach. Wysokie użycie RAM nie zawsze jest złe! Cache jest automatycznie zwalniany, gdy aplikacje go potrzebują.\n\nOpcja 'Wyczyść cache RAM' wymusza opróżnienie tego bufora. Może to tymczasowo spowolnić system, ale czasem bywa przydatne."

    options=(1 "Wyczyść cache użytkownika (~/.cache)" off
             2 "Wyczyść cache APT (apt-get clean)" off
             3 "Usuń stare, zrotowane logi (/var/log)" off
             4 "Opróżnij /tmp i /var/tmp" off
             5 "Wyczyść cache pamięci RAM (dla zaawansowanych)" off)

    choices=$(dialog --backtitle "Inteligentne Czyszczenie" \
                    --title "Wybierz operacje do wykonania" \
                    --checklist "$help_text\n\nZaznacz spacją, co chcesz wyczyścić.\nMożliwe do zwolnienia (szacunkowo): ~/.cache ($cache_size), /var/cache/apt ($apt_size)" 22 85 5 \
                    "${options[@]}" 2>&1 >/dev/tty)

    if [ -z "$choices" ]; then
        dialog --title "Anulowano" --msgbox "Nie wykonano żadnych operacji." 8 50
        return
    fi
    
    ( 
    for choice in $choices; do
        case $choice in
            1)
                echo "Czyszczenie cache użytkownika (~/.cache)..."
                rm -rf ~/.cache/*
                echo "Cache użytkownika wyczyszczone."
                ;;
            2)
                echo "Czyszczenie cache APT..."
                sudo apt-get clean
                echo "Cache APT wyczyszczone."
                ;;
            3)
                echo "Usuwanie starych logów..."
                sudo find /var/log -name "*.gz" -o -name "*.1" -delete
                echo "Stare logi usunięte."
                ;;
            4)
                echo "Czyszczenie /tmp i /var/tmp..."
                sudo rm -rf /tmp/* /var/tmp/*
                echo "/tmp i /var/tmp wyczyszczone."
                ;;
            5)
                echo "Synchronizacja buforów i czyszczenie cache RAM..."
                sudo sync
                echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
                echo "Cache RAM wyczyszczone."
                ;;
        esac
    done
    ) | dialog --title "Postęp operacji" --programbox 20 70

    dialog --title "Zakończono" --msgbox "Wybrane operacje czyszczenia zostały zakończone." 8 60
}

# Function to kill a process by PID
kill_process_by_pid() {
    read -p "Enter the PID of the process to kill: " pid_to_kill
    if [[ -z "$pid_to_kill" ]]; then
        echo "PID cannot be empty."
        return
    fi

    if ps -p "$pid_to_kill" > /dev/null; then
        read -p "Are you sure you want to kill process with PID $pid_to_kill? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            sudo kill -9 "$pid_to_kill"
            if [[ $? -eq 0 ]]; then
                echo "Process $pid_to_kill killed successfully."
            else
                echo "Failed to kill process $pid_to_kill."
            fi
        else
            echo "Operation cancelled."
        fi
    else
        echo "No process found with PID $pid_to_kill."
    fi
    press_enter_to_continue
}

# Function to kill a network connection by selecting from netstat output
kill_network_connection() {
    echo "Listing active network connections (TCP and UDP, listening and established):"
    echo "-----------------------------------------------------------------------"
    # Use netstat to list connections, filter for TCP/UDP, listening/established, and show PID/program name
    # -t: TCP, -u: UDP, -l: listening, -n: numeric addresses, -p: show PID/program name
    # We need sudo for -p to show all PIDs
    NETSTAT_OUTPUT=$(sudo netstat -tulnp 2>/dev/null | grep -E '^(tcp|udp)' | awk '{$1=$1;print}')

    if [[ -z "$NETSTAT_OUTPUT" ]]; then
        echo "No active network connections found."
        press_enter_to_continue
        return
    fi

    declare -A connections_map
    local i=1
    echo "Nr. Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name"
    echo "--------------------------------------------------------------------------------------------------"
    while IFS= read -r line; do
        # Extract PID from the last column, which might be "PID/ProgramName"
        # Example: tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1234/sshd
        # The PID is before the first '/' in the last field
        local pid_program=$(echo "$line" | awk '{print $NF}')
        local pid=$(echo "$pid_program" | cut -d'/' -f1)

        if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
            echo "$i. $line"
            connections_map["$i"]="$pid"
            i=$((i+1))
        fi
    done <<< "$NETSTAT_OUTPUT"
    echo "--------------------------------------------------------------------------------------------------"

    if [[ ${#connections_map[@]} -eq 0 ]]; then
        echo "No connections with identifiable PIDs found."
        press_enter_to_continue
        return
    fi

    read -p "Enter the number of the connection to terminate (or 'q' to quit): " selection

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        echo "Operation cancelled."
        press_enter_to_continue
        return
    fi

    if [[ -n "${connections_map[$selection]}" ]]; then
        local pid_to_kill="${connections_map[$selection]}"
        local connection_details=$(echo "$NETSTAT_OUTPUT" | grep -E " $(echo "$pid_to_kill" | cut -d'/' -f1)/" | head -n 1) # Get the full line for confirmation

        echo "You selected connection: $connection_details"
        read -p "Are you sure you want to kill the process (PID: $pid_to_kill) associated with this connection? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            sudo kill -9 "$pid_to_kill"
            if [[ $? -eq 0 ]]; then
                echo "Process $pid_to_kill killed successfully, terminating the connection."
            else
                echo "Failed to kill process $pid_to_kill."
            fi
        else
            echo "Operation cancelled."
        fi
    else
        echo "Invalid selection. Please enter a valid number from the list."
    fi
    press_enter_to_continue
}


# --- GŁÓWNA PĘTLA MENU ---

while true;
do
    choice=$(dialog --clear --backtitle "Audyt i Narzędzia Systemowe" \
                    --title "MENU NARZĘDZI" \
                    --menu "Wybierz opcję:" 20 70 14 \
                    "1" "🌡️ Pulpit Zdrowia Systemu (NOWOŚĆ)" \
                    "2" "🔌 Połączenia sieciowe (ss, netstat)" \
                    "3" "📡 Skanowanie portów (nmap)" \
                    "4" "📜 Przegląd logów systemowych (journalctl)" \
                    "5" "🔒 Bezpieczeństwo (fail2ban, rkhunter)" \
                    "6" "💾 Prosty backup" \
                    "7" "💻 Informacje o systemie" \
                    "8" "🔧 Diagnostyka sprzętu (sensors, smartctl)" \
                    "9" "⚙️ Zarządzanie usługami systemd" \
                    "10" "🕵️ Analiza Użytkowników i Dostępów" \
                    "11" "❌ Zabij połączenie sieciowe" \
                    "11" "🌐 Sieć i DNS" \
                    "12" "🧹 Inteligentne Czyszczenie" \
                    "0" "Powrót do menu głównego" 2>&1 >/dev/tty)

    if [ -z "$choice" ]; then
        break
    fi

    case "$choice" in
        1) system_health_dashboard ;; 
        2) (echo "--- Aktywne porty nasłuchujące ---"; ss -tuln; echo -e "\n--- Procesy nasłuchujące ---"; sudo netstat -tulpn) | dialog --title "Połączenia sieciowe" --programbox 30 80 ;; 
        3) install_package nmap nmap; target=$(dialog --inputbox "Podaj IP/domenę:" 8 60 "localhost" 2>&1 >/dev/tty); if [ -n "$target" ]; then sudo nmap -F "$target" | dialog --title "Wynik Nmap" --programbox 30 90; fi ;; 
        4) sudo journalctl -n 100 --no-pager --reverse | dialog --title "Logi systemowe" --programbox 40 100 ;; 
        5) (echo "--- Status fail2ban ---"; sudo systemctl status fail2ban --no-pager; echo -e "\n--- Skanowanie rkhunter ---"; install_package rkhunter rkhunter; sudo rkhunter --check --skip-keypress) | dialog --title "Narzędzia bezpieczeństwa" --programbox 40 100 ;; 
        6) src=$(dialog --inputbox "Katalog źródłowy:" 8 60 "$HOME/" 2>&1 >/dev/tty); if [ -z "$src" ]; then continue; fi; dest=$(dialog --inputbox "Katalog docelowy:" 8 60 "$HOME/" 2>&1 >/dev/tty); if [ -z "$dest" ]; then continue; fi; if [ -d "$src" ]; then mkdir -p "$dest"; backup_file="$dest/backup-$(date +%Y%m%d_%H%M%S).tar.gz"; sudo tar -czvf "$backup_file" "$src" 2>&1 | dialog --msgbox "Błąd" 10 70; dialog --msgbox "Backup wykonany!\nPlik: $backup_file" 10 70; else dialog --msgbox "Błąd: Katalog źródłowy nie istnieje." 8 50; fi ;; 
        7) (echo "--- Dystrybucja ---"; lsb_release -a; echo -e "\n--- Jądro i uptime ---"; echo "Jądro: $(uname -r)"; echo "Uptime: $(uptime -p)"; echo -e "\n--- Dysk ---"; df -h | grep -vE 'tmpfs|udev') | dialog --title "Informacje o systemie" --programbox 30 80 ;; 
        8) install_package sensors lm-sensors; install_package smartctl smartmontools; (echo "--- Temperatury ---" && sensors) > /tmp/hwdiag.txt; dev_list=$(ls /dev/sd* | awk -F'/' '{print $3}' | paste -s -d ' '); dev=$(dialog --inputbox "Wykryte dyski: $dev_list\n\nPodaj urządzenie (np. sda):" 12 70 2>&1 >/dev/tty); if [ -n "$dev" ]; then echo -e "\n--- S.M.A.R.T. dla /dev/$dev ---" >> /tmp/hwdiag.txt; sudo smartctl -a "/dev/$dev" >> /tmp/hwdiag.txt; fi; dialog --title "Diagnostyka sprzętu" --textbox /tmp/hwdiag.txt 40 100; rm /tmp/hwdiag.txt ;; 
        9) manage_systemd_services ;; 
        10) user_analysis ;; 
        11) kill_network_connection ;; 
        11) network_dns_menu ;; 
        12) smart_cleaner ;; 
        0) break ;; 
    esac
done

clear