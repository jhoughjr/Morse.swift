// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Morse.swift",
    platforms: [.macOS(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Morse",
            targets: ["Morse"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/jtodaone/jhoughjt/Morse.swift.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.

        .target(
            name: "Morse",
            dependencies: []),
        .testTarget(
            name: "MorseTests",
            dependencies: ["Morse"]
        ),
        .executableTarget(
            name: "morset",
            dependencies: [
                .product(name: "Morse", package: "Morse.swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),

            ]),
    ]
)
