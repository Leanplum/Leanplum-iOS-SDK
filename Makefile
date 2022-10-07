####################################################################
#
# Rules used to build and release the SDK.
#
####################################################################

spm:
	sh Tools/spm.sh

updateVersion:
	sed -i '' -e "s/#define LEANPLUM_SDK_VERSION @.*/#define LEANPLUM_SDK_VERSION @\"`cat sdk-version.txt`\"/g" "./LeanplumSDK/LeanplumSDK/Classes/Internal/LPConstants.h";\
	minVersion=5.0.0; version=`cat sdk-version.txt`;\
	if [[ "$$version" != *"beta"* ]]; then \
		sed -i '' -e "s/s.dependency 'Leanplum-iOS-SDK', .*/s.dependency 'Leanplum-iOS-SDK', \"~> $$minVersion\"/g" "./Leanplum-iOS-Location.podspec";\
		sed -i '' -e "s/s.dependency 'Leanplum-iOS-SDK', .*/s.dependency 'Leanplum-iOS-SDK', \"~> $$minVersion\"/g" "./Leanplum-iOS-LocationAndBeacons.podspec";\
	else \
		sed -i '' -e "s/s.dependency 'Leanplum-iOS-SDK', .*/s.dependency 'Leanplum-iOS-SDK', \"~> $$minVersion-beta\"/g" "./Leanplum-iOS-Location.podspec";\
		sed -i '' -e "s/s.dependency 'Leanplum-iOS-SDK', .*/s.dependency 'Leanplum-iOS-SDK', \"~> $$minVersion-beta\"/g" "./Leanplum-iOS-LocationAndBeacons.podspec";\
	fi;

tagCommit:
	git add LeanplumSDK/LeanplumSDK/Classes/Internal/LPConstants.h; git commit -am 'update version'; git tag `cat sdk-version.txt`; git push; git push origin `cat sdk-version.txt`

deploy: updateVersion tagCommit
