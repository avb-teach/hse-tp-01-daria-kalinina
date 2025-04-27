#!/usr/bin/env bash

error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}


if (( BASH_VERSINFO[0] < 4 )); then
    error_exit "Требуется Bash 4.0 или новее. Текущая версия: ${BASH_VERSION}"
fi

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


mkdir -p "$output_dir" || error_exit "Не удалось создать выходную директорию: $output_dir"


while IFS= read -r -d '' file; do
    rel="${file#$input_dir/}"
    IFS='/' read -r -a parts <<< "$rel"
    L=${#parts[@]}

    if [[ -n "$max_depth" && $L -gt $max_depth ]]; then
        start=$((L - max_depth))
    else
        start=0
    fi

    tail_parts=( "${parts[@]:start}" )
    fname="${tail_parts[-1]}"

    if (( ${#tail_parts[@]} > 1 )); then
        subdirs=( "${tail_parts[@]:0:${#tail_parts[@]}-1}" )
        target_dir="$output_dir/$(printf "%s/" "${subdirs[@]}")"
    else
        target_dir="$output_dir"
    fi

    mkdir -p "$target_dir" || {
        echo "Предупреждение: не удалось создать каталог $target_dir" >&2
        continue
    }

    dest="$target_dir/$fname"
    if [[ -e "$dest" ]]; then
        base="${fname%.*}"
        ext="${fname##*.}"
        count=1
        while [[ -e "$target_dir/${base}_$count.$ext" ]]; do
            ((count++))
        done
        dest="$target_dir/${base}_$count.$ext"
    fi

    cp --preserve "$file" "$dest" || {
        echo "Предупреждение: не удалось скопировать $file" >&2
    }

done < <(find "$input_dir" -type f -print0)
