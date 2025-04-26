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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            elif [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                error_exit "Неизвестный аргумент: $1"
            fi
            shift
            ;;
    esac
done

[[ -z "$input_dir" || -z "$output_dir" ]] && error_exit "Использование: $0 [--max_depth N] <входная_директория> <выходная_директория>"

[[ ! -d "$input_dir" ]] && error_exit "Входная директория не существует: $input_dir"

mkdir -p "$output_dir" || error_exit "Не удалось создать выходную директорию: $output_dir"

declare -A file_count

find_command=("find" "$input_dir" "-type" "f")
[[ -n "$max_depth" ]] && find_command+=("-maxdepth" "$max_depth")

"${find_command[@]}" -print0 | while IFS= read -r -d '' file; do
    base_name=$(basename -- "$file")
    extension="${base_name##*.}"
    name_part="${base_name%.*}"

    if [[ -n "${file_count[$base_name]}" ]]; then
        new_name="${name_part}_${file_count[$base_name]}.${extension}"
        file_count[$base_name]=$((file_count[$base_name] + 1))
    else
        new_name="$base_name"
        file_count[$base_name]=1
    fi

    if ! cp --preserve -- "$file" "$output_dir/$new_name"; then
        echo "Предупреждение: не удалось скопировать $file" >&2
    fi
done

echo "Успешно скопировано файлов: ${#file_count[@]}"

