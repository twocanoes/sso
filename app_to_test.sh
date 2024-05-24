#!/bin/sh -e 


set -e
set -x 
BUILD_DIR="/tmp/ssoeexample"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"
if [ "${1}" ]; then
REMOTE_MAC=$1
else 
REMOTE_MAC="dev.local"
fi

agvtool bump
xcodebuild  -scheme "Scissors"  -configuration "Release" -derivedDataPath  "${DERIVED_DATA_DIR}"

ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/Applications/Scissors.app" ] ; then echo removing; rm -rf "/Applications/Scissors.app"; fi"'

if [ -e /tmp/ssoeexample/ssoeexample.zip ]; then
	rm /tmp/ssoeexample/ssoeexample.zip
fi

pushd /tmp/ssoeexample/DerivedData/Build/Products/Release/
zip -r /tmp/ssoeexample/ssoeexample.zip "Scissors.app"
popd 

ssh  root@"${REMOTE_MAC}" 'bash -c "if [ -e "/tmp/ssoeexample.zip" ] ; then echo removing; rm -rf "/tmp/ssoeexample.zip"; fi"'

scp -Cr /tmp/ssoeexample/ssoeexample.zip root@"${REMOTE_MAC}":/tmp/ssoeexample.zip


ssh root@"${REMOTE_MAC}" unzip /tmp/ssoeexample.zip -d /Applications
#scp -r /tmp/xcreds/DerivedData/Build/Products/Release/XCreds.app root@"${REMOTE_MAC}":/Applications
#ssh root@"${REMOTE_MAC}" reboot
exit 0
