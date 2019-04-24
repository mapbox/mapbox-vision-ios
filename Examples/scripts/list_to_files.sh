#!/usr/bin/env bash
# reads input/output paths from file and exports it to expected constants

function list_to_files {
    prefix="${1}"
    list_file="${prefix}_0"

    echo "${list_file} : ${!list_file}"

    IFS=$'\r\n' GLOBIGNORE='*' files=($(eval cat \$${list_file}))

    eval "export ${prefix}_COUNT=${#files[@]}"
    eval "echo ${prefix}_COUNT : \${${prefix}_COUNT}"

    for index in ${!files[@]}; do
        file="$(echo ${files[$index]} | sed -e 's/(\([^)]*\))/{\1}/g')"
        key="${prefix}_${index}"

        eval "export ${key}=${file}"
        if [[ -L "${!key}" ]]; then
            eval "export ${key}=$(readlink ${!key})"
        fi

        echo "${key} : ${!key}"
    done    
}

list_to_files "SCRIPT_INPUT_FILE"
list_to_files "SCRIPT_OUTPUT_FILE"
