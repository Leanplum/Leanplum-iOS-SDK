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
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/5.0.0-beta6/Leanplum.xcframework.zip",
            checksum: "e373f432b989f3e007fc4129920565dc5311a159d5959bf4bb63baf83cdf6339"
        ),
       .target(
           name: "LeanplumLocation",
           path: "LeanplumSDKLocation",
           publicHeadersPath: "LeanplumSDKLocation/include"
       )
    ]
)
