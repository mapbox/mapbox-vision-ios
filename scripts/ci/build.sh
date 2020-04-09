#!/usr/bin/env bash

# Uncomment to debug
#DST='platform=iOS Simulator,OS=13.2,name=iPhone 11'
#IOS_BUILD_TYPE='Debug'
#IOS_BUILD_DIR='build'

set -eo pipefail

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${dir}/../utils/errors.sh"

#######################
#   Helper functions  #
#######################

function buildProject() {
    local -r SCHEME_TO_BUILD="${1}"

    xcodebuild \
      -project "MapboxVision.xcodeproj" \
      -scheme "${SCHEME_TO_BUILD}" \
      -destination "${DST}" \
      -configuration "${IOS_BUILD_TYPE}" \
      build \
      CONFIGURATION_BUILD_DIR="${IOS_BUILD_DIR}/" | xcpretty
}

function testProject() {
    local -r SCHEME_TO_TEST="${1}"

    xcodebuild test \
      -project "MapboxVision.xcodeproj" \
      -scheme "${SCHEME_TO_TEST}" \
      -destination "${DST}" \
      -configuration "${IOS_BUILD_TYPE}" \
      CONFIGURATION_BUILD_DIR="${IOS_BUILD_DIR}/" | xcpretty
}

###################
#   Main script   #
###################

if [[ $# -eq 2 ]]; then
    while [[ $# -gt 0 ]]; do
        argument="$1"

        case ${argument} in
            -b|--build)
                schemeToBuild="$2"
                buildProject "${schemeToBuild}"
                shift
                shift
                ;;
            *) # unknown option
                echoerr "Can't parse arguments. Unknown argument ${argument}"
                exit "$ERROR_CANT_PARSE_ARGUMENTS"
                ;;
        esac
    done
else
    echoerr "Arguments must be passed"
    exit "$ERROR_ILLEGAL_NUMBER_OF_ARGS"
fi
