#!/bin/bash
version=`cat sdk-version.txt`

git clone https://${GITHUB_TOKEN}@github.com/Leanplum/Leanplum-iOS-Location.git
cd Leanplum-iOS-Location
git checkout master
rm sdk-version.txt
cp ../sdk-version.txt .
git add sdk-version.txt
git commit -m "update version"
git tag `cat sdk-version.txt`
git push https://${GITHUB_TOKEN}@github.com/Leanplum/Leanplum-iOS-Location.git master
git push https://${GITHUB_TOKEN}@github.com/Leanplum/Leanplum-iOS-Location.git master `cat sdk-version.txt`
