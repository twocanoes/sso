#!/bin/sh -e 


set -e
set -x 
SRC_PATH="../../"
BUILD_DIR="/tmp/ssoeexample"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"
if [ "${1}" ]; then
REMOTE_MAC=$1
else 
REMOTE_MAC="test.local"
fi

agvtool bump
#xcodebuild  -scheme "Scissors"  -configuration "Release" -derivedDataPath  "${DERIVED_DATA_DIR}"
#xcodebuild -exportArchive -archivePath "${BUILD_DIR}/Scissors.xcarchive"  -exportOptionsPlist ".//build_resources/exportOptions.plist" -exportPath "${BUILD_DIR}"
pushd ./build_resources/buildscripts/

xcodebuild archive -project "${SRC_PATH}/Scissors.xcodeproj" -scheme "Scissors" -archivePath  "${BUILD_DIR}/Scissors.xcarchive"


xcodebuild -exportArchive -archivePath "${BUILD_DIR}/Scissors.xcarchive"  -exportOptionsPlist "${SRC_PATH}/build_resources/exportOptions.plist" -exportPath "${BUILD_DIR}" 

ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/Applications/Scissors.app" ] ; then echo removing; rm -rf "/Applications/Scissors.app"; fi"'

if [ -e /tmp/ssoeexample/ssoeexample.zip ]; then
	rm /tmp/ssoeexample/ssoeexample.zip
fi

pushd /tmp/ssoeexample/
zip -r /tmp/ssoeexample/ssoeexample.zip "Scissors.app"
popd 

ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/tmp/ssoeexample.zip" ] ; then echo removing; rm -rf "/tmp/ssoeexample.zip"; fi"'

scp -Cr /tmp/ssoeexample/ssoeexample.zip root@"${REMOTE_MAC}":/tmp/ssoeexample.zip


ssh root@"${REMOTE_MAC}" unzip /tmp/ssoeexample.zip -d /Applications
#scp -r /tmp/xcreds/DerivedData/Build/Products/Release/XCreds.app root@"${REMOTE_MAC}":/Applications
#ssh root@"${REMOTE_MAC}" reboot
exit 0
