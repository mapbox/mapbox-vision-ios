#!/usr/bin/env bash

set -e

cd "scripts"

dev_input_file="dev-carthage-input.xcfilelist"

if [[ -f "${dev_input_file}" ]]; then
	source "prepare_dev.sh"
	export SCRIPT_INPUT_FILE_0="${dev_input_file}"
fi

source "list_to_files.sh"
