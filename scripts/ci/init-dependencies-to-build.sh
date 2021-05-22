#!/usr/bin/env bash

set -eo pipefail

carthage bootstrap --platform ios --cache-builds
