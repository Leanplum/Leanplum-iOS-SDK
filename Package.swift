// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Leanplum",
    products: [
        .library(name: "Leanplum", targets: ["Leanplum"])
    ],
    targets: [
        .target(
            name: "Leanplum",
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
