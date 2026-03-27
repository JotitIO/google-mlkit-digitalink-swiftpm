// swift-tools-version: 5.9

import PackageDescription

let releaseURL = "https://github.com/JotitIO/google-mlkit-digitalink-swiftpm/releases/download/1.2.2"

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
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", exact: "2.6.0"),
    ],
    targets: [
        .binaryTarget(
            name: "MLKitDigitalInkRecognition",
            url: "\(releaseURL)/MLKitDigitalInkRecognition.xcframework.zip",
            checksum: "91e94369f9327936131ba16adfebb2cadac0bcdc34db96e702d15da2badc4be6"
        ),
        .binaryTarget(
            name: "MLKitMDD",
            url: "\(releaseURL)/MLKitMDD.xcframework.zip",
            checksum: "e14ef763708ce68e82cdec57799bc72d8d71414a2b9adceca4514709b32abcfd"
        ),
        .binaryTarget(
            name: "MLKitCommon",
            url: "\(releaseURL)/MLKitCommon.xcframework.zip",
            checksum: "85e46939f38daf2c01424450fd3ccc79d865c086580e9cbd8fee46583969d84e"
        ),
        .binaryTarget(
            name: "GoogleToolboxForMac",
            url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
            checksum: "5223c9aba0fc96ce6bd3ccee0164ffd69956fbc50560c7a1531fdcaba8060ee1"
        ),
        .target(
            name: "Common",
            dependencies: [
                "MLKitCommon",
                "GoogleToolboxForMac",
                .product(name: "ZipArchive", package: "ZipArchive"),
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
