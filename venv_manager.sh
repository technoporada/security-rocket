#!/bin/bash
# venv_manager.sh
# Prosty helper do zarządzania wirtualnymi środowiskami Python

VENV_DIR="$HOME/.local/venvs"

function create_venv() {
    local name=$1

    local path="$VENV_DIR/$name"
    if [ -d "$path" ]; then
        echo "🔹 Środowisko $name już istnieje w $path"
    else
        echo "🔹 Tworzę środowisko $name w $path"
        python3 -m venv "$path"
        echo "🔹 Środowisko utworzone."
    fi

}

function activate_venv() {

    local name=$1
    local path="$VENV_DIR/$name"

    if [ -d "$path" ]; then

        echo "🔹 Aktywuję środowisko $name"

        source "$path/bin/activate"

    else

        echo "❌ Środowisko $name nie istnieje! Najpierw stwórz je poleceniem create_venv <nazwa>"
    fi
}

function install_package() {
    local name=$1
    local package=$2
    create_venv "$name"
    activate_venv "$name"
    echo "🔹 Instaluję $package w środowisku $name"
    pip install --upgrade pip
    pip install "$package"

    deactivate
    echo "✅ $package zainstalowane w $name"
}


function help() {
    echo "Użycie:"
    echo "  create_venv <nazwa>       - Tworzy nowe środowisko"
    echo "  activate_venv <nazwa>     - Aktywuje środowisko"

    echo "  install_package <nazwa> <pakiet> - Tworzy/aktywuje środowisko i instaluje pakiet"
}


case $1 in

    create_venv)
        create_venv $2
        ;;

    activate_venv)

        activate_venv $2

        ;;
    install_package)
        install_package $2 $3
        ;;
    *)
        help
        ;;
esac

