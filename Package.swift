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
        .package(url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/6.0.0-beta4/Leanplum.xcframework.zip",
    ],
    targets: [
        .binaryTarget(
            name: "Leanplum",
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/5.0.0/Leanplum.xcframework.zip",
            checksum: "ff4c103f3c0775266a196bcc11d502511a875c15778de8ce9ac6c502a0d5d39b"
        ),
        .target(
            name: "LeanplumLocation",
            dependencies: ["Leanplum"],
            path: "LeanplumSDKLocation",
            publicHeadersPath: "LeanplumSDKLocation/include"
        ),
        .target(name: "LeanplumTargetWrapper",
                dependencies: ["Leanplum", .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")],
                path: "LeanplumTargetWrapper"
               )
    ]
)
