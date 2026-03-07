# google-mlkit-digitalink-swiftpm

Swift Package Manager wrapper for [Google MLKit DigitalInkRecognition](https://developers.google.com/ml-kit/vision/digital-ink-recognition). Since MLKit does not officially support SPM, this package re-packages the CocoaPod binary xcframeworks as SPM binary targets.

## Versions

| Package | MLKitDigitalInkRecognition | MLKitCommon | MLKitMDD |
|---------|---------------------------|-------------|----------|
| 1.0.0   | 7.0.0                     | 13.0.0      | 9.0.0    |

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

## How it works

The MLKit frameworks ship as CocoaPod `.framework` fat binaries (arm64 + x86_64). This package:

1. Slices each fat binary into separate `ios-arm64` (device) and `ios-x86_64-simulator` (simulator) slices
2. Wraps raw Mach-O objects in `ar` static archives (required for SPM binary targets)
3. Packages each as a proper `.xcframework` with an `Info.plist`
4. Hosts the xcframeworks as GitHub release assets
5. Declares SPM package dependencies for the shared Google infrastructure libraries that the MLKit binaries link against at compile time

The approach is identical to [d-date/google-mlkit-swiftpm](https://github.com/d-date/google-mlkit-swiftpm) (which covers other MLKit APIs but not DigitalInkRecognition).

## Simulator support

The included xcframeworks contain an `ios-x86_64-simulator` slice only (matching the original CocoaPod distribution). **Apple Silicon Mac simulators (arm64) are not supported** — use a physical device or run the simulator under Rosetta.

## Updating to a new MLKit version

See `scripts/build.sh` for the build process.
