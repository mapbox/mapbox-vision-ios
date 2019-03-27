#!/usr/bin/env bash

set -e

input_file="carthage-input.xcfilelist"
dev_input_file="dev-${input_file}"

if [[ ! -f "${input_file}" ]]; then
	echo "Error: ${PWD}/${input_file} does not exist."
	exit 1
fi

cp "${input_file}" "${dev_input_file}"
sed -i '' -e 's/.*\(MapboxVision.*\)/$(BUILT_PRODUCTS_DIR)\/\1/g' "${dev_input_file}"
