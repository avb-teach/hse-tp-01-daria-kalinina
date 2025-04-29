#!/usr/bin/env bash

error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}

max_depth=""
vhod=""
vihod=""

usage() {
    echo "Использование: $0 [--max_depth N] <входная_директория> <выходная_директория>" >&2
    exit 1
}

while (( $# )); do
    case "$1" in
        --max_depth)
            shift
            [[ $# -gt 0 ]] || usage
            max_depth="$1"
            shift
            ;;
        -*)
            error_exit "Неизвестный параметр: $1"
            ;;
        *)
            if [[ -z "$vhod" ]]; then
                vhod="${1%/}"
            elif [[ -z "$vihod" ]]; then
                vihod="${1%/}"
            else
                usage
            fi
            shift
            ;;
    esac
done

[[ -z "$vhod" || -z "$vihod" ]] && usage
[[ ! -d "$vhod" ]] && error_exit "Входная директория не существует: $vhod"

if [[ -n "$max_depth" ]]; then
    if ! [[ "$max_depth" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "Неверное значение max_depth: $max_depth"
    fi
fi

mkdir -p "$vihod" || error_exit "Не удалось создать выходную директорию: $vihod"

find "$vhod" -type f -print0 | while IFS = read -r -d '' file; do
    rez="${file#$vhod/}"
    if [[ -n "$max_depth" ]]; then
        rez=$(dirname "$rez" | cut -d '/' -f$((${#rel//\//}+1 - max_depth))-)
    fi
    helpd="$vihod/$(dirname "$rez")"
    mkdir -p "$helpd" || {
        echo "Нельзя создать каталог $helpd" >&2
        continue
    }
    f=$(basename "$rez")
    dist="$helpd/$f"

    if [[ -e "$dist" ]]; then
        osn="${f%.*}"
        con="${f##*.}"
        k=1
        while [[ -e "$helpd/${osn}_$k.$con" ]]; do
            ((k++))
        done
        dist="$helpd/${osn}_$k.$con"
    fi
    cp --preserve "$file" "$dist" || {
        echo "Нельзя скопировать $file" >&2
    }
done
