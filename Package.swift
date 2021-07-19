// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LeanplumSDK",
    products: [
        .library(name: "LeanplumSDK", targets: ["LeanplumSDK"])
    ],
    targets: [
        .target(
            name: "LeanplumSDK",
            path: "LeanplumSDK/LeanplumSDK",
            exclude: [
                "Supporting Files/Info.plist"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
