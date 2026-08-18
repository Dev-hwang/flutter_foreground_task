// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_foreground_task",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "flutter-foreground-task",
            targets: ["flutter_foreground_task", "flutter_foreground_task_early_registration"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_foreground_task",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        ),
        .target(
            name: "flutter_foreground_task_early_registration",
            dependencies: ["flutter_foreground_task"],
            cSettings: [
                .headerSearchPath("include/flutter_foreground_task_early_registration")
            ]
        )
    ]
)
