import ProjectDescription

private let modularBaseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "DEVELOPMENT_REGION": "en",
    "ENABLE_MODULE_VERIFIER": "NO",
    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
    "STRING_CATALOG_GENERATE_SYMBOLS": "NO",
]

extension Settings {
    public static let modular: Settings = .settings(base: modularBaseSettings)
}

public extension Project {
    /// Static framework: Sources/ auto-discovered via buildableFolders.
    static func framework(
        name: String,
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil
    ) -> Project {
        let target = Target.target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.modular.swiftui.\(name.lowercased())",
            deploymentTargets: .iOS("17.0"),
            resources: resources,
            buildableFolders: ["Sources"],
            dependencies: dependencies,
            settings: .modular
        )
        let scheme = Scheme.scheme(
            name: name,
            buildAction: .buildAction(targets: [.target(name)])
        )
        return Project(
            name: name,
            options: .options(automaticSchemesOptions: .disabled),
            settings: .modular,
            targets: [target],
            schemes: [scheme]
        )
    }

    /// App target: Sources/ auto-discovered, no explicit Info.plist file needed.
    static func app(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Project {
        let target = Target.target(
            name: name,
            destinations: .iOS,
            product: .app,
            bundleId: "com.modular.swiftui.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "UIApplicationSupportsIndirectInputEvents": .boolean(true),
            ]),
            buildableFolders: ["Sources"],
            dependencies: dependencies,
            settings: .modular
        )
        let scheme = Scheme.scheme(
            name: name,
            buildAction: .buildAction(targets: [.target(name)]),
            runAction: .runAction(executable: .target(name))
        )
        return Project(
            name: name,
            options: .options(automaticSchemesOptions: .disabled),
            settings: .modular,
            targets: [target],
            schemes: [scheme]
        )
    }
}
