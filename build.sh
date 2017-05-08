#!/usr/bin/env bash
#
# LPM | Author: Ben Marten
# Copyright (c) 2017 Leanplum Inc. All rights reserved.
#
# shellcheck disable=SC2140
set -eo pipefail; [[ $DEBUG ]] && set -x

#######################################
# COMMON BEGIN
#######################################

#######################################
# Print out error messages along with other status information.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
err() {
  printf "%s%s%s\n" "${RED}ERROR [$(date +'%Y-%m-%dT%H:%M:%S%z')]: " "$@" "${NORMAL}" >&2
}

#######################################
# Runs a sub command and only outputs the stderr to console, then exits.
# Globals:
#   None
# Arguments:
#   Description of the command to run.
#   The command to run.
# Returns:
#   None
#######################################
run() {
  echo "$1"
  local cmd=${*:2}

  set +o errexit
  local error
  error=$(${cmd} 2>&1 >/dev/null)
  set -o errexit

  if [ -n "$error" ]; then
    err "Error running command: '$cmd':" "$error"
    exit 1
  fi
}

#######################################
# COMMON END
#######################################

#######################################
# Builds the Apple SDK.
# Globals:
#   IOS_VERSION The version to build.
#   BUILD_NUMBER The build number to use, defaults to timestamp.
# Arguments:
#   None
# Returns:
#   None
#######################################
main() {
  # Check for Jenkins build number, otherwise default to curent time in seconds.
  if [[ -z "${BUILD_NUMBER+x}" ]]; then 
    BUILD_NUMBER=$(date "+%s")
  fi
  export IOS_VERSION_STRING="$IOS_VERSION+$BUILD_NUMBER"

  LEANPLUM_SDK_ROOT=${LEANPLUM_SDK_ROOT:-"$(pwd)/."}
  RELEASE_DIR_BASE=${RELEASE_DIR_BASE:-"$LEANPLUM_SDK_ROOT/Release"}
  CONFIGURATION=${CONFIGURATION:-"Release"}
  BUILD_DIR=${BUILD_DIR:-"/tmp/AppleSDK-build"}
  BUILD_ROOT=${BUILD_ROOT:-"/tmp/AppleSDK-build"}
  ARM64_DIR=${ARM64_DIR:-"/build-arm64"}
  ARMV7S_DIR=${ARMV7S_DIR:-"/build-armv7s"}
  X8664_DIR=${X8664_DIR:-"/build-x86_64"}
  ARMV7_DIR=${ARMV7_DIR:-"/build-armv7"}
  X86_DIR=${X86_DIR:-"/build-x86"}
  default="${BUILD_DIR}${ARMV7_DIR}/${CONFIGURATION}-iphoneos"
  CURRENTCONFIG_ARMV7_DEVICE_DIR=${CURRENTCONFIG_ARMV7_DEVICE_DIR:-$default}
  default="${BUILD_DIR}${ARM64_DIR}/${CONFIGURATION}-iphoneos"
  CURRENTCONFIG_ARM64_DEVICE_DIR=${CURRENTCONFIG_ARM64_DEVICE_DIR:-$default}
  default="${BUILD_DIR}${ARMV7S_DIR}/${CONFIGURATION}-iphoneos"
  CURRENTCONFIG_ARMV7S_DEVICE_DIR=${CURRENTCONFIG_ARMV7S_DEVICE_DIR:-$default}
  default="${BUILD_DIR}${X86_DIR}/${CONFIGURATION}-iphonesimulator"
  CURRENTCONFIG_X86_DEVICE_DIR=${CURRENTCONFIG_X86_DEVICE_DIR:-$default}
  default="${BUILD_DIR}${X8664_DIR}/${CONFIGURATION}-iphonesimulator"
  CURRENTCONFIG_X8664_SIMULATOR_DIR=${CURRENTCONFIG_X8664_SIMULATOR_DIR:-$default}
  ACTION="clean build"

  DEVICE_SDK="iphoneos"
  SIM_SDK="iphonesimulator"

  rm -rf "$RELEASE_DIR_BASE"
  mkdir -p "$RELEASE_DIR_BASE"
  RELEASE_DIR="$RELEASE_DIR_BASE"
  mkdir -p "$RELEASE_DIR"
  
  # Build Dynamic Framework
  cd "$LEANPLUM_SDK_ROOT/Example/"
  pod install
  cd "$LEANPLUM_SDK_ROOT/Example/Pods"
  build_ios_dylib

  # Build Static Framework
  RELEASE_DIR="$RELEASE_DIR_BASE/static"
  mkdir -p "$RELEASE_DIR"
  
  export LP_STATIC=1
  cd "$LEANPLUM_SDK_ROOT/Example/"
  pod install
  cd "$LEANPLUM_SDK_ROOT/Example/Pods"
  build_ios

  echo "${GREEN} Done.${NORMAL}"
}

