// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Leanplum",
    products: [
        .library(name: "Leanplum", targets: ["Leanplum"]),
        .library(name: "LeanplumLocation", targets: ["LeanplumLocation"])
    ],
    targets: [
        .binaryTarget(
            name: "Leanplum",
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/5.0.0-beta10/Leanplum.xcframework.zip",
            checksum: "6cebb61fbceb512019441e3d8a9ef1b8c4241476cd212bfecc86ab2c0256f252"
        ),
       .target(
           name: "LeanplumLocation",
           path: "LeanplumSDKLocation",
           publicHeadersPath: "LeanplumSDKLocation/include"
       )
    ]
)
