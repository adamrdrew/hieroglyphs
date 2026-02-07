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
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1")
    ],
    targets: [
        .executableTarget(
            name: "Hieroglyphs",
            dependencies: [
                .product(name: "CodeEditorView", package: "CodeEditorView"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ]
        ),
        .testTarget(
            name: "HieroglyphsTests",
            dependencies: ["Hieroglyphs"]
        )
    ]
)
