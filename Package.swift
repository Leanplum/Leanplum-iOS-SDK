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
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk", from: "4.1.1")
    ],
    targets: [
        .binaryTarget(
            name: "Leanplum",
            //path: "Release/static/Leanplum.xcframework"
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/4.1.0/Leanplum.xcframework.zip",
            checksum: "8babd16ec7ebfc3f939bfe312ead4c3b16e4b2e3de5996cd920953ab1f725524"
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
