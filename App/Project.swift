import ProjectDescription
import ProjectDescriptionHelpers

private let baseAppDependencies: [TargetDependency] = [
    .project(target: "Core", path: "../Core"),
    .project(target: "Networking", path: "../Networking"),
    .project(target: "Data", path: "../Data"),
    .project(target: "SharedUI", path: "../SharedUI"),
    .project(target: "Pokemon", path: "../Features/Pokemon"),
    .project(target: "Account", path: "../Features/Account"),
    .external(name: "Kingfisher"),
]

private let devAppDependencies: [TargetDependency] = baseAppDependencies + [
    .external(name: "Pulse"),
    .external(name: "PulseUI"),
]

private func infoPlist(displayName: String) -> [String: Plist.Value] {
    [
        "CFBundleDisplayName": .string(displayName),
        "UILaunchScreen": .dictionary([:]),
        "UIApplicationSupportsIndirectInputEvents": .boolean(true),
    ]
}

let project = Project(
    name: "App",
    options: .options(automaticSchemesOptions: .disabled),
    settings: Settings.modular,
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "com.modular.swiftui.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: infoPlist(displayName: "App")),
            buildableFolders: ["Sources"],
            scripts: [.swiftLint],
            dependencies: baseAppDependencies,
            settings: Settings.modular
        ),
        .target(
            name: "AppDev",
            destinations: .iOS,
            product: .app,
            bundleId: "com.modular.swiftui.app.dev",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: infoPlist(displayName: "App dev")),
            buildableFolders: ["Sources"],
            scripts: [.swiftLint],
            dependencies: devAppDependencies,
            settings: Settings.modular(addingConditions: "DEV")
        ),
    ],
    schemes: [
        .scheme(
            name: "App",
            buildAction: .buildAction(targets: [.target("App")]),
            runAction: .runAction(executable: .target("App"))
        ),
        .scheme(
            name: "AppDev",
            buildAction: .buildAction(targets: [.target("AppDev")]),
            runAction: .runAction(executable: .target("AppDev"))
        ),
    ]
)
