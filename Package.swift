// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LeanplumSDK",
    products: [
        .library(name: "LeanplumSDK", targets: ["LeanplumSDKObjc", "LeanplumSDKSwift"])
    ],
    targets: [
        .target(
            name: "LeanplumSDKObjc",
            path: "LeanplumSDK/LeanplumSDK/Classes",
            resources: [
                .process("Resources")
            ],
            publicHeadersPath: "include"
        )
        .target(
            name: "LeanplumSDKSwift",
            path: "LeanplumSDK/LeanplumSDK/ClassesSwift",
            resources: [
                .process("Resources")
            ],
            publicHeadersPath: "include"
        )
    ]
)
