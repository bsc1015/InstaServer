// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "InstaServer",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.8"),
        
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.1"),
        
        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        
        .package(url: "https://github.com/vapor/routing.git", from: "3.0.1"),
        
        .package(url: "https://github.com/vapor/multipart.git", from: "3.0.2"),
        
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor", "Routing", "Multipart", "Authentication"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

