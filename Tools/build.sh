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

XCODEBUILD_PATH="xcodebuild"

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

  if [ -n "$1" ]; then
    XCODEBUILD_PATH=$1
    echo "Using xcodebuild path: $XCODEBUILD_PATH"
  fi

  pod install

  build_ios_dylib 'Leanplum' 'Release/dynamic/LeanplumSDK'
  build_ios_dylib 'LeanplumLocation' 'Release/dynamic/LeanplumSDKLocation'
  build_ios_dylib 'LeanplumLocationAndBeacons' 'Release/dynamic/LeanplumSDKLocationAndBeacons'

  printf "\n"
  build_ios_static 'Leanplum-Static' 'Release/static/LeanplumSDK' 'Leanplum'
  build_ios_static 'LeanplumLocation-Static' \
  'Release/static/LeanplumSDKLocation' 'LeanplumLocation'
  build_ios_static 'LeanplumLocationAndBeacons-Static' \
  'Release/static/LeanplumSDKLocationAndBeacons' 'LeanplumLocationAndBeacons'

  # remove duplicate assets if any
  find "Release/" -name '_CodeSignature' -exec rm -rf {} +

  # codesign
  SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Distribution: Leanplum, Inc." | awk '{print $2}')
  if [ -n "$SIGNING_IDENTITY" ]; then
    echo "Codesigning xcframeworks"
    find "Release/" -name '*.xcframework' -exec codesign --timestamp -s $SIGNING_IDENTITY {} +
  else
    echo "Signing Identity not found"
  fi

  # zip all iOS frameworks
  zip_ios

  # update SPM checksum and url
  update_spm_info

  # zip static iOS framework for Unreal Engine
  zip_unreal_engine

  echo "Built with Xcode path: $XCODEBUILD_PATH and version: `"$XCODEBUILD_PATH" -version`"

  echo "${GREEN} Done.${NORMAL}"
}

#######################################
# Builds dynamic xcframework from device and simulator archives.
# Globals:
#   None
# Arguments:
#   archivePath
#   framework
# Returns:
#   None
#######################################
create_dynamic_xcframework() {  
  archivePath=$1
  framework=$2

  xcframework=${framework/"framework"/"xcframework"}

  if [[ "$framework" != *"Pods_"* ]]; then
    echo "Creating dynamic $xcframework ..."
    "$XCODEBUILD_PATH" -quiet -create-xcframework \
    -framework $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$framework \
    -framework $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$framework \
    -output Release/dynamic/$xcframework
  fi
}

#######################################
# Builds the iOS dynamic library Target.
# Globals:
#   None
# Arguments:
#   scheme
#   archivePath
# Returns:
#   None
#######################################
build_ios_dylib() {
  scheme=$1
  archivePath=$2
  
  echo "Starting build for $scheme (iOS) dynamic framework"

  echo "Building $scheme dynamic (simulator) target ..."
  "$XCODEBUILD_PATH" archive \
  -quiet \
  -scheme $scheme \
  -archivePath $archivePath-iphonesimulator.xcarchive \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  SKIP_INSTALL=NO

  echo "Building $scheme dynamic (device) target ..."
  "$XCODEBUILD_PATH" archive \
  -quiet \
  -scheme $scheme \
  -archivePath $archivePath-iphoneos.xcarchive \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  SKIP_INSTALL=NO

  find "$archivePath-iphoneos.xcarchive/Products/Library/Frameworks" \
  -name "*.framework" \
  -type d \
  -exec /bin/bash -c 'create_dynamic_xcframework "$1" "`basename $0`"' {} $archivePath \; 
  
  # Remove module name from xcframework swiftinterface
  # It prevents error X is not a member of type Leanplum.Leanplum
  # This happens when a class name is same as the module name
  # https://stackoverflow.com/a/62310245
  find Release/dynamic/$scheme.xcframework -name "*.swiftinterface" -exec sed -i -e "s/$scheme\.//g" {} \;

  # simulator build also contains arm64 slice, we are removing it to keep backward compatibility
  # it will still be available in xcframework
  echo "Removing arm64 from simulator slice ..."
  lipo -remove arm64 \
    $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$scheme.framework/$scheme \
    -output $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$scheme.framework/$scheme

  cp -r $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$scheme.framework \
    Release/dynamic/$scheme.framework
  rm -rf Release/dynamic/$scheme.framework/$scheme

  echo "Creating iphoneos & iphonesimulator fat dynamic library ..."
  lipo -create \
        $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$scheme.framework/$scheme \
        $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$scheme.framework/$scheme \
    -output Release/dynamic/$scheme.framework/$scheme

  echo "Modifying plist to include both Simulator & iPhone ..."
  plutil -insert CFBundleSupportedPlatforms.1 -string iPhoneSimulator Release/dynamic/$scheme.framework/Info.plist

  rm -rf $archivePath-iphoneos.xcarchive
  rm -rf $archivePath-iphonesimulator.xcarchive
  printf "%s\n" "Successfully built $scheme dynamic framework."
}

