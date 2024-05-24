#!/bin/sh -x
set -e
#export SKIP_NOTARY=1
PRODUCT_NAME="Scissors.app"
SCRIPT_FOLDER="$(dirname $0)"
PROJECT_FOLDER="../../"
SRC_PATH="../../"
echo manifest: $update_manifest
echo upload: $upload
###########################

if [ -e "${SRC_PATH}/../build/bitbucket_creds.sh" ] ; then 
	source "${SRC_PATH}/../build/bitbucket_creds.sh"
fi
if [ -e /Applications/DropDMG.app ]; then 
	osascript -e 'tell application "DropDMG" to get version'
fi

pushd ../..
agvtool next-version -all

buildNumber=$(agvtool what-version -terse)
popd

marketing_version=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' "${PROJECT_FOLDER}"/Scissors.xcodeproj/project.pbxproj)

date=$(date)



temp_folder=$(mktemp -d "/tmp/Scissors.XXXXXXXX")
BUILD_FOLDER="${temp_folder}/build"


xcodebuild archive -project "${SRC_PATH}/Scissors.xcodeproj" -scheme "Scissors" -archivePath  "${temp_folder}/Scissors.xcarchive"


xcodebuild -exportArchive -archivePath "${temp_folder}/Scissors.xcarchive"  -exportOptionsPlist "${SRC_PATH}/build_resources/exportOptions.plist" -exportPath "${BUILD_FOLDER}" 


echo saving symbols
mkdir -p "${PROJECT_FOLDER}/products/symbols/${buildNumber}"


cp -R "${temp_folder}/Scissors.xcarchive/dSYMs/" "${PROJECT_FOLDER}/products/symbols/${buildNumber}/"


cp -Rv "${SRC_PATH}/build_resources/" "${BUILD_FOLDER}"

echo "output is in ${BUILD_FOLDER}"
if [ -e /Users/tperfitt/Documents/Projects/build/build.sh ] ; then 
	/Users/tperfitt/Documents/Projects/build/build.sh  "${BUILD_FOLDER}" "${temp_folder}" "${PRODUCT_NAME}" "${BUILD_FOLDER}/${PRODUCT_NAME}" "${SCRIPT_FOLDER}/build_post.sh"
fi
