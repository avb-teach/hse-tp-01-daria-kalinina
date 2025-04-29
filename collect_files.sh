#!/usr/bin/env bash

error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}

max_depth=""
input_dir=""
output_dir=""

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
            if [[ -z "$input_dir" ]]; then
                input_dir="${1%/}"
            elif [[ -z "$output_dir" ]]; then
                output_dir="${1%/}"
            else
                usage
            fi
            shift
            ;;
    esac
done

[[ -z "$input_dir" || -z "$output_dir" ]] && usage
[[ ! -d "$input_dir" ]] && error_exit "Входная директория не существует: $input_dir"


if [[ -n "$max_depth" ]]; then
    if ! [[ "$max_depth" =~ ^[1-9][0-9]*$ ]]; then
        error_exit "Неверное значение max_depth: $max_depth"
    fi
fi


mkdir -p "$output_dir" || error_exit "Нельзя создать выходную директорию: $output_dir"


while IFS= read -r -d '' file; do
    rel="${file#$input_dir/}"
    IFS='/' read -r -a parts <<< "$rel"
    L=${#parts[@]}

    if [[ -n "$max_depth" && $L -gt $max_depth ]]; then
        start=$((L - max_depth))
    else
        start=0
    fi

    ost=( "${i[@]:start}" )
    f="${ost[-1]}"

    if (( ${#ost[@]} > 1 )); then
        x=( "${ost[@]:0:${#ost[@]}-1}" )
        help_dir="$output_dir/$(printf "%s/" "${x[@]}")"
    else
        help_dir="$output_dir"
    fi

    mkdir -p "$target_dir" || {
        echo "Нельзя создать каталог $help_dir" >&2
        continue
    }

    dist="$help_dir/$f"
    if [[ -e "$dist" ]]; then
        osn="${f%.*}"
        ext="${f##*.}"
        k=1
        while [[ -e "$help_dir/${osn}_$k.$ext" ]]; do
            ((count++))
        done
        dist="$help_dir/${osn}_$k.$ext"
    fi

    cp --preserve "$file" "$dist" || {
        echo "Предупреждение: не удалось скопировать $file" >&2
    }

done < <(find "$input_dir" -type f -print0)
