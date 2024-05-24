#!/bin/bash

set -e
set -x

script_path="${0}"
package_path="${1}"
target_path="${2}"
target_volume="${3}"

if [ -e  "${target_volume}"/Applications/Twocanoes Single Sign-On.app ]; then
	rm -rf "${target_volume}/Applications/Twocanoes Single Sign-On"
	
fi