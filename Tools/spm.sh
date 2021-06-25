#!/usr/bin/env bash
#
# Author: Milos Jakovljevic
# Copyright (c) 2020 Leanplum Inc. All rights reserved.
#
# shellcheck disable=SC2140
set -eo pipefail; [[ $DEBUG ]] && set -x

main() {
    echo "Creating symlinks for all headers & resources"

    pushd LeanplumSDK/LeanplumSDK
    rm -rf Resources
    ln -s ../LeanplumSDKBundle/Resources Resources
    popd

    rm -rf LeanplumSDK/LeanplumSDK/include
    mkdir LeanplumSDK/LeanplumSDK/include

    # find all headers with absolute paths
    pushd LeanplumSDK/LeanplumSDK/Classes
    headers=$(find .. -name "*.h")
    popd

    # symlink all header files to include directory
    ln -s $headers "LeanplumSDK/LeanplumSDK/include"

    echo "${GREEN}Done.${NORMAL}"
}

main "$@"

