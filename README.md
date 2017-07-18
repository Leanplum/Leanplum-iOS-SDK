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
