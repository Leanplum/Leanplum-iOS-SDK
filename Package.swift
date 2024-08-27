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
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk", from: "7.0.1")
    ],
    targets: [
        .binaryTarget(
            name: "Leanplum",
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/6.5.0-beta2/Leanplum.xcframework.zip",
            checksum: "2fc5acb238dc0c67a0fb3dab52be9c5a66758fd7b57fe697e797fa8adc122c9c"
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
