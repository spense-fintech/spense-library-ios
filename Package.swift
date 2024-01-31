// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spense-library-ios",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "spense-library-ios",
            targets: ["spense-library-ios"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/TakeScoop/SwiftyRSA.git", from: "1.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "spense-library-ios",
        dependencies: ["SwiftyRSA"]),
        .testTarget(
            name: "spense-library-iosTests",
            dependencies: ["spense-library-ios"]),
    ]
)
