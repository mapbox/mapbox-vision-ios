#!/usr/bin/env bash

set -euo pipefail

dir=$(dirname "${BASH_SOURCE[0]}")
source ${dir}/../utils/environment.sh
source ${dir}/../utils/errors.sh

###########################
#   Filescope variables   #
###########################

# Uncomment lines below to debug
#IOS_BUILD_TYPE="Release"
#IOS_PLATFORM_TYPE="iphoneos"
#IOS_BUILD_DIR="build"

# We have only release builds on AWS
buildConfig="Release-${IOS_PLATFORM_TYPE}"
s3BasePath="${AWS_S3_BUILD_ARTIFACTS_BASE_PATH}"

# "Directories" on AWS S3 to store uploaded build products
s3BuildDir="${s3BasePath}/${buildConfig}"

checksumFileName=".checksumSHA256.txt"
syncMarkerFileName=".syncMarkerFile"
pullMarkerFileName=".pullMakerFile"

########################
#   Helper functions   #
########################

function performCleanup() {
    rm -f "${copiedRemoteChecksumFile}"
}

function pullFramework() {
    frameworkName="$1"
    framework="${frameworkName}.framework"

    localFrameworkPath="Carthage/Build/iOS/${buildConfig}/${framework}"
    remoteFrameworkPath="${s3BuildDir}/${frameworkName}/${framework}" 

    echo
    echo "Pulling ${framework}"
    echo

    echo "Checking if ${framework} exists locally"
    localChecksum=""
    if ! isDirExistsAtPath "${localFrameworkPath}"; then
        echo "Build product ${framework} is not found at ${localFrameworkPath}"
    else
        set +o pipefail
        localChecksum=$(find "${localFrameworkPath}" -print0 | sort -z | xargs -0 shasum -a 256 2>&1 | shasum -a 256 | awk '{print $1}')
        set -o pipefail
    fi

    echo "Getting a checksum for a remote version of ${framework}"

    remoteChecksumFilePath="${s3BuildDir}/${frameworkName}/${checksumFileName}"
    copiedRemoteChecksumFile="./${checksumFileName}"

    if isFileExistsOnS3 "${remoteChecksumFilePath}"; then
        aws s3 cp "${remoteChecksumFilePath}" "${copiedRemoteChecksumFile}"

        if isFileExistsAtPath "${copiedRemoteChecksumFile}"; then
            remoteChecksum=$(cat ${copiedRemoteChecksumFile})
            
            echo
            echo "Checksum for a remote build product: ${remoteChecksum}"
            echo "Checksum for a local build product:  ${localChecksum}"

            if [[ "${localChecksum}" == "${remoteChecksum}" ]]; then
                echo "${frameworkName} at ${s3BuildDir} was not changed, update is not needed"
                performCleanup
                return
            else
                echo "There's a new version of ${framework}, update is needed"
            fi
        fi
    else
        echoerr "Checksum file does not exist at ${remoteChecksumFilePath}"
        exit "$ERROR_FILE_DOES_NOT_EXIST"
    fi

    # We implement "mutual exclusion" with files we can treat as flags.
    # Each actor (repository) which wants to work with AWS S3, sets up a flag (creates an empty marker file).
    # Other actors (repositories) can easily see the flags.
    # When `mapbox-vision-ios` repo wants to pull the new verison of framework, it does the following:
    # 1. raise the flag (creates a pullMarkerFlag file)
    # 2. when there's no syncMarkerFlag, we start pulling process
    # 3. when the pulling is completed, we lower the flag (remove pullMarkerFlag file)
    #
    # What we do in case when there's a syncMarkerFlag (step 2 above)?
    # - we lower our flag (removes pullMarkerFlag file)
    # - we wait until sync flag is lowered (syncMarkerFlag is removed)
    # - then we raise our flag (create pullMarkerFlag file)
    #
    # The same behaviour is applicable for other actors (including mapbox-vision repo).

    echo
    echo "Checking if build artifacts are currently being updated"
    echo
    syncMarkerFilePath="${s3BuildDir}/${frameworkName}/${syncMarkerFileName}"
    pullMarkerFilePath="${s3BuildDir}/${frameworkName}/${pullMarkerFileName}"

    while : ; do
        echo "Putting a pull marker to indicate we want to pull latest build artifacts"
        createEmptyFileOnS3 "${pullMarkerFilePath}"

        if isFileExistsOnS3 "${syncMarkerFilePath}"; then
            echo "Sync marker was found. That means uploading of build artifacts is in progress"
            echo "Removing the pull marker"
            aws s3 rm "${pullMarkerFilePath}" --quiet
        else
            echo "Sync marker was not found. That means we can start pulling process"
            break
        fi

        echo "Retrying in several seconds"
        echo
        sleep $[ ( $RANDOM % 20 )  + 1 ]s # 1-20 seconds random sleep, time interval to check flag next time
    done

    echo
    echo "Start syncing"
    echo

    aws s3 sync "${s3BuildDir}/${frameworkName}/${framework}" "${localFrameworkPath}"

    echo
    echo "Removing the pull marker to allow external repos to upload updated build artifacts"
    echo
    aws s3 rm "${pullMarkerFilePath}" --quiet

    performCleanup
    echo "${framework} was sucсessfully pulled"
}

function pullNativeBuildProducts() {
    if [[ $# -ne 0 ]]; then
        echoerr "Illegal arguments passed to ${FUNCNAME[0]}"
        exit "$ERROR_ILLEGAL_NUMBER_OF_ARGS"
    fi

    local -r buildArtifactsToPull=("MapboxVisionNative" "MapboxVisionARNative" "MapboxVisionSafetyNative")

    for buildArtifact in "${buildArtifactsToPull[@]}"; do
        pullFramework "${buildArtifact}"

        # copy pulled frameworks into Carthage/Build/iOS dir to allow building
        echo "Copying ${buildArtifact} into Carthage/Build/iOS dir"
        cp -a "Carthage/Build/iOS/${IOS_BUILD_TYPE}-${IOS_PLATFORM_TYPE}/${buildArtifact}.framework" "Carthage/Build/iOS"
    done
    
    echo
    echo "Build dependecies are up-to-date now."
    echo
}

###################
#   Main script   #
###################

if [[ $# -gt 0 ]]; then
    while [[ $# -gt 0 ]]; do
        argument="$1"

        case ${argument} in
            -p|--pull-native-deps)
                pullNativeBuildProducts
                shift
                ;;
            *)  # unknown option
                echoerr "Can't parse arguments. Unknown argument ${argument}"
                exit "$ERROR_CANT_PARSE_ARGUMENTS"
                ;;
        esac
    done
else
    echoerr "Arguments must be passed"
    exit "$ERROR_ILLEGAL_NUMBER_OF_ARGS"
fi
