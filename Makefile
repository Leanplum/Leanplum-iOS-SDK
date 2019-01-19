####################################################################
#
# Rules used to build and release the SDK.
#
####################################################################

deploy:
	git tag `cat sdk-version.txt`; git push --tags
