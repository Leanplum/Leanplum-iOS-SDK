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
            path: "Leanplum-SDK",
            exclude: [
                "LeanplumSDK_iOS-Info.plist",
                "LeanplumSDK_tvOS-Info.plist"
            ],
            resources: [
                .process("Resources")
            ],
            publicHeadersPath: "include"
        )
    ]
)
