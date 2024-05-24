#!/bin/bash 

set -e



pushd ./build_resources/buildscripts/

SKIP_DMG=1 ./build.sh

popd
