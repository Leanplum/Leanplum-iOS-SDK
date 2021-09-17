#!/usr/bin/env bash
#
# Author: Milos Jakovljevic
# Copyright (c) 2020 Leanplum Inc. All rights reserved.
#
# shellcheck disable=SC2140
set -eo pipefail; [[ $DEBUG ]] && set -x

main() {
    echo "Extracting xcframework binary for SPM target"

    unzip -q "Leanplum.framework.zip" -d "Leanplum.framework"
    mv "Leanplum.framework/dynamic/Leanplum.xcframework" "/binary/Leanplum.xcframework"
    rm -rf "Leanplum.framework"

    echo "${GREEN}Done.${NORMAL}"
}

main "$@"

