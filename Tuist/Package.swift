// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "Alamofire": .staticFramework,
            "Kingfisher": .staticFramework,
        ],
        baseSettings: .settings(base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        ]),
        targetSettings: [
            "Alamofire": ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"],
            "Kingfisher": ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"],
        ]
    )
#endif

let package = Package(
    name: "ModularProjectSwiftUI",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.12.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", exact: "8.9.0"),
    ]
)
