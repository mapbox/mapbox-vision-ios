#!/usr/bin/env bash

set -eo pipefail

if [ -z `which jazzy` ]; then
    echo "Installing jazzy…"
    gem install jazzy
    if [ -z `which jazzy` ]; then
        echo "Unable to install jazzy."
        exit 1
    fi
fi

WORKSPACE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
cd "${WORKSPACE_DIR}"

jazzy --config "MapboxVision/.jazzy.yaml"
jazzy --config "MapboxVisionAR/.jazzy.yaml"
jazzy --config "MapboxVisionSafety/.jazzy.yaml"
