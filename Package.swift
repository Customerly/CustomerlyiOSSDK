// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Customerly",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Customerly", targets: ["CustomerlySDK"])
    ],
    targets: [
        .target(
            name: "CustomerlySDK",
            path: "CustomerlySDK"
        )
    ]
)