#######################################
# Builds the iOS Target.
# Globals:
#   None
# Arguments:
#   scheme
#   archivePath
#   productName
# Returns:
#   None
#######################################
build_ios_static() {
  scheme=$1
  archivePath=$2
  productName=$3
  
  echo "Starting build for $scheme static framework"

  echo "Building $scheme static (simulator) target ..."
  "$XCODEBUILD_PATH" archive \
  -quiet \
  -scheme $scheme \
  -archivePath $archivePath-iphonesimulator.xcarchive \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  SKIP_INSTALL=NO

  echo "Building $scheme static (device) target ..."
  "$XCODEBUILD_PATH" archive \
  -quiet \
  -scheme $scheme \
  -archivePath $archivePath-iphoneos.xcarchive \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  SKIP_INSTALL=NO

  echo "Creating $scheme static xcframework ..."
  "$XCODEBUILD_PATH" -quiet -create-xcframework \
  -framework $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$productName.framework \
  -framework $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$productName.framework \
  -output Release/static/$productName.xcframework
  
  # Remove module name from xcframework swiftinterface
  # It prevents error X is not a member of type Leanplum.Leanplum
  # This happens when a class name is same as the module name
  # https://stackoverflow.com/a/62310245
  find Release/static/Leanplum.xcframework -name "*.swiftinterface" -exec sed -i -e "s/Leanplum\.//g" {} \;

  # Remove module name from xcframework swiftinterface
  # It prevents error X is not a member of type Leanplum.Leanplum
  # This happens when a class name is same as the module name
  # https://stackoverflow.com/a/62310245
  find Release/static/Leanplum.xcframework -name "*.swiftinterface" -exec sed -i -e "s/Leanplum\.//g" {} \;

  echo "Removing arm64 from simulator slice ..."
  lipo -remove arm64 \
    $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$productName.framework/$productName \
    -output $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$productName.framework/$productName

  cp -r $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$productName.framework \
    Release/static/$productName.framework
  rm -rf Release/static/$productName.framework/$productName

  echo "Creating iphoneos & iphonesimulator fat static library ..."
  lipo -create \
        $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$productName.framework/$productName \
        $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$productName.framework/$productName \
    -output Release/static/$productName.framework/$productName

  echo "Modifying plist to include both Simulator & iPhone ..."
  plutil -insert CFBundleSupportedPlatforms.1 -string iPhoneSimulator Release/static/$productName.framework/Info.plist

  rm -rf $archivePath-iphoneos.xcarchive
  rm -rf $archivePath-iphonesimulator.xcarchive
  printf "%s\n" "Successfully built $scheme static framework."
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
  cd Release
  zip -q -r Leanplum.zip .
  mv Leanplum.zip ..

  echo "zipping static xcframework for SPM"
  cd static
  zip -q -r Leanplum.xcframework.zip \
    Leanplum.xcframework
  cd ../..
}

update_spm_info(){
  echo "updating SPM checksum and url"
  package_file=Package.swift
  package_tmp_file=Package_tmp.swift
  checksum=`swift package compute-checksum Release/static/Leanplum.xcframework.zip`
  awk -v value="\"$checksum\"" '!x{x=sub(/checksum:.*/, "checksum: "value)}1' $package_file > $package_tmp_file \
      && mv $package_tmp_file $package_file
  
  version=`cat sdk-version.txt`
  lp_framework="Leanplum.xcframework.zip"
  github_url="https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download"
  github_url_escaped="https:\/\/github.com\/Leanplum\/Leanplum-iOS-SDK\/releases\/download"
  url="$github_url/$version/$lp_framework"
  sub="!x{x=sub(/url: \\\"${github_url_escaped}.*/, \"url: \"value)}1"
  awk -v value="\"$url\"," "$sub" $package_file > $package_tmp_file \
    && mv $package_tmp_file $package_file
}

zip_unreal_engine() {
  echo "zipping for Unreal Engine release"
  pwd
  cd Release/static

  mkdir -p Leanplum.embeddedframework
  cp -R Leanplum.framework Leanplum.embeddedframework
  zip -q -r Leanplum.embeddedframework.zip Leanplum.embeddedframework
  mv Leanplum.embeddedframework.zip ..
  rm -rf Leanplum.embeddedframework

  mkdir -p Leanplum.embeddedxcframework
  cp -R Leanplum.xcframework Leanplum.embeddedxcframework
  zip -q -r Leanplum.embeddedxcframework.zip Leanplum.embeddedxcframework
  mv Leanplum.embeddedxcframework.zip ..
  rm -rf Leanplum.embeddedxcframework
  cd -
}

export -f create_dynamic_xcframework
export XCODEBUILD_PATH
main "$@"
