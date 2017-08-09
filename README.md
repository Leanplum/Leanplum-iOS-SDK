![Leanplum](Leanplum.png)

<p align="center">
<a href="https://travis-ci.org/xmartlabs/Eureka"><img src="https://travis-ci.org/xmartlabs/Eureka.svg?branch=master" alt="Build status" /></a>
<img src="https://img.shields.io/cocoapods/dt/Leanplum-iOS-SDK.svg?maxAge=3600" alt="Downloads" />
<a href="https://cocoapods.org/pods/Leanplum-iOS-SDK"><img src="https://img.shields.io/cocoapods/v/Leanplum-iOS-SDK.svg" alt="CocoaPods compatible" /></a>
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<img src="https://img.shields.io/badge/platform-tvOS-blue.svg?style=flat" alt="Platform tvOS" />
<a href="https://cocoapods.org/pods/Leanplum-iOS-SDK"><img src="https://img.shields.io/cocoapods/v/Leanplum-iOS-SDK.svg" alt="CocoaPods compatible" /></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
<a href="https://raw.githubusercontent.com/Leanplum/Leanplum-iOS-SDK/master/LICENSE"><img src="https://img.shields.io/badge/license-apache%202.0-blue.svg?style=flat" alt="License: Apache 2.0" /></a> 
</p>

# Leanplum-Apple-SDK
## Installation & Usage
- Please refer to: https://www.leanplum.com/docs#/setup/ios for how to setup Leanplum SDK in your project.
- To run the example project:
```bash
cd "Example/"
pod install
open "Leanplum-SDK.xcworkspace"
```
## Development Workflow
- We are using GitFlow branching model: https://github.com/nvie/gitflow
- We use the Conventional Changelog Commit Style for commit messages: https://github.com/commitizen/cz-cli
## Build the SDK
To build the sdk run:
```bash
cd "Example/"
pod install
cd -
./build.sh
```
## Contributing
Please follow the Conventional Changelog Commit Style and send a pull request to `develop` branch.
## License
See LICENSE file.
## Support
Leanplum does not support custom modifications to the SDK, without an approved pull request (PR). If you wish to include your changes, please fork the repo and send a PR to the develop branch. After the PR has been reviewed and merged into develop it will go into our regular release cycle which includes QA. Once QA has passed the PR will be available in master and your changes are now officialy supported by Leanplum.
