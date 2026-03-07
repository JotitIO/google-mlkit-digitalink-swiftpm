// swift-tools-version: 5.9

import PackageDescription

let releaseURL = "https://github.com/JotitIO/google-mlkit-digitalink-swiftpm/releases/download/1.1.0"

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
            checksum: "72a4478e390c558518e07e18b1ec8891a5aaeb38b849a6f0642c8a50f785de17"
        ),
        .binaryTarget(
            name: "MLKitMDD",
            url: "\(releaseURL)/MLKitMDD.xcframework.zip",
            checksum: "c80e7d371f399cbc0a9c40c9e54d90b0ca2a6110b73fdf23e6d4cdcb4b5ba2eb"
        ),
        .binaryTarget(
            name: "MLKitCommon",
            url: "\(releaseURL)/MLKitCommon.xcframework.zip",
            checksum: "f018f38657b3c3edce9cddf87c87a6373107e502e8ba6ad7506778fca1085d68"
        ),
        .binaryTarget(
            name: "GoogleToolboxForMac",
            url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
            checksum: "6e43977b67269b93bec41293c2ca23ace0ff971b0976cef853094929a5bca5ae"
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
