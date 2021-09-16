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
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "LeanplumSDKSwift",
            dependencies: ["LeanplumSDKObjc"],
            path: "LeanplumSDK/LeanplumSDK/ClassesSwift"
            
        )
    ]
)
