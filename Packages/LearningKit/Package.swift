// swift-tools-version: 6.0
import PackageDescription

// Each Clean Architecture layer is its own module, so the dependency rule is
// enforced by the compiler rather than by convention:
//
//   App (SwiftUI + composition root) ──▶ Presentation ──▶ Domain
//                                    └─▶ DataLayer ─────▶ Domain
//
// Domain depends on nothing. Presentation cannot see DataLayer, and vice versa.
let package = Package(
    name: "LearningKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    targets: [
        .target(name: "Domain"),
        .target(
            name: "DataLayer",
            dependencies: ["Domain"],
            resources: [.process("Resources")]
        ),
        .target(name: "Presentation", dependencies: ["Domain"]),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer", "Domain"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"]),
    ],
    swiftLanguageModes: [.v6]
)
