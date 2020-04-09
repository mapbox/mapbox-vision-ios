#!/usr/bin/env bash

dir=$(dirname "${BASH_SOURCE[0]}")
source ${dir}/errors.sh

###################
#    Functions    #
###################

isDirExistsAtPath () {
    local -r dirPath="$1"
    [ -d "${dirPath}" ]
}

isFileExistsAtPath() {
    local -r filePath="$1"
    [ -f "${filePath}" ]
}

isFileExistsOnS3() {
    local -r filePath="$1"
    filesList=$(aws s3 ls "${filePath}")
}

createEmptyFileOnS3() {
    local -r remoteFilePath="$1"
    local -r fileName="$(basename ${remoteFilePath})"

    localFilePath="./${fileName}"
    touch "${localFilePath}"
    aws s3 cp "${localFilePath}" "$(dirname ${remoteFilePath})/"
    rm -f "${localFilePath}"
}
