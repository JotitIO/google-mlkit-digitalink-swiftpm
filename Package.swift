// swift-tools-version: 5.9

import PackageDescription

let releaseURL = "https://github.com/JotitIO/google-mlkit-digitalink-swiftpm/releases/download/1.2.4"

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
            checksum: "3480ea4970239c0b9f083e223924b5b7989d8ec492688a298986fd32b2b3c97d"
        ),
        .binaryTarget(
            name: "MLKitMDD",
            url: "\(releaseURL)/MLKitMDD.xcframework.zip",
            checksum: "99bf49a75dc807147c77f7754ae495b472060f8ed7c9c7051728fc18a48a7155"
        ),
        .binaryTarget(
            name: "MLKitCommon",
            url: "\(releaseURL)/MLKitCommon.xcframework.zip",
            checksum: "9f1a2647ce8e5c63f74abe6bf733d91b3a95a6154b906cfde91b68849d373dbf"
        ),
        .binaryTarget(
            name: "GoogleToolboxForMac",
            url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
            checksum: "f839e6425d7a7be1a60e0f9f7632e1c003b3f45e8822f40cfa0e5256974e4762"
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
