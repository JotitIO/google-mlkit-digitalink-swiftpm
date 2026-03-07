#!/bin/bash
# Builds xcframeworks for MLKitDigitalInkRecognition from CocoaPod binary tarballs.
# Run from the repo root. Requires: lipo, ar, ranlib, xcodebuild, curl, shasum.
#
# Usage: ./scripts/build.sh <MLKitDigitalInkRecognition-version> <MLKitMDD-version> <MLKitCommon-version>
# Example: ./scripts/build.sh 7.0.0 9.0.0 13.0.0

set -euo pipefail

DIG_VERSION="${1:-7.0.0}"
MDD_VERSION="${2:-9.0.0}"
COMMON_VERSION="${3:-13.0.0}"

WORK_DIR="$(mktemp -d)"
OUTPUT_DIR="$(pwd)/xcframeworks"
mkdir -p "$OUTPUT_DIR"

echo "Working directory: $WORK_DIR"

build_xcframework() {
    local NAME="$1"
    local TARBALL_URL="$2"
    local NEEDS_AR="$3"

    echo "\n=== Building $NAME.xcframework ==="
    local SRC="$WORK_DIR/$NAME"
    mkdir -p "$SRC"
    echo "Downloading $NAME..."
    curl -sL "$TARBALL_URL" -o "$SRC/$NAME.tar.gz"
    tar -xzf "$SRC/$NAME.tar.gz" -C "$SRC"

    local FRAMEWORK_PATH="$SRC/Frameworks/$NAME.framework"
    local DEV="$SRC/iphoneos"
    local SIM="$SRC/iphonesimulator"
    mkdir -p "$DEV" "$SIM"

    cp -r "$FRAMEWORK_PATH" "$DEV/"
    cp -r "$FRAMEWORK_PATH" "$SIM/"

    lipo -thin arm64  "$FRAMEWORK_PATH/$NAME" -output "$DEV/$NAME.framework/$NAME"
    lipo -thin x86_64 "$FRAMEWORK_PATH/$NAME" -output "$SIM/$NAME.framework/$NAME"

    # Add Info.plist if missing
    for DIR in "$DEV/$NAME.framework" "$SIM/$NAME.framework"; do
        if [ ! -f "$DIR/Info.plist" ]; then
            cat > "$DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>com.google.mlkit.${NAME}</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>MinimumOSVersion</key><string>15.5</string>
</dict></plist>
PLIST
        fi
    done

    # Wrap raw Mach-O objects in ar static archive
    if [ "$NEEDS_AR" = "true" ]; then
        for DIR in "$DEV/$NAME.framework" "$SIM/$NAME.framework"; do
            pushd "$DIR" > /dev/null
            mv "$NAME" "${NAME}.o"
            ar r "$NAME" "${NAME}.o"
            ranlib "$NAME"
            rm "${NAME}.o"
            popd > /dev/null
        done
    fi

    rm -rf "$OUTPUT_DIR/$NAME.xcframework"
    xcodebuild -create-xcframework \
        -framework "$DEV/$NAME.framework" \
        -framework "$SIM/$NAME.framework" \
        -output "$OUTPUT_DIR/$NAME.xcframework"
    echo "Built: $OUTPUT_DIR/$NAME.xcframework"
}

# Fetch podspec source URL
podspec_url() {
    local POD="$1"
    local VERSION="$2"
    curl -s "https://trunk.cocoapods.org/api/v1/pods/$POD/versions/$VERSION" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data_url'])" \
        | xargs curl -s \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['source']['http'])"
}

DIG_URL=$(podspec_url MLKitDigitalInkRecognition "$DIG_VERSION")
MDD_URL=$(podspec_url MLKitMDD "$MDD_VERSION")
COMMON_URL=$(podspec_url MLKitCommon "$COMMON_VERSION")

build_xcframework "MLKitDigitalInkRecognition" "$DIG_URL" "true"
build_xcframework "MLKitMDD" "$MDD_URL" "true"
build_xcframework "MLKitCommon" "$COMMON_URL" "false"

# GoogleToolboxForMac needs CocoaPods build — reuse from d-date/google-mlkit-swiftpm
# matching the MLKitCommon version in use
DDATE_RELEASE=$([ "$COMMON_VERSION" = "14.0.0" ] && echo "9.0.0" || echo "8.0.0")
echo "\n=== Downloading GoogleToolboxForMac from d-date/google-mlkit-swiftpm $DDATE_RELEASE ==="
curl -sL "https://github.com/d-date/google-mlkit-swiftpm/releases/download/$DDATE_RELEASE/GoogleToolboxForMac.xcframework.zip" \
    -o "$OUTPUT_DIR/GoogleToolboxForMac.xcframework.zip"
unzip -qo "$OUTPUT_DIR/GoogleToolboxForMac.xcframework.zip" -d "$OUTPUT_DIR"

echo "\n=== Zipping xcframeworks ==="
cd "$OUTPUT_DIR"
for fw in MLKitDigitalInkRecognition MLKitMDD MLKitCommon GoogleToolboxForMac; do
    zip -r "${fw}.xcframework.zip" "${fw}.xcframework" -q
    echo "$(shasum -a 256 ${fw}.xcframework.zip)  <- checksum"
done

rm -rf "$WORK_DIR"
echo "\nDone. Update Package.swift checksums with the values above, then:"
echo "  gh release create <version> $OUTPUT_DIR/*.xcframework.zip"
