// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc1035: Self = "RFC_1035"
}

extension Target.Dependency {
    static var rfc1035: Self { .target(name: .rfc1035) }
}

let package = Package(
    name: "swift-rfc-1035",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: .rfc1035, targets: [.rfc1035]),
    ],
    dependencies: [
        // Add RFC dependencies here as needed
        // .package(url: "https://github.com/swift-web-standards/swift-rfc-1123.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .rfc1035,
            dependencies: [
                // Add target dependencies here
            ]
        ),
        .testTarget(
            name: .rfc1035.tests,
            dependencies: [
                .rfc1035
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }