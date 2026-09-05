# Security Rocket 🚀

Hardening Linuxa w jednym miejscu — zbiór bezpiecznych skryptów bash do twardnienia systemu (SSH, UFW, AppArmor, sysctl, AIDE) z mechanizmami bezpieczeństwa: preflight, backup, blokada lockoutu SSH i rollback.

Budowane lokalnie, offline-first, bez zależności (czysty bash + standardowe narzędzia).

## Skrypty

| Skrypt | Rola |
|--------|------|
| `oneclick_harden.sh` | **One-click hardening**: SSH→klucze (blokada lockoutu), AppArmor, sysctl, AIDE, UFW minimal. Robi backup przed zmianami, ma bezpiecznik przed wyłączeniem haseł bez kluczy. |
| `preflight_check.sh` | Weryfikacja przed hardeningiem: klucz SSH, tryb SSH, backup konfiguracji, snapshot `ss`/`ufw`. |
| `apply_and_verify.sh` | Uruchamia wybrany tryb (`oneclick`/`hardcore`), testuje, analizuje i robi rollback przy krytycznym błędzie. |
| `ufw_manager.sh` | Scentralizowane profile UFW: `standard` / `aggressive` (z domyślnym blokowaniem ruchu wychodzącego). |
| `security_report.sh` | Raport bezpieczeństwa: porty, SSH, UFW, AppArmor, AIDE. |
| `system_check.sh` | Ogólny przegląd systemu: dysk, pamięć, failed services, błędy w logach, aktualizacje. |
| `varenet_system_utils.sh` | Narzędzia systemowe w menu `dialog` (procesy, sieć, użytkownicy). |
| `varenet_firewall_menu.sh` | Menu firewall / UFW. |
| `varenet_control.sh` | Kontrola usług sieciowych (start/stop/status). |
| `reinstall_core_components.sh` | Przeinstalowanie komponentów core. |
| `venv_manager.sh` | Zarządzanie środowiskami venv. |

## Użycie

```bash
# 1) Weryfikacja przed zmianami
./preflight_check.sh

# 2) One-click hardening (ma wbudowany bezpiecznik przed lockoutem SSH)
./oneclick_harden.sh

# lub przez integrację z testami i rollbackiem
./apply_and_verify.sh oneclick

# 3) Raport po zmianach
./security_report.sh
```

> ⚠️ **Danger zone**: skrypty modyfikują konfigurację SSH (`PasswordAuthentication no`, zakaz roota) i UFW.
> Przed uruchomieniem uruchom `preflight_check.sh` i miej fizyczny dostęp do maszyny.
> `oneclick_harden.sh` **abortuje** jeśli nie wykryje klucza w `authorized_keys` — nie zablokujesz się trwale przez przypadek.

## Wymagania

- Linux z `sudo`, `systemd`, `ufw`, `dialog` (opcjonalnie),
- `ssh` z kluczem publicznym w `~/.ssh/authorized_keys`,
- zero bibliotek Pythona, zero API — czysty bash.

## Bezpieczeństwo

- Backup plików konfiguracyjnych przed każdą modyfikacją (do `~/.local/share/hardening_runs/`),
- Bezpiecznik `oneclick_harden.sh` blokuje wyłączenie haseł, gdy brak kluczy SSH,
- Logi każdego uruchomienia z timestampem (`hardening_runs/apply_*.log`),
- Metadata: `ulimit`, `set -euo pipefail`.