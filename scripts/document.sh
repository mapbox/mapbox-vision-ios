#!/usr/bin/env bash

set -euo pipefail

if ! hash jazzy 2>/dev/null; then
    echo "Installing jazzy..."
    gem install jazzy
fi

CONFIG=".jazzy.yaml"
WORKSPACE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
cd "${WORKSPACE_DIR}"

jazzy --config "MapboxVision/${CONFIG}"
jazzy --config "MapboxVisionAR/${CONFIG}"
jazzy --config "MapboxVisionSafety/${CONFIG}"
