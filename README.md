# Security Rocket 🚀

Hardening Linuxa w jednym miejscu — zbiór bezpiecznych skryptów bash do
twardzenia systemu (SSH, UFW, AppArmor, sysctl, AIDE) z mechanizmami
bezpieczeństwa: preflight, backup, blokada lockoutu SSH i rollback.

Budowane lokalnie, offline-first, bez zależności (czysty bash + standardowe
narzędzia).

## Uwaga przed uruchomieniem

To skrypty **`sudo`-owe, które zmieniają konfigurację systemu.** SSH, firewall
i AppArmor. Uruchamiaj na maszynie, do której masz dostęp z innego miejsca —
SSH, konsola providera albo fizyczny dostęp do klawiatury. Zmiany w `/etc/ssh`
i reguły UFW potrafią odciąć Cię od systemu.

Profil `aggressive` w `ufw_manager.sh` ustawia `default deny outgoing`, czyli
**system przestaje widzieć internet** (działa tylko DNS). Na maszynie zdalnej
to ryzyko utraty łączności. Domyślny i polecany jest `standard`.

## Skrypty

| Skrypt | Rola |
|--------|------|
| `oneclick_harden.sh` | **One-click hardening**: SSH→klucze (blokada lockoutu), AppArmor, sysctl, AIDE, UFW w profilu `standard`. Robi backup przed zmianami i ma bezpiecznik — nie wyłącza haseł bez kluczy SSH. |
| `preflight_check.sh` | Weryfikacja przed hardeningiem: klucz SSH, tryb SSH, backup konfiguracji, snapshot `ss`/`ufw`. |
| `apply_and_verify.sh` | Uruchamia hardening, testuje, analizuje wynik i robi rollback przy krytycznym błędzie (brak SSH). |
| `ufw_manager.sh` | Profile UFW: `standard` (blokuje wchodzące, zostawia wychodzące) / `aggressive` (`deny` na obu kierunkach). Wymaga `--yes`, robi `ufw --force reset` na wejściu. |
| `security_report.sh` | Raport bezpieczeństwa: porty, SSH, UFW, AppArmor, AIDE. |
| `system_check.sh` | Ogólny przegląd systemu: dysk, pamięć, failed services, błędy w logach, aktualizacje. |
| `areknet_system_utils.sh` | Narzędzia systemowe w menu `dialog` (procesy, sieć, użytkownicy). |
| `areknet_firewall_menu.sh` | Menu firewall / UFW. |
| `areknet_control.sh` | Kontrola usług sieciowych (start/stop/status) + wejście do hardeningu. |
| `venv_manager.sh` | Zarządzanie środowiskiem wirtualnym pomocniczych skryptów. |
| `reinstall_core_components.sh` | Przeinstalowanie komponentów core. |

## Jak uruchomić

```bash
./preflight_check.sh          # najpierw zobacz co się stanie
sudo ./apply_and_verify.sh oneclick
```

`apply_and_verify.sh` robi sam: preflight → hardening → testy → rollback przy
braku SSH. Logi w `~/.local/share/hardening_runs/`.

Sam firewall, bez resty:

```bash
sudo ./ufw_manager.sh standard
```

## Uwagi

- `areknet_*` to skrypty, które odwołują się do siebie po nazwie — uruchamiaj
  je z katalogu repo, nie z innego miejsca.
- Skrypty zakładają `bash`, `ufw`, `ss`, `curl`, `systemctl`. Brak któregokolwiek
  z nich zatrzymuje skrypt z komunikatem, a nie po cichu.
- Logi i backupy: `~/.local/share/hardening_runs/`. Rollback przywraca
  `sshd_config`, `sysctl` i reguły UFW z backupów z tej samej sesji.
