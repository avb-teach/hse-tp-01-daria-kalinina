#!/bin/bash

error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}

if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    error_exit "Требуется Bash 4.0 или новее. Текущая версия: ${BASH_VERSION}"
fi


max_depth=""
input_dir=""
output_dir=""

while (( $# > 0 )); do
    case "$1" in
        --max_depth)
            if [[ ! "$2" =~ ^[0-9]+$ ]]; then
                echo "Ошибка: Аргумент --max_depth должен быть числом" >&2
                exit 1
            fi
            max_depth="$2"
            shift 2
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            elif [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                echo "Ошибка: Неизвестный аргумент: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Использование: $0 [--max_depth N] <входная_директория> <выходная_директория>" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Ошибка: Входная директория не существует: $input_dir" >&2
    exit 1
fi

mkdir -p "$output_dir" || {
    echo "Ошибка: Не удалось создать выходную директорию: $output_dir" >&2
    exit 1
}

declare -A file_count
copied_files=0

while IFS= read -r -d '' file; do
    base_name=$(basename -- "$file")
    extension="${base_name##*.}"
    name_part="${base_name%.*}"
    
    if [[ ${file_count[$base_name]+_} ]]; then
        new_name="${name_part}_$((file_count[$base_name]++)).${extension}"
    else
        new_name="$base_name"
        file_count[$base_name]=1
    fi

    if cp --preserve -- "$file" "$output_dir/$new_name"; then
        ((copied_files++))
    else
        echo "Предупреждение: не удалось скопировать $file" >&2
    fi
done < <(find "$input_dir" -type f $([[ -n "$max_depth" ]] && echo "-maxdepth $max_depth") -print0 | sort -z)

exit 0
