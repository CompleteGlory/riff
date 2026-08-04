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

# Belt and braces: pubspec.yaml already pins enable-swift-package-manager to
# false, but a fresh Flutter clone defaults it to ON, and Xcode Cloud runs
# xcodebuild with automatic package resolution disabled — so any SPM
# integration attempt dies demanding a checked-in Package.resolved.
flutter config --no-enable-swift-package-manager

flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# CFBundleVersion must be unique and increasing for every TestFlight upload.
# pubspec does carry a +buildNumber (it is Android's versionCode), but it only
# changes when the version does, so two TestFlight uploads of the same version
# would collide. Xcode Cloud's CI_BUILD_NUMBER increments per build, so use it
# as the build number and keep pubspec's version as the user-visible one.
# Falls back to 1 when the script is run outside Xcode Cloud.
BUILD_NUMBER="${CI_BUILD_NUMBER:-1}"

# Writes ios/Flutter/Generated.xcconfig pointing at the production entrypoint
# (there is no lib/main.dart — only main_development.dart/main_production.dart)
# without compiling anything; xcodebuild does the actual build afterwards.
# --no-codesign: during ci_post_clone no signing certificates are installed
# yet (Xcode Cloud injects signing at archive time), so skip Flutter's
# code-signing checks.
# --dart-define=SPOTIFY_CLIENT_ID is NOT optional: SpotifyAuthService reads the
# client id with String.fromEnvironment at compile time and falls back to an
# empty string, and the assert that would catch that is stripped from release
# builds. Without it "Connect Spotify" fails silently in TestFlight. The define
# survives --config-only because Flutter encodes it into Generated.xcconfig as
# DART_DEFINES, which xcodebuild then compiles with. It is a public PKCE client
# id, not a secret — see CLAUDE.md.
flutter build ios --config-only --release --no-codesign \
  --flavor production -t lib/main_production.dart \
  --build-number="$BUILD_NUMBER" \
  --dart-define=SPOTIFY_CLIENT_ID="${SPOTIFY_CLIENT_ID:-5bf7c19bb7b84c8cb8af0128fa7c59eb}"

cd ios
pod install

exit 0
