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