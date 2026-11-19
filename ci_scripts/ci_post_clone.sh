#!/bin/sh
# Xcode Cloud runs this right after it clones the repo.
set -e

# Sova's wave effect has Metal shaders; Xcode 26 ships the compiler separately.
xcodebuild -downloadComponent MetalToolchain || echo "Metal Toolchain already present"

# Every Xcode Cloud build gets a higher build number than the last one.
if [ -n "$CI_BUILD_NUMBER" ]; then
  sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" \
    "$CI_PRIMARY_REPOSITORY_PATH/Sova.xcodeproj/project.pbxproj"
  echo "Build number set to $CI_BUILD_NUMBER"
fi
