####################################################################
#
# Rules used to build and release the SDK.
#
####################################################################

spm:
	sh Tools/spm.sh

updateVersion:
	sed -i '' -e "s/#define LEANPLUM_SDK_VERSION @.*/#define LEANPLUM_SDK_VERSION @\"`cat sdk-version.txt`\"/g" "./LeanplumSDK/LeanplumSDK/Classes/Internal/LPConstants.h"

tagCommit:
	git add LeanplumSDK/LeanplumSDK/Classes/Internal/LPConstants.h; git commit -am 'update version'; git tag `cat sdk-version.txt`; git push; git push origin `cat sdk-version.txt`

deploy: updateVersion tagCommit
