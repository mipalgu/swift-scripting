// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scripting",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Scripting",
            targets: ["Scripting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-system", from: "1.2.1"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Scripting",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
            ]),
        .testTarget(
            name: "ScriptingTests",
            dependencies: ["Scripting"]),
    ]
)
