// swift-tools-version: 5.9

import PackageDescription

let releaseURL = "https://github.com/JotitIO/google-mlkit-digitalink-swiftpm/releases/download/1.2.7"

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
            checksum: "8d01d76ae08ba19e93b991857b3d7aedcaee3fd3e9ef97cb7a5257ff9cd816fc"
        ),
        .binaryTarget(
            name: "MLKitMDD",
            url: "\(releaseURL)/MLKitMDD.xcframework.zip",
            checksum: "edf95ecf06305409673d695f09c78699d39d16df9a0eb84c16cf9a0ada45d171"
        ),
        .binaryTarget(
            name: "MLKitCommon",
            url: "\(releaseURL)/MLKitCommon.xcframework.zip",
            checksum: "21daffedd47339a1280db3a7834179012a5df83445dd356d47003bdac1fd600f"
        ),
        .binaryTarget(
            name: "GoogleToolboxForMac",
            url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
            checksum: "801491781ae1bab9eef5d0ae2cf1da4b651e3cc5b576f0881ccd280854b6c117"
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
