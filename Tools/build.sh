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
  rm -rf Release

  build_ios_dylib
  printf "\n"
  build_ios_static

  # # remove duplicate assets if any
  find "Release/" -name '_CodeSignature' -exec rm -rf {} +

  rm -rf Release/dynamic/LeanplumSDK-iphoneos.xcarchive
  rm -rf Release/dynamic/LeanplumSDK-iphonesimulator.xcarchive
  rm -rf Release/static/LeanplumSDK-iphoneos.xcarchive
  rm -rf Release/static/LeanplumSDK-iphonesimulator.xcarchive

  # move binary for SPM
  cp_spm
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

  run "Building Leanplum-SDK-iOS dynamic (simulator) target ..." \
  xcodebuild archive \
  -scheme Leanplum \
  -archivePath Release/dynamic/LeanplumSDK-iphonesimulator.xcarchive \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO

  run "Building Leanplum-SDK-iOS dynamic (device) target ..." \
  xcodebuild archive \
  -scheme Leanplum \
  -archivePath Release/dynamic/LeanplumSDK-iphoneos.xcarchive \
  -sdk iphoneos \
  SKIP_INSTALL=NO

  run "Creating Leanplum-SDK-iOS dynamic xcframework ..." \
  xcodebuild -create-xcframework \
  -framework Release/dynamic/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework \
  -framework Release/dynamic/LeanplumSDK-iphoneos.xcarchive/Products/Library/Frameworks/Leanplum.framework \
  -output Release/dynamic/Leanplum.xcframework

  # simulator build also contains arm64 slice, we are removing it to keep backward compatibility
  # it will still be available in xcframework
  run "Removing arm64 from simulator slice ..." \
  lipo -remove arm64 \
    Release/dynamic/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum \
    -output Release/dynamic/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum

  cp -r Release/dynamic/LeanplumSDK-iphoneos.xcarchive/Products/Library/Frameworks/Leanplum.framework \
    Release/dynamic/Leanplum.framework
  rm -rf Release/dynamic/Leanplum.framework/Leanplum

  run "Creating iphoneos & iphonesimulator fat dynamic library ..." \
  lipo -create \
    Release/dynamic/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum \
    Release/dynamic/LeanplumSDK-iphoneos.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum \
    -output Release/dynamic/Leanplum.framework/Leanplum

  run "Modifying plist to include both Simulator & iPhone ..." \
  plutil -insert CFBundleSupportedPlatforms.1 -string iPhoneSimulator Release/dynamic/Leanplum.framework/Info.plist

  printf "%s\n" "Successfully built Leanplum-SDK dynamic framework."
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
  echo "Starting build for Leanplum-SDK static framework"

  run "Building Leanplum-SDK-iOS static (simulator) target ..." \
  xcodebuild archive \
  -scheme Static \
  -archivePath Release/static/LeanplumSDK-iphonesimulator.xcarchive \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO

  run "Building Leanplum-SDK-iOS static (device) target ..." \
  xcodebuild archive \
  -scheme Static \
  -archivePath Release/static/LeanplumSDK-iphoneos.xcarchive \
  -sdk iphoneos \
  SKIP_INSTALL=NO

  run "Creating Leanplum-SDK-iOS static xcframework ..." \
  xcodebuild -create-xcframework \
  -framework Release/static/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework \
  -framework Release/static/LeanplumSDK-iphoneos.xcarchive/Products/Library/Frameworks/Leanplum.framework \
  -output Release/static/Leanplum.xcframework

  run "Removing arm64 from simulator slice ..." \
  lipo -remove arm64 \
    Release/static/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum \
    -output Release/static/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum

  cp -r Release/static/LeanplumSDK-iphoneos.xcarchive/Products/Library/Frameworks/Leanplum.framework \
    Release/static/Leanplum.framework
  rm -rf Release/static/Leanplum.framework/Leanplum

  run "Creating iphoneos & iphonesimulator fat static library ..." \
  lipo -create \
    Release/static/LeanplumSDK-iphonesimulator.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum \
    Release/static/LeanplumSDK-iphoneos.xcarchive/Products/Library/Frameworks/Leanplum.framework/Leanplum \
    -output Release/static/Leanplum.framework/Leanplum

  run "Modifying plist to include both Simulator & iPhone ..." \
  plutil -insert CFBundleSupportedPlatforms.1 -string iPhoneSimulator Release/static/Leanplum.framework/Info.plist

  printf "%s\n" "Successfully built Leanplum-SDK static framework."
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
  cd Release/dynamic
  zip -r Leanplum.framework.zip *
  mv Leanplum.framework.zip ..
  cd -
}

cp_spm() {
  echo "moving xcframework binary for SPM target"
  mkdir -p binary
  cp -f -r "Release/dynamic/Leanplum.xcframework" "binary/Leanplum.xcframework"
}

zip_unreal_engine() {
  echo "zipping for Unreal Engine release"
  pwd
  cd Release/static

  mkdir -p Leanplum.embeddedframework
  cp -R Leanplum.framework Leanplum.embeddedframework
  zip -r Leanplum.embeddedframework.zip Leanplum.embeddedframework
  mv Leanplum.embeddedframework.zip ..
  rm -rf Leanplum.embeddedframework

  mkdir -p Leanplum.embeddedxcframework
  cp -R Leanplum.xcframework Leanplum.embeddedxcframework
  zip -r Leanplum.embeddedxcframework.zip Leanplum.embeddedxcframework
  mv Leanplum.embeddedxcframework.zip ..
  rm -rf Leanplum.embeddedxcframework
  cd -
}

main "$@"
