// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Guitar Tuner",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "Guitar Tuner",
            targets: ["Guitar Tuner"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Guitar Tuner",
            path: ".",
            sources: [
                "GuitarTunerApp.swift",
                "Models",
                "Services",
                "ViewModels",
                "Views"
            ]
        )
    ]
)


