#!/bin/bash
# Builds xcframeworks for MLKitDigitalInkRecognition from CocoaPod binary tarballs.
# Run from the repo root. Requires: lipo, ar, ranlib, xcodebuild, python3, curl, shasum.
#
# Usage: SIGNING_CERT="Apple Distribution: Your Team (TEAMID)" ./scripts/build.sh <dig-ver> <mdd-ver> <common-ver>
# Example: SIGNING_CERT="Apple Distribution: Jotit Inc (ABC123)" ./scripts/build.sh 7.0.0 9.0.0 13.0.0

set -euo pipefail

DIG_VERSION="${1:-7.0.0}"
MDD_VERSION="${2:-9.0.0}"
COMMON_VERSION="${3:-13.0.0}"

WORK_DIR="$(mktemp -d)"
OUTPUT_DIR="$(pwd)/xcframeworks"
mkdir -p "$OUTPUT_DIR"

echo "Working directory: $WORK_DIR"

# Re-tag the iOS platform byte (2) to iOS Simulator (7) in a Mach-O binary or ar archive.
# Handles both raw Mach-O objects (NEEDS_AR=true path) and ar archives (NEEDS_AR=false path).
retag_ios_to_simulator() {
    local INPUT="$1"
    local OUTPUT="$2"
    python3 - "$INPUT" "$OUTPUT" << 'PYEOF'
import sys, struct, os, subprocess, tempfile, shutil

AR_MAGIC = b'!<arch>\n'
MH_MAGIC_64 = 0xfeedfacf
LC_BUILD_VERSION = 0x32

def patch_macho(data):
    data = bytearray(data)
    if len(data) < 32 or struct.unpack_from('<I', data, 0)[0] != MH_MAGIC_64:
        return bytes(data)
    ncmds = struct.unpack_from('<I', data, 16)[0]
    off = 32
    for _ in range(ncmds):
        cmd = struct.unpack_from('<I', data, off)[0]
        csz = struct.unpack_from('<I', data, off + 4)[0]
        if csz == 0: break
        if cmd == LC_BUILD_VERSION and struct.unpack_from('<I', data, off + 8)[0] == 2:
            struct.pack_into('<I', data, off + 8, 7)
        off += csz
    return bytes(data)

src, dst = sys.argv[1], sys.argv[2]
raw = open(src, 'rb').read()

if raw[:8] == AR_MAGIC:
    # ar archive: extract members, patch each, re-archive
    tmp = tempfile.mkdtemp()
    try:
        subprocess.run(['ar', 'x', os.path.abspath(src)], cwd=tmp, check=True)
        for name in os.listdir(tmp):  # ar x may extract files with no permissions
            os.chmod(os.path.join(tmp, name), 0o644)
        for name in os.listdir(tmp):
            fp = os.path.join(tmp, name)
            with open(fp, 'rb') as f:
                content = f.read()
            patched = patch_macho(content)
            if patched != content:
                os.chmod(fp, 0o644)
                with open(fp, 'wb') as f:
                    f.write(patched)
        members = sorted(
            os.path.join(tmp, f) for f in os.listdir(tmp)
            if not f.startswith('__.')  # skip __.SYMDEF and __.SYMDEF SORTED
        )
        subprocess.run(['ar', 'r', os.path.abspath(dst)] + members, check=True)
        subprocess.run(['ranlib', os.path.abspath(dst)], check=True)
    finally:
        shutil.rmtree(tmp)
else:
    # Raw Mach-O object
    open(dst, 'wb').write(patch_macho(raw))
PYEOF
}

sign_xcframework() {
    local NAME="$1"
    local CERT="${SIGNING_CERT:-Apple Distribution}"
    echo "\n--- Signing frameworks inside $NAME.xcframework with: $CERT ---"
    find "$OUTPUT_DIR/$NAME.xcframework" -name "*.framework" -type d | while read -r fw; do
        codesign --force --sign "$CERT" "$fw"
    done
}

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

    # Copy framework structure (headers, modules, bundles, etc.) for both slices
    cp -r "$FRAMEWORK_PATH" "$DEV/"
    cp -r "$FRAMEWORK_PATH" "$SIM/"

    # Extract architecture slices from the fat CocoaPods binary
    lipo -thin arm64  "$FRAMEWORK_PATH/$NAME" -output "$SRC/arm64_raw"
    lipo -thin x86_64 "$FRAMEWORK_PATH/$NAME" -output "$SRC/x86_64_raw"

    # Re-tag arm64 from iOS -> iOS Simulator (patches LC_BUILD_VERSION in each Mach-O object)
    retag_ios_to_simulator "$SRC/arm64_raw" "$SRC/arm64_sim"

    if [ "$NEEDS_AR" = "true" ]; then
        # CocoaPods binary slices are raw Mach-O objects — wrap in ar archives
        ar r "$SRC/arm64_dev.a"  "$SRC/arm64_raw" && ranlib "$SRC/arm64_dev.a"
        ar r "$SRC/arm64_sim.a"  "$SRC/arm64_sim" && ranlib "$SRC/arm64_sim.a"
        ar r "$SRC/x86_64_sim.a" "$SRC/x86_64_raw" && ranlib "$SRC/x86_64_sim.a"
        cp "$SRC/arm64_dev.a" "$DEV/$NAME.framework/$NAME"
        lipo -create "$SRC/arm64_sim.a" "$SRC/x86_64_sim.a" -output "$SIM/$NAME.framework/$NAME"
    else
        # CocoaPods binary slices are already ar archives — use directly
        cp "$SRC/arm64_raw" "$DEV/$NAME.framework/$NAME"
        lipo -create "$SRC/arm64_sim" "$SRC/x86_64_raw" -output "$SIM/$NAME.framework/$NAME"
    fi

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

    rm -rf "$OUTPUT_DIR/$NAME.xcframework"
    xcodebuild -create-xcframework \
        -framework "$DEV/$NAME.framework" \
        -framework "$SIM/$NAME.framework" \
        -output "$OUTPUT_DIR/$NAME.xcframework"
    echo "Built: $OUTPUT_DIR/$NAME.xcframework"

    sign_xcframework "$NAME"
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

sign_xcframework "GoogleToolboxForMac"

echo "\n=== Zipping xcframeworks ==="
cd "$OUTPUT_DIR"
for fw in MLKitDigitalInkRecognition MLKitMDD MLKitCommon GoogleToolboxForMac; do
    zip -r "${fw}.xcframework.zip" "${fw}.xcframework" -q
    echo "$(shasum -a 256 ${fw}.xcframework.zip)  <- checksum"
done

rm -rf "$WORK_DIR"
echo "\nDone. Update Package.swift checksums with the values above, then:"
echo "  gh release create <version> $OUTPUT_DIR/*.xcframework.zip"
