// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LeanplumiOSSDK",
    products: [
        .library(name: "LeanplumiOSSDK", targets: ["LeanplumiOSSDK"])
    ],
    targets: [
        .target(
            name: "LeanplumiOSSDK",
            path: "LeanplumSDK/LeanplumSDK",
            exclude: [
                "Supporting Files/Info.plist"
            ],
            resources: [
                .process("Resources")
            ],
            publicHeadersPath: "include"
        )
    ]
)
