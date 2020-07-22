#!/usr/bin/env bash
#
# Author: Milos Jakovljevic
# Copyright (c) 2020 Leanplum Inc. All rights reserved.
#
# shellcheck disable=SC2140
set -eo pipefail; [[ $DEBUG ]] && set -x

main() {
    echo "Creating symlinks for all class headers"

    rm -rf Leanplum-SDK/include
    mkdir Leanplum-SDK/include

    # find all headers with absolute paths
    pushd Leanplum-SDK/Classes
    headers=$(find .. -name "*.h")
    popd

    # symlink all header files to include directory
    ln -s $headers "Leanplum-SDK/include"

    echo "${GREEN}Done.${NORMAL}"
}

main "$@"

