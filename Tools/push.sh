#!/usr/bin/env bash

source ~/.rvm/scripts/rvm
rvm use default
pod trunk push Leanplum-iOS-SDK-source.podspec --allow-warnings
