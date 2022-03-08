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
            url: "https://github.com/Leanplum/Leanplum-iOS-SDK/releases/download/4.1.0-beta1/Leanplum.xcframework.zip",
            checksum: "3b7b4d7310bfa847536569d259a6697ae6996ecc6c7ae144b1943f94838bf6b8"
        ),
       .target(
           name: "LeanplumLocation",
           path: "LeanplumSDKLocation",
           publicHeadersPath: "LeanplumSDKLocation/include"
       )
    ]
)
