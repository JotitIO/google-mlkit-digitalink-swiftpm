# google-mlkit-digitalink-swiftpm

Swift Package Manager wrapper for [Google MLKit DigitalInkRecognition](https://developers.google.com/ml-kit/vision/digital-ink-recognition). Since MLKit does not officially support SPM, this package re-packages the CocoaPod binary xcframeworks as SPM binary targets.

## Versions

| Package | MLKitDigitalInkRecognition | MLKitCommon | MLKitMDD |
|---------|---------------------------|-------------|----------|
| 1.2.1   | 7.0.0                     | 13.0.0      | 9.0.0    |
| 1.0.0   | 7.0.0                     | 13.0.0      | 9.0.0    |

**Use 1.2.1 or later.** Earlier releases are missing arm64 simulator support, correct `CFBundleExecutable` entries, and the `MLKStroke`/`MLKStrokePoint` stubs.

## Usage

In Xcode: **File → Add Package Dependencies**, enter:
```
https://github.com/JotitIO/google-mlkit-digitalink-swiftpm
```
Select the `MLKitDigitalInkRecognition` product.

Then import as normal:
```swift
import MLKitDigitalInkRecognition
```

### Required: linker flag

Because the MLKit frameworks are **static libraries**, Objective-C categories they define (e.g. `NSError` extensions used internally) will be silently dropped by the linker unless you force-load them. Add `-ObjC` to `OTHER_LDFLAGS` in your project's xcconfig or build settings:

```
OTHER_LDFLAGS = $(inherited) -ObjC
```

### Required: copy resource bundle to app root

MLKit locates `MLKitDigitalInkRecognition_resource.bundle` (which contains the model download manifest) via `[NSBundle mainBundle]` — because the framework binary is statically linked, not dynamically loaded. SPM embeds the bundle inside `Frameworks/MLKitDigitalInkRecognition.framework/` but does **not** copy it to the app root. CocoaPods used to handle this automatically via its "Copy Pods Resources" phase.

Add a **Run Script** build phase to your app target (after the Resources phase):

```sh
BUNDLE_SOURCE="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/MLKitDigitalInkRecognition.framework/MLKitDigitalInkRecognition_resource.bundle"
BUNDLE_DEST="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/MLKitDigitalInkRecognition_resource.bundle"
if [ -d "${BUNDLE_SOURCE}" ]; then
    cp -r "${BUNDLE_SOURCE}" "${BUNDLE_DEST}"
fi
```

This copies the resource bundle to the app root while leaving the original inside the embedded framework, so it is accessible from both locations.

## How it works

The MLKit frameworks ship as CocoaPod `.framework` fat binaries (arm64 + x86_64). This package:

1. Slices each fat binary into separate `ios-arm64` (device) and `ios-x86_64-simulator` (simulator) slices
2. Wraps raw Mach-O objects in `ar` static archives (required for SPM binary targets)
3. Packages each as a proper `.xcframework` with an `Info.plist` (including the required `CFBundleExecutable` key)
4. Hosts the xcframeworks as GitHub release assets
5. Declares SPM package dependencies for the shared Google infrastructure libraries that the MLKit binaries link against at compile time

The approach is identical to [d-date/google-mlkit-swiftpm](https://github.com/d-date/google-mlkit-swiftpm) (which covers other MLKit APIs but not DigitalInkRecognition).

## Simulator support (arm64)

The xcframeworks include an `ios-arm64_x86_64-simulator` slice. The **arm64 simulator slice is a stub** — all public classes compile and link correctly, but recognition always returns an error and `ModelManager.isModelDownloaded(_:)` always returns `false`. This is intentional: the feature requires a downloaded model and network access, neither of which are meaningful in the simulator.

The stub implements the full public API surface:

| Class | Behaviour on arm64 simulator |
|-------|------------------------------|
| `ModelManager` | `isModelDownloaded` → `false`; `download` → no-op |
| `DigitalInkRecognizer` | `recognize` → calls completion with error |
| `DigitalInkRecognitionModel` | init succeeds, properties return empty values |
| `Stroke`, `StrokePoint`, `Ink` | init and property access work normally |
| All `DigitalInkRecognitionModelIdentifier` constants | return `nil` |

Gate feature usage on `ModelManager.modelManager().isModelDownloaded(model)` and the behaviour is correct on both device and simulator with no `#if targetEnvironment(simulator)` guards needed in app code.

## Updating to a new MLKit version

Follow these steps when a new `MLKitDigitalInkRecognition` / `MLKitCommon` / `MLKitMDD` CocoaPod version is released.

### 1. Build the device + x86_64-simulator xcframeworks

```bash
./scripts/build.sh <MLKitDigitalInkRecognition-version> <MLKitMDD-version> <MLKitCommon-version>
# e.g. ./scripts/build.sh 8.0.0 10.0.0 14.0.0
```

This downloads the CocoaPod tarballs, slices the fat binaries, wraps Mach-O objects in `ar` archives, and produces zipped xcframeworks in `xcframeworks/`. It also prints the SHA-256 checksums you will need later.

### 2. Add `CFBundleExecutable` to any framework Info.plist that is missing it

The installer requires this key. `MLKitCommon` and `GoogleToolboxForMac` include it already; `MLKitDigitalInkRecognition` and `MLKitMDD` do not. Run for any that are missing it:

```bash
plutil -insert CFBundleExecutable -string "MLKitDigitalInkRecognition" \
  xcframeworks/MLKitDigitalInkRecognition.xcframework/ios-arm64/MLKitDigitalInkRecognition.framework/Info.plist
plutil -insert CFBundleExecutable -string "MLKitMDD" \
  xcframeworks/MLKitMDD.xcframework/ios-arm64/MLKitMDD.framework/Info.plist
# also for the x86_64-simulator slices
```

### 3. Check for public API changes

Compare the new version's headers (in `xcframeworks/MLKitDigitalInkRecognition.xcframework/ios-arm64/MLKitDigitalInkRecognition.framework/Headers/`) against the current stub in `stubs/MLKitStub.m`. Look for:

- New classes that app code might reference
- Renamed initializers or methods
- New classes in `MLKitCommon` headers (`stubs/MLKitCommonStub.m`) such as new `ModelManager` methods

### 4. Update the arm64 simulator stubs if needed

The stubs live in `stubs/MLKitStub.m` (for `MLKitDigitalInkRecognition`) and `stubs/MLKitCommonStub.m` (for `MLKitCommon`). Add any new public classes or methods as no-ops following the existing pattern, then recompile:

```bash
# MLKitDigitalInkRecognition stub
xcrun --sdk iphonesimulator clang \
  -arch arm64 -mios-simulator-version-min=16.0 -fobjc-arc \
  -c stubs/MLKitStub.m -o stubs/MLKitStub.o

# MLKitCommon stub
xcrun --sdk iphonesimulator clang \
  -arch arm64 -mios-simulator-version-min=16.0 -fobjc-arc \
  -c stubs/MLKitCommonStub.m -o stubs/MLKitCommonStub.o

# MLKitMDD and GoogleToolboxForMac use empty stubs
xcrun --sdk iphonesimulator clang \
  -arch arm64 -mios-simulator-version-min=16.0 \
  -c stubs/empty.m -o stubs/empty.o

xcrun --sdk iphonesimulator ar rcs stubs/libMLKitDigitalInkRecognition-arm64sim.a stubs/MLKitStub.o
xcrun --sdk iphonesimulator ar rcs stubs/libMLKitCommon-arm64sim.a stubs/MLKitCommonStub.o
xcrun --sdk iphonesimulator ar rcs stubs/libMLKitMDD-arm64sim.a stubs/empty.o
```

### 5. Build fat simulator binaries and combine into xcframeworks

For each framework: combine the existing `ios-x86_64-simulator` binary with the new arm64 stub using `lipo`, then rebuild the xcframework with both slices.

```bash
# Example for MLKitDigitalInkRecognition
xcrun lipo -create \
  xcframeworks/MLKitDigitalInkRecognition.xcframework/ios-x86_64-simulator/MLKitDigitalInkRecognition.framework/MLKitDigitalInkRecognition \
  stubs/libMLKitDigitalInkRecognition-arm64sim.a \
  -output sim-combined/MLKitDigitalInkRecognition

# Copy the combined binary into a simulator framework bundle (copy headers, Info.plist
# from the x86_64-simulator slice first, then replace the binary)

xcodebuild -create-xcframework \
  -framework xcframeworks/MLKitDigitalInkRecognition.xcframework/ios-arm64/MLKitDigitalInkRecognition.framework \
  -framework sim-combined/MLKitDigitalInkRecognition.framework \
  -output xcframeworks_final/MLKitDigitalInkRecognition.xcframework
```

Repeat for `MLKitCommon`, `MLKitMDD`, and `GoogleToolboxForMac` (for GoogleToolboxForMac, check whether the new d-date release already includes arm64 simulator — if so, use it directly).

Re-zip each xcframework and record the SHA-256 checksums:

```bash
cd xcframeworks_final
for fw in MLKitDigitalInkRecognition MLKitCommon MLKitMDD GoogleToolboxForMac; do
  zip -qr "${fw}.xcframework.zip" "${fw}.xcframework"
  shasum -a 256 "${fw}.xcframework.zip"
done
```

### 6. Create a new GitHub release

```bash
gh release create <new-version> \
  --repo JotitIO/google-mlkit-digitalink-swiftpm \
  --title "<new-version>" \
  xcframeworks_final/*.xcframework.zip
```

### 7. Update Package.swift and this README

In `Package.swift`, update `releaseURL` to point to the new version tag and replace the four `checksum:` values with the SHA-256 values from step 5.

Update the versions table in this README.

Commit, push to `main`, then move the version tag to the new `Package.swift` commit:

```bash
git add Package.swift README.md
git commit -m "Update to <new-version>"
git push
NEW_SHA=$(git rev-parse HEAD)
gh api --method PATCH repos/JotitIO/google-mlkit-digitalink-swiftpm/git/refs/tags/<new-version> \
  --field sha="$NEW_SHA" --field force=true
```
