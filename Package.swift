// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "CustomerlySDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "CustomerlySDK", targets: ["CustomerlySDK"])
    ],
    targets: [
        .target(
            name: "CustomerlySDK",
            path: "CustomerlySDK"
        )
    ]
)
