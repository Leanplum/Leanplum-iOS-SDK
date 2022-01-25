#!/usr/bin/env bash
git config --local user.email "$GITHUB_EMAIL"
git config --local user.name "$GITHUB_NAME"
git config pull.rebase false
git remote set-url origin https://$GITHUB_NAME:$GITHUB_TOKEN@github.com/Leanplum/Leanplum-iOS-SDK.git
RELEASE_VERSION=${TRAVIS_TAG%-*}
echo $RELEASE_VERSION
git checkout -b release/$RELEASE_VERSION
git restore --staged .
git add Package.swift
git commit -m 'update spm'
git pull origin release/$RELEASE_VERSION
git push --set-upstream origin release/$RELEASE_VERSION
git tag -f `cat sdk-version.txt`
git push -f origin `cat sdk-version.txt`