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
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/4.0.0-beta16/Leanplum.xcframework.zip",
            checksum: "075753a006bad2abb3245631ce92d83bd99099115d8ae1f101337f428b0ceb44"
        ),
       .target(
           name: "LeanplumLocation",
           path: "LeanplumSDKLocation",
           publicHeadersPath: "LeanplumSDKLocation/include"
       )
    ]
)
