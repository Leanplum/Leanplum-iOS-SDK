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
            url: "https://storage.googleapis.com/leanplum-multi/Nikola/Leanplum-poc.xcframework.zip",
            checksum: "45a64c180522d62ab72e6ace1902a19eeff5e7a24b777107ad188c3e0a3037ff"
    )]
)
