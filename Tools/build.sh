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
  X8664_DIR=${X8664_DIR:-"/build-x86_64"}

  default="${BUILD_DIR}${ARM64_DIR}/${CONFIGURATION}-iphoneos"
  CURRENTCONFIG_ARM64_DEVICE_DIR=${CURRENTCONFIG_ARM64_DEVICE_DIR:-$default}
  default="${BUILD_DIR}${X8664_DIR}/${CONFIGURATION}-iphonesimulator"
  CURRENTCONFIG_X8664_SIMULATOR_DIR=${CURRENTCONFIG_X8664_SIMULATOR_DIR:-$default}
  
  # Clean and build
  ACTION="clean build"

  DEVICE_SDK="iphoneos"
  SIM_SDK="iphonesimulator"

  # Clear leftovers
  rm -rf "$RELEASE_DIR_BASE"
  mkdir -p "$RELEASE_DIR_BASE"

  # Build Dynamic Framework
  RELEASE_DIR="$RELEASE_DIR_BASE/dynamic"
  mkdir -p "$RELEASE_DIR"

  cd "$SDK_DIR/Example/"
  pod install
  cd "$SDK_DIR/Example/Pods"
  build_ios_dylib

  # Build Static Framework
  RELEASE_DIR="$RELEASE_DIR_BASE/static"
  mkdir -p "$RELEASE_DIR"
  
  export LP_STATIC=1
  cd "$SDK_DIR/Example/"
  pod install
  cd "$SDK_DIR/Example/Pods"
  build_ios_static

  # remove duplicate assets if any
  find "${RELEASE_DIR_BASE}/" -name '*.car' -not -path '*/Leanplum-iOS-SDK.bundle/*' -exec rm -rf {} +
  find "${RELEASE_DIR_BASE}/" -name '*.storyboardc' -not -path '*/Leanplum-iOS-SDK.bundle/*' -exec rm -rf {} +
  find "${RELEASE_DIR_BASE}/" -name '_CodeSignature' -exec rm -rf {} +

  # zip all iOS frameworks
  zip_ios
  
  # zip static iOS framework for Unreal Engine
  zip_unreal_engine

  echo "${GREEN} Done.${NORMAL}"
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
  echo "Starting build for Leanplum-SDK (iOS) dynamic framework"

  run "Building Leanplum-SDK-iOS dynamic (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  
  run "Building Leanplum-SDK-iOS dynamic (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"

  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/Leanplum" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK/Leanplum.framework/Leanplum"

  # Copy generated framework
  cp -r "${BUILD_DIR}$ARM64_DIR/$CONFIGURATION-iphoneos/Leanplum-iOS-SDK/Leanplum.framework/" \
    "${RELEASE_DIR}/Leanplum.framework"
  rm -f "${RELEASE_DIR}/Leanplum.framework/Leanplum"
  mv "${RELEASE_DIR}/Leanplum" "${RELEASE_DIR}/Leanplum.framework/"

  # create xcframework
  run "Combining builds into xcframework" \
  xcodebuild -create-xcframework \
    -framework "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK/Leanplum.framework" \
    -framework "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK/Leanplum.framework" \
    -output "${RELEASE_DIR}/Leanplum.xcframework"

  printf "%s\n" "Successfully built Leanplum-SDK (iOS) Framework."
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
build_ios_static() {
  echo "Starting build for Leanplum-SDK (iOS) static framework"

  run "Building Leanplum-SDK-iOS static (device/arm64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK" -sdk "${DEVICE_SDK}" \
    "$ACTION" ARCHS='arm64' RUN_CLANG_STATIC_ANALYZER=NO BUILD_DIR="${BUILD_DIR}${ARM64_DIR}" \
    BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"
  
  run "Building Leanplum-SDK-iOS static (simulator/x86_64) target ..." \
    xcodebuild -configuration "${CONFIGURATION}" -target "Leanplum-iOS-SDK" -sdk "${SIM_SDK}" \
    "$ACTION" ARCHS='x86_64' VALID_ARCHS='x86_64' RUN_CLANG_STATIC_ANALYZER=NO \
    BUILD_DIR="${BUILD_DIR}${X8664_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" \
    GCC_PREPROCESSOR_DEFINITIONS="PACKAGE_IDENTIFIER=${LEANPLUM_PACKAGE_IDENTIFIER}"

  # create framework for each slice first  
  mkdir -p "${RELEASE_DIR}/arm64/Leanplum.framework"
  mkdir -p "${RELEASE_DIR}/x86_64/Leanplum.framework"

  cp -r "${BUILD_DIR}$ARM64_DIR/$CONFIGURATION-iphoneos/Leanplum-iOS-SDK/Leanplum.framework/" \
    "${RELEASE_DIR}/Leanplum.framework"
  cp -r "${BUILD_DIR}$ARM64_DIR/$CONFIGURATION-iphoneos/Leanplum-iOS-SDK/Leanplum.framework/" \
    "${RELEASE_DIR}/arm64/Leanplum.framework"
  cp -r "${BUILD_DIR}$X8664_DIR/$CONFIGURATION-iphonesimulator/Leanplum-iOS-SDK/Leanplum.framework/" \
    "${RELEASE_DIR}/x86_64/Leanplum.framework"

  rm -f "${RELEASE_DIR}/Leanplum.framework/Leanplum"
  
  # combine and copy arm64 & x86_64 slice to universal framework
  run "Combining builds to universal fat library ..." \
    lipo -create -output "${RELEASE_DIR}/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK/libLeanplum-iOS-SDK.a" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK/libLeanplum-iOS-SDK.a"

  # copy the arm64 slice to framework
  lipo -create -output "${RELEASE_DIR}/arm64/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_ARM64_DEVICE_DIR}/Leanplum-iOS-SDK/libLeanplum-iOS-SDK.a" \

  # copy the x86_64 slice to framework
  lipo -create -output "${RELEASE_DIR}/x86_64/Leanplum.framework/Leanplum" \
    "${CURRENTCONFIG_X8664_SIMULATOR_DIR}/Leanplum-iOS-SDK/libLeanplum-iOS-SDK.a" \

  # create xcframework from each framework slice
  run "Combining builds into xcframework" \
  xcodebuild -create-xcframework \
    -framework "${RELEASE_DIR}/arm64/Leanplum.framework" \
    -framework "${RELEASE_DIR}/x86_64/Leanplum.framework" \
    -output "${RELEASE_DIR}/Leanplum.xcframework"

  rm -rf "${RELEASE_DIR}/arm64"
  rm -rf "${RELEASE_DIR}/x86_64"

  printf "%s\n" "Successfully built Leanplum-SDK (iOS) static Framework."
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
zip_ios() {
  echo "zipping for iOS release"
  cd "${RELEASE_DIR_BASE}"
  zip -r Leanplum.framework.zip *
  mv Leanplum.framework.zip "$SDK_DIR"
  cd -
}

zip_unreal_engine() {
  echo "zipping for Unreal Engine release"
  pwd
  cd "${RELEASE_DIR_BASE}/static"

  mkdir -p Leanplum.embeddedframework
  cp -R Leanplum.framework Leanplum.embeddedframework
  zip -r Leanplum.embeddedframework.zip Leanplum.embeddedframework
  mv Leanplum.embeddedframework.zip "$SDK_DIR"
  rm -rf Leanplum.embeddedframework

  mkdir -p Leanplum.embeddedxcframework
  cp -R Leanplum.xcframework Leanplum.embeddedxcframework
  zip -r Leanplum.embeddedxcframework.zip Leanplum.embeddedxcframework
  mv Leanplum.embeddedxcframework.zip "$SDK_DIR"
  rm -rf Leanplum.embeddedxcframework
  cd -
}

main "$@"
