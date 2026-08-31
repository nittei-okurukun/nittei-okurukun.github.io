// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NitteiOkurikun",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NitteiOkurikun",
            path: "Sources/NitteiOkurikun"
        )
    ]
)
