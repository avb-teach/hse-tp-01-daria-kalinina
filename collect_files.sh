#!/usr/bin/env bash

max_depth=""
vhod=""
vihod=""

usage() {
    echo "Использование: $0 [--max_depth N] <входная_директория> <выходная_директория>" >&2
    exit 1
}

while getopts ":m:" opt; do
    case "$opt" in
        m)
            max_depth="$OPTARG"
            ;;
        \?)
            usage
            ;;
        :)
            usage
            ;;
    esac
done

shift $((OPTIND - 1))
vhod="${1%/}"
vihod="${2%/}"
[[ -n "$vhod" && -n "$vihod" ]] || usage

[[ -z "$vhod" || -z "$vihod" ]] && usage
[[ ! -d "$vhod" ]] && { echo "Входная директория не существует: $vhod" >&2; exit 1; }
if [[ -n "$max_depth" && ! "$max_depth" =~ ^[1-9][0-9]*$ ]]; then
     echo "Неверное значение max_depth: $max_depth" >&2
     exit 1
fi

mkdir -p "$vihod"

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

    mkdir -p "$help_dir"

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

    cp --preserve "$file" "$dist"
done < <(find "$vhod" -type f -print0)
