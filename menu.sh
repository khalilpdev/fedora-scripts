#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RST='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAG='\033[0;35m'

get_modules() {
    local modules=()
    while IFS= read -r dir; do
        local name
        name=$(basename "$dir")
        [[ "$name" == ".git" || "$dir" == "$BASE_DIR" ]] && continue
        if find "$dir" -maxdepth 1 -name '*.sh' -print -quit | grep -q .; then
            modules+=("$name")
        fi
    done < <(find "$BASE_DIR" -maxdepth 1 -type d | sort)
    echo "${modules[@]}"
}

get_scripts() {
    local module="$1"
    local scripts=()
    while IFS= read -r script; do
        scripts+=("$(basename "$script")")
    done < <(find "$BASE_DIR/$module" -maxdepth 1 -name '*.sh' | sort)
    echo "${scripts[@]}"
}

get_description() {
    local script="$1"
    sed -n '/^#!/{n;/^#/{s/^# *//p;q}}' "$script"
}

run_script() {
    local script="$1"
    local name
    name=$(basename "$script")

    while true; do
        clear
        echo -e "${BOLD}${BLUE}=========================================${RST}"
        echo -e "${BOLD} ${name%.sh}${RST}"
        echo -e "${BOLD}${BLUE}=========================================${RST}"
        echo ""

        local desc
        desc=$(get_description "$script")
        if [ -n "$desc" ]; then
            echo -e " ${desc}"
            echo ""
        fi

        local lines
        lines=$(wc -l < "$script")
        local preview=20
        [[ $lines -lt $preview ]] && preview=$lines
        echo -e "${YELLOW}--- preview (first $preview/$lines lines) ---${RST}"
        sed -n "1,${preview}p" "$script"
        echo -e "${YELLOW}---------------------------------------------${RST}"
        echo ""
        echo -e "${GREEN}[r]${RST} Run this script"
        echo -e "${YELLOW}[p]${RST} Print full script"
        echo -e "[b] Back to module"
        echo ""
        read -p "Choice: " action

        case "$action" in
            r|R)
                echo ""
                echo -e "${BOLD}Executing ${name}...${RST}"
                echo -e "${BLUE}=========================================${RST}"
                bash "$script"
                local rc=$?
                echo ""
                echo -e "${BLUE}=========================================${RST}"
                echo -e "${BOLD}Script finished (exit code: $rc)${RST}"
                read -p "Press Enter to continue..."
                return
                ;;
            p|P)
                less "$script"
                ;;
            b|B)
                return
                ;;
        esac
    done
}

module_menu() {
    local module="$1"

    while true; do
        clear
        local scripts=($(get_scripts "$module"))
        echo -e "${BOLD}${BLUE}=========================================${RST}"
        echo -e "${BOLD} Module: ${CYAN}$module${RST}"
        echo -e "${BOLD}${BLUE}=========================================${RST}"
        echo ""

        if [ ${#scripts[@]} -eq 0 ]; then
            echo -e "${YELLOW}No scripts found in this module.${RST}"
            read -p "Press Enter to go back..."
            return
        fi

        for i in "${!scripts[@]}"; do
            local desc
            desc=$(get_description "$BASE_DIR/$module/${scripts[$i]}")
            local num=$((i+1))
            printf "  ${GREEN}%2d)${RST} ${BOLD}%s${RST}\n" "$num" "${scripts[$i]%.sh}"
            if [ -n "$desc" ]; then
                printf "       %s\n" "$desc"
            fi
        done
        echo ""
        echo -e "  ${GREEN}a)${RST} Run all scripts sequentially"
        echo -e "  [b] Back    [q] Quit"
        echo ""
        read -p "Select: " choice

        case "$choice" in
            q|Q) echo "Bye!"; exit 0 ;;
            b|B) return ;;
            a|A)
                for script in "${scripts[@]}"; do
                    echo ""
                    echo -e "${BOLD}${BLUE}--- Running ${script} ---${RST}"
                    bash "$BASE_DIR/$module/$script"
                    echo -e "${BOLD}${BLUE}--- Done ---${RST}"
                done
                read -p "Press Enter to continue..."
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#scripts[@]}" ]; then
                    run_script "$BASE_DIR/$module/${scripts[$((choice-1))]}"
                else
                    read -p "Invalid option. Press Enter..."
                fi
                ;;
        esac
    done
}

cleanup() {
    echo ""
    echo -e "${YELLOW}Bye!${RST}"
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    clear
    modules=($(get_modules))

    echo -e "${BOLD}${BLUE}=========================================${RST}"
    echo -e "${BOLD}        Fedora Scripts - Main Menu${RST}"
    echo -e "${BOLD}${BLUE}=========================================${RST}"
    echo ""

    if [ ${#modules[@]} -eq 0 ]; then
        echo -e "${YELLOW}No modules found (no subdirectories with .sh files).${RST}"
        echo "Create module directories with scripts inside."
        read -p "Press Enter to quit..."
        exit 1
    fi

    echo -e "${BOLD}Modules:${RST}"
    for i in "${!modules[@]}"; do
        count=$(find "$BASE_DIR/${modules[$i]}" -maxdepth 1 -name '*.sh' | wc -l)
        num=$((i+1))
        printf "  ${GREEN}%2d)${RST} ${BOLD}%-12s${RST} ${CYAN}[%d scripts]${RST}\n" "$num" "${modules[$i]}" "$count"
    done
    echo ""
    echo -e "  [q] Quit"
    echo ""
    read -p "Select a module: " choice

    case "$choice" in
        q|Q) echo "Bye!"; exit 0 ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#modules[@]}" ]; then
                module_menu "${modules[$((choice-1))]}"
            else
                read -p "Invalid option. Press Enter..."
            fi
            ;;
    esac
done
