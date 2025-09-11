// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LiteLog",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "LiteLog",
            targets: ["LiteLog"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Splash.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "LiteLog",
            dependencies: [
                .product(name: "Splash", package: "Splash")
            ],
            path: "Sources",
            exclude: ["Info.plist"],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT", 
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Info.plist"
                ])
            ])
    ]
)
