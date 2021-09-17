// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LeanplumSDK",
    products: [
        .library(name: "LeanplumSDK", targets: ["LeanplumSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "LeanplumSDK",
            path: "binary/Leanplum.xcframework"
    )]
)
