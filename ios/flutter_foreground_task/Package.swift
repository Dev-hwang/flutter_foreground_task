// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_foreground_task",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-foreground-task", targets: ["flutter_foreground_task"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_foreground_task",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/flutter_foreground_task"
        )
    ]
)
