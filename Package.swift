// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Hieroglyphs",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/mchakravarty/CodeEditorView", from: "0.15.4"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Hieroglyphs",
            dependencies: [
                .product(name: "CodeEditorView", package: "CodeEditorView"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Yams", package: "Yams")
            ],
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "HieroglyphsTests",
            dependencies: ["Hieroglyphs"]
        )
    ]
)
