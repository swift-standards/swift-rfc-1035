// swift-tools-version:6.0

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
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .rfc1035, targets: [.rfc1035]),
    ],
    dependencies: [
//         .package(url: "https://github.com/swift-standards/swift-standards.git", from: "0.1.0")
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
