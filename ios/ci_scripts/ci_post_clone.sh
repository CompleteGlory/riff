#!/bin/sh
# Xcode Cloud post-clone setup.
#
# Xcode Cloud starts from a clean clone, but several files the Xcode build
# depends on are gitignored build products:
#   - ios/Flutter/Generated.xcconfig            (written by `flutter pub get` /
#     `flutter build ios --config-only`; included by Release.xcconfig)
#   - ios/Pods/** including the Pods-Runner *.xcfilelist files (written by
#     `pod install`)
# Without this script the build fails with "could not find included file
# 'Generated.xcconfig'" and "Unable to load contents of file list:
# .../Pods-Runner-*-Release-Production-*.xcfilelist".
set -e
set -x

# Pin the same Flutter revision as the dev machine (`flutter --version` →
# "Framework revision"). Update this hash when you upgrade Flutter locally.
FLUTTER_REVISION=041dc6a9a2d93d3ef9bc2994fd08545903207aee

# CocoaPods must be available BEFORE `flutter build ios --config-only`,
# because that command runs `pod install` internally.
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi
pod --version

# Blob-less clone: full history + tags (needed for Flutter's version
# detection, which `flutter pub get` uses to check pubspec constraints)
# without downloading every historical file.
git clone --filter=blob:none https://github.com/flutter/flutter.git "$HOME/flutter"
git -C "$HOME/flutter" checkout "$FLUTTER_REVISION"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# Writes ios/Flutter/Generated.xcconfig pointing at the production entrypoint
# (there is no lib/main.dart — only main_development.dart/main_production.dart)
# without compiling anything; xcodebuild does the actual build afterwards.
# --no-codesign: during ci_post_clone no signing certificates are installed
# yet (Xcode Cloud injects signing at archive time), so skip Flutter's
# code-signing checks.
flutter build ios --config-only --release --no-codesign --flavor production -t lib/main_production.dart

cd ios
pod install

exit 0
