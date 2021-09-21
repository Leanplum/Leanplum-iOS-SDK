// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Leanplum",
    products: [
        .library(name: "Leanplum", targets: ["Leanplum"])
    ],
    targets: [
        .binaryTarget(
            name: "Leanplum",
            url: "github/Leanplum.xcframework.zip";
            checksum: "checksum";
        )
    ]
)
