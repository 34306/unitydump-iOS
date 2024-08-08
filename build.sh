#!/bin/bash

set -e

cd "$(dirname "$0")"

CURRENT_DIR="$(pwd)"
APP_NAME=unitydump

rm -rf build
mkdir build
cd build

xcodebuild -project "$CURRENT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$CURRENT_DIR/build/DerivedDataApp" \
    -destination 'generic/platform=iOS' \
    clean build \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \

APP="$CURRENT_DIR/build/DerivedDataApp/Build/Products/Release-iphoneos/$APP_NAME.app"
TARGET_APP="$CURRENT_DIR/build/$APP_NAME.app"
cp -r "$APP" "$TARGET_APP"

codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

ldid -S"$CURRENT_DIR/entitlements.plist" "$TARGET_APP/$APP_NAME"

mkdir Payload
cp -r $APP_NAME.app Payload/$APP_NAME.app
zip -vr $APP_NAME.ipa Payload
rm -rf $APP_NAME.app
rm -rf Payload
rm -rf DerivedDataApp
cp $APP_NAME.ipa $APP_NAME.tipa