#!/bin/bash

set -e

BUILD_DIR=build
TARGET_DMG=SunSynkTray.dmg

echo " |- Cleaning build directory"
rm -Rf $BUILD_DIR
echo " |- Removing existing .dmg"
rm SunSynkTray.dmg

echo " |- Building project"
xcodebuild clean archive -project "sunsynktray.xcodeproj" -scheme "sunsynktray" -configuration "Release" -destination "generic/platform=macOS,name=Any Mac" -archivePath $BUILD_DIR/SunSynkTray.xcarchive

echo " |- Preparing DMG working directory"
mkdir $BUILD_DIR/dmg
cp -r $BUILD_DIR/SunSynkTray.xcarchive/Products/Applications/sunsynktray.app $BUILD_DIR/dmg/SunSynkTray.app
ln -s /Applications $BUILD_DIR/dmg/Applications

echo " |- Building .dmg"
hdiutil create -volname "SunSynkTray" -srcfolder $BUILD_DIR/dmg -ov -format UDZO $TARGET_DMG

echo " |- Done"
