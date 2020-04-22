// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Leanplum",
    products: [
        .library(name: "Leanplum", targets: ["Leanplum"])
    ],
    targets: [
        .target(
        	name: "Leanplum", 
        	path: "Leanplum-SDK/Classes",
        	publicHeadersPath: "."
        )
    ]
)
