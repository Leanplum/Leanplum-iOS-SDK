// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Leanplum",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "Leanplum", targets: ["LeanplumTargetWrapper"]),
        .library(name: "LeanplumLocation", targets: ["LeanplumLocation"])
    ],
    dependencies: [
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk", from: "6.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "Leanplum",
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/6.3.0/Leanplum.xcframework.zip",
            checksum: "ec3705808fd7c05ee3d05cdf042be40db3642a894a7cb03b6018f1d56d328632"
        ),
        .target(
            name: "LeanplumLocation",
            dependencies: ["Leanplum"],
            path: "LeanplumSDKLocation",
            resources: [
                .copy("LeanplumSDKLocation/PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "LeanplumSDKLocation/include"
        ),
        .target(name: "LeanplumTargetWrapper",
                dependencies: ["Leanplum", .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")],
                path: "LeanplumTargetWrapper"
               )
    ]
)
