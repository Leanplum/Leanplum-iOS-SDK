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
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/4.0.0-beta13/Leanplum.xcframework.zip",
            checksum: "877d25535bf5d635ebae0d07c3d2ef3f014d490a661263f97f9c1a8c6f19ed20"
        ),
       .target(
           name: "LeanplumLocation",
           path: "LeanplumSDKLocation",
           publicHeadersPath: "LeanplumSDKLocation/include"
       )
    ]
)
