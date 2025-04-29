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

mkdir -p "$vihod" || error_exit "Нельзя создать выходную директорию: $vihod"

while IFS= read -r -d '' file; do
    rel="${file#$vhod/}"
    IFS='/' read -r -a parts <<< "$rel"
    L=${#parts[@]}

    if [[ -n "$max_depth" && $L -gt $max_depth ]]; then
        nach=$((L - max_depth))
    else
        nach=0
    fi

    ost=( "${parts[@]:nach}" )
    f="${ost[-1]}"

    if (( ${#ost[@]} > 1 )); then
        x=( "${ost[@]:0:${#ost[@]}-1}" )
        help_dir="$vihod/$(printf "%s/" "${x[@]}")"
    else
        help_dir="$vihod"
    fi

    mkdir -p "$help_dir" || {
        echo "Нельзя создать каталог $help_dir" >&2
        continue
    }

    dist="$help_dir/$f"
    if [[ -e "$dist" ]]; then
        osn="${f%.*}"
        ext="${f##*.}"
        k=1
        while [[ -e "$help_dir/${osn}_$k.$ext" ]]; do
            ((k++))
        done
        dist="$help_dir/${osn}_$k.$ext"
    fi

    cp --preserve "$file" "$dist" || {
        echo "Предупреждение: не удалось скопировать $file" >&2
    }

done < <(find "$vhod" -type f -print0)
