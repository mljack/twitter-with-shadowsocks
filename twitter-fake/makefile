all: build ipa

build:
	xcodebuild CONFIGURATION_BUILD_DIR=$$PWD/build clean build -project Twitter/Twitter.xcodeproj -scheme Twitter -configuration Realease -sdk iphoneos

ipa:
	xcrun -sdk iphoneos PackageApplication -v build/Twitter.app -o $$PWD/build/Twitter.ipa

.PHONY: build