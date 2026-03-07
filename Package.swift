// swift-tools-version: 5.9

import PackageDescription

let releaseURL = "https://github.com/JotitIO/google-mlkit-digitalink-swiftpm/releases/download/1.0.0"

let package = Package(
    name: "GoogleMLKitDigitalInkRecognition",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "MLKitDigitalInkRecognition",
            targets: [
                "MLKitDigitalInkRecognition",
                "MLKitMDD",
                "MLKitCommon",
                "GoogleToolboxForMac",
                "Common",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/google/promises.git", exact: "2.4.0"),
        .package(url: "https://github.com/google/GoogleDataTransport.git", exact: "10.1.0"),
        .package(url: "https://github.com/google/GoogleUtilities.git", exact: "8.1.0"),
        .package(url: "https://github.com/google/gtm-session-fetcher.git", exact: "3.5.0"),
        .package(url: "https://github.com/firebase/nanopb.git", exact: "2.30910.0"),
    ],
    targets: [
        .binaryTarget(
            name: "MLKitDigitalInkRecognition",
            url: "\(releaseURL)/MLKitDigitalInkRecognition.xcframework.zip",
            checksum: "5e849ac782c0d5652308655235daef5a5f71db4cdbe3533c6d23bff059da0c04"
        ),
        .binaryTarget(
            name: "MLKitMDD",
            url: "\(releaseURL)/MLKitMDD.xcframework.zip",
            checksum: "63788b19ed6e1e7e241fbaea6013c97d58a5bfcc1f09415a230ee951a241f8e9"
        ),
        .binaryTarget(
            name: "MLKitCommon",
            url: "\(releaseURL)/MLKitCommon.xcframework.zip",
            checksum: "0d9020d7a05dbb8c333a7b30ddffb49321378d9e58638b7f675e4fde069399b3"
        ),
        .binaryTarget(
            name: "GoogleToolboxForMac",
            url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
            checksum: "c93924c3ac7161d58d5d207590c3aecca4e23e202e8c2ebd14fddfd95862a341"
        ),
        .target(
            name: "Common",
            dependencies: [
                "MLKitCommon",
                "GoogleToolboxForMac",
                .product(name: "FBLPromises", package: "promises"),
                .product(name: "GoogleDataTransport", package: "GoogleDataTransport"),
                .product(name: "GULAppDelegateSwizzler", package: "GoogleUtilities"),
                .product(name: "GULEnvironment", package: "GoogleUtilities"),
                .product(name: "GULLogger", package: "GoogleUtilities"),
                .product(name: "GULMethodSwizzler", package: "GoogleUtilities"),
                .product(name: "GULNSData", package: "GoogleUtilities"),
                .product(name: "GULNetwork", package: "GoogleUtilities"),
                .product(name: "GULReachability", package: "GoogleUtilities"),
                .product(name: "GULUserDefaults", package: "GoogleUtilities"),
                .product(name: "GTMSessionFetcher", package: "gtm-session-fetcher"),
                .product(name: "nanopb", package: "nanopb"),
            ],
            path: "Sources/Common"
        ),
    ]
)
