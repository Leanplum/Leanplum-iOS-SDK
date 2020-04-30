#!/bin/bash
version=`cat sdk-version.txt`

body="{
\"request\": {
\"branch\":\"master\",
\"message\" : \"Building iOS SDK $version\",
 \"config\": {
   \"env\": {
     \"LEANPLUM_IOS_SDK_VERSION\": \"$version\"
   }
  }
}}"

curl -s -X POST \
   -H "Content-Type: application/json" \
   -H "Accept: application/json" \
   -H "Travis-API-Version: 3" \
   -H "Authorization: token $TRAVIS_TOKEN" \
   -d "$body" \
   https://api.travis-ci.org/repo/Leanplum%2FLeanplum-ReactNative-SDK/requests
