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
  export IOS_VERSION_STRING=${IOS_VERSION_STRING:-"$IOS_VERSION.$BUILD_NUMBER"}

  SDK_DIR=${SDK_DIR:-"$(pwd)/."}
  RELEASE_DIR_BASE=${RELEASE_DIR_BASE:-"$SDK_DIR/Release"}
  LEANPLUM_PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER:-"s"}
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
  default="${BUILD_DIR}${ARM64_DIR}/${CONFIGURATION}-appletvos"
  CURRENTCONFIG_ARM64_TV_DEVICE_DIR=${CURRENTCONFIG_ARM64_TV_DEVICE_DIR:-$default}
  default="${BUILD_DIR}${X8664_DIR}/${CONFIGURATION}-appletvsimulator"
  CURRENTCONFIG_X8664_TV_SIMULATOR_DIR=${CURRENTCONFIG_X8664_TV_SIMULATOR_DIR:-$default}
  ACTION="clean build"

  DEVICE_SDK="iphoneos"
  TVOS_SDK="appletvos"
  SIM_SDK="iphonesimulator"
  TVOS_SIM_SDK="appletvsimulator"

  rm -rf "$RELEASE_DIR_BASE"
  mkdir -p "$RELEASE_DIR_BASE"
  RELEASE_DIR="$RELEASE_DIR_BASE"
  mkdir -p "$RELEASE_DIR"
  
  # Build Dynamic Framework
  cd "$SDK_DIR/Example/"
  pod install
  cd "$SDK_DIR/Example/Pods"
  build_ios_dylib
  build_tvos_dylib

  # Build Static Framework
  RELEASE_DIR="$RELEASE_DIR_BASE/static"
  mkdir -p "$RELEASE_DIR"
  
  export LP_STATIC=1
  cd "$SDK_DIR/Example/"
  pod install
  cd "$SDK_DIR/Example/Pods"
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

  run "Building Leanplum-SDK-iOS static (device/armv7) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS static (device/armv7s) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7s' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7S_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS static (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS static (simulator/i386) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='i386' VALID_ARCHS='i386' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X86_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS static (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"

  mkdir "${RELEASE_DIR}/Leanplum.framework/"
  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARMV7_DEVICE_DIR}/Leanplum-iOS-SDK-source/libLeanplum-iOS-SDK-source.a" \
    "${CURRENTCONFIG_ARMV7S_DEVICE_DIR}/Leanplum-iOS-SDK-source/libLeanplum-iOS-SDK-source.a" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK-source/libLeanplum-iOS-SDK-source.a" \
    "${CURRENTCONFIG_X86_DEVICE_DIR}/Leanplum-iOS-SDK-source/libLeanplum-iOS-SDK-source.a" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK-source/libLeanplum-iOS-SDK-source.a"

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
  cp "$SDK_DIR/Leanplum-SDK/Classes/Leanplum.h" "${RELEASE_DIR}/Leanplum.framework/Headers"
  cp "$SDK_DIR/Leanplum-SDK/Classes/LPInbox.h" "${RELEASE_DIR}/Leanplum.framework/Headers"

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

  run "Building Leanplum-SDK-iOS dynamic (device/armv7) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS dynamic (device/armv7s) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='armv7s' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARMV7S_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS dynamic (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS dynamic (simulator/i386) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='i386' VALID_ARCHS='i386' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X86_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-iOS dynamic (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK-source" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"

  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/Leanplum" \
    "${CURRENTCONFIG_ARMV7_DEVICE_DIR}/Leanplum-iOS-SDK-source/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARMV7S_DEVICE_DIR}/Leanplum-iOS-SDK-source/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK-source/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_X86_DEVICE_DIR}/Leanplum-iOS-SDK-source/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK-source/Leanplum.framework/Leanplum"

  # Copy generated framework
  cp -r "${BUILD_DIR}$ARMV7_DIR/$CONFIGURATION-iphoneos/Leanplum-iOS-SDK-source/Leanplum.framework/" \
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
  sed -i "" -e "s/Leanplum-iOS-SDK-source-umbrella.h/Leanplum.h/g" \
    "${RELEASE_DIR}/Leanplum.framework/modules/module.modulemap"

  printf "%s\n" "Successfully built Leanplum-SDK (iOS) Framework.\n"
}

#######################################
# Builds the dynamic library tvOS target.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
build_tvos_dylib() {
  echo "Starting build for Leanplum-SDK (tvOS)"

  mkdir -p "${RELEASE_DIR}/"

  run "Building Leanplum-SDK-tvOS dynamic (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-tvOS-SDK-source" -sdk "${TVOS_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  run "Building Leanplum-SDK-tvOS dynamic (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-tvOS-SDK-source" -sdk "${TVOS_SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"

  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/LeanplumTV" \
    "${CURRENTCONFIG_ARM64_TV_DEVICE_DIR}/Leanplum-tvOS-SDK-source/LeanplumTV.framework/LeanplumTV" \
    "${CURRENTCONFIG_X8664_TV_SIMULATOR_DIR}/Leanplum-tvOS-SDK-source/LeanplumTV.framework/LeanplumTV"

  # Copy generated framework
  cp -r "${BUILD_DIR}$ARM64_DIR/$CONFIGURATION-appletvos/Leanplum-tvOS-SDK-source/"\
"LeanplumTV.framework/" "${RELEASE_DIR}/LeanplumTV.framework"
  rm -f "${RELEASE_DIR}/LeanplumTV.framework/LeanplumTV"
  mv "${RELEASE_DIR}/LeanplumTV" "${RELEASE_DIR}/LeanplumTV.framework/"

  # Delete unnecessary headers
  mv "${RELEASE_DIR}/LeanplumTV.framework/Headers/Leanplum.h" \
    "${RELEASE_DIR}/LeanplumTV.framework/"
  mv "${RELEASE_DIR}/LeanplumTV.framework/Headers/LPInbox.h" \
    "${RELEASE_DIR}/LeanplumTV.framework/"
  rm -rf "${RELEASE_DIR}/LeanplumTV.framework/Headers"
  mkdir "${RELEASE_DIR}/LeanplumTV.framework/Headers"
  mv "${RELEASE_DIR}/LeanplumTV.framework/Leanplum.h" \
    "${RELEASE_DIR}/LeanplumTV.framework/Headers/"
  mv "${RELEASE_DIR}/LeanplumTV.framework/LPInbox.h" \
    "${RELEASE_DIR}/LeanplumTV.framework/Headers/"

  rm -rf "${RELEASE_DIR}/LeanplumTV.framework/_CodeSignature"

  # Update modulemap with correct import, since umbrella header is not generated by cocoapods with
  # a custom module_name set.
  sed -i "" -e "s/Leanplum-tvOS-SDK-source-umbrella.h/Leanplum.h/g" \
    "${RELEASE_DIR}/LeanplumTV.framework/modules/module.modulemap"

  printf "%s\n" "Successfully built Leanplum-SDK (tvOS) Framework.\n"
}

main "$@"
