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
    targets: [
        .executableTarget(
            name: "LiteLog",
            path: "Sources",
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
