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

See `scripts/build.sh` for the build process.