#######################################
# Builds the iOS Target.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
build_ios() {
  echo "Starting build for Leanplum-SDK (iOS)"

  run "Building Leanplum-SDK (device/armv7) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (device/armv7s) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7s' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7S_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (simulator/i386) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='i386' VALID_ARCHS='i386' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X86_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"

  mkdir "${RELEASE_DIR}/Leanplum.framework/"
  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARMV7_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/libLeanplum-iOS-SDK-source-iOS.a" \
    "${CURRENTCONFIG_ARMV7S_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/libLeanplum-iOS-SDK-source-iOS.a" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/libLeanplum-iOS-SDK-source-iOS.a" \
    "${CURRENTCONFIG_X86_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/libLeanplum-iOS-SDK-source-iOS.a" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK-source-iOS/libLeanplum-iOS-SDK-source-iOS.a"

  # Create .framework package.
  mkdir -p "${RELEASE_DIR}/Leanplum.framework"
  mkdir -p "${RELEASE_DIR}/Leanplum.framework/Headers"
  mkdir -p "${RELEASE_DIR}/Leanplum.framework/Modules"

  # Add modulemap.
cat <<EOF > "${RELEASE_DIR}/Leanplum.framework/Modules/module.modulemap"
framework module Leanplum {
  umbrella header "Leanplum.h"
  export *
  module *
  { export * }
}
EOF

  # Copy headers.
  cp "$LEANPLUM_SDK_ROOT/Leanplum-SDK/Classes/Leanplum.h" "${RELEASE_DIR}/Leanplum.framework/Headers"
  cp "$LEANPLUM_SDK_ROOT/Leanplum-SDK/Classes/Leanplum.h" "${RELEASE_DIR}/Leanplum.framework/Headers"

  printf "%s\n" "Successfully built Leanplum-SDK (iOS) Framework."
}

#######################################
# Builds the iOS dynamic library Target.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
build_ios_dylib() {
  echo "Starting build for Leanplum-SDK (iOS)"

  run "Building Leanplum-SDK (device/armv7) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (device/armv7s) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7s' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7S_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (simulator/i386) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='i386' VALID_ARCHS='i386' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X86_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"
  run "Building Leanplum-SDK (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source-iOS" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode"

  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/Leanplum" \
    "${CURRENTCONFIG_ARMV7_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARMV7S_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_X86_DEVICE_DIR}/Leanplum-iOS-SDK-source-iOS/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK-source-iOS/Leanplum.framework/Leanplum"

  # Copy generated framework
  cp -r "${BUILD_DIR}$ARMV7_DIR/$CONFIGURATION-iphoneos/Leanplum-iOS-SDK-source-iOS/Leanplum.framework/" \
    "${RELEASE_DIR}/Leanplum.framework"
  rm -f "${RELEASE_DIR}/Leanplum.framework/Leanplum"
  mv "${RELEASE_DIR}/Leanplum" "${RELEASE_DIR}/Leanplum.framework/"

  # Delete unnecessary headers
  mv "${RELEASE_DIR}/Leanplum.framework/Headers/Leanplum.h" \
    "${RELEASE_DIR}/Leanplum.framework/"
  mv "${RELEASE_DIR}/Leanplum.framework/Headers/LPInbox.h" \
    "${RELEASE_DIR}/Leanplum.framework/"
  rm -rf "${RELEASE_DIR}/Leanplum.framework/Headers"
  mkdir "${RELEASE_DIR}/Leanplum.framework/Headers"
  mv "${RELEASE_DIR}/Leanplum.framework/Leanplum.h" \
    "${RELEASE_DIR}/Leanplum.framework/Headers/"
  mv "${RELEASE_DIR}/Leanplum.framework/LPInbox.h" \
    "${RELEASE_DIR}/Leanplum.framework/Headers/"

  rm -rf "${RELEASE_DIR}/Leanplum.framework/_CodeSignature"
  # Update modulemap with correct import, since umbrella header is not generated by cocoapods with
  # a custom module_name set.
  sed -i "" -e "s/Leanplum-iOS-SDK-source-iOS-umbrella.h/Leanplum.h/g" \
    "${RELEASE_DIR}/Leanplum.framework/modules/module.modulemap"

  printf "%s\n" "Successfully built Leanplum-SDK (iOS) Framework.\n"
}

main "$@"
