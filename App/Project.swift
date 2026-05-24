import ProjectDescription
import ProjectDescriptionHelpers

private let baseAppDependencies: [TargetDependency] = [
    .project(target: "Core", path: "../Core"),
    .project(target: "Networking", path: "../Networking"),
    .project(target: "Data", path: "../Data"),
    .project(target: "SharedUI", path: "../SharedUI"),
    .project(target: "Pokemon", path: "../Features/Pokemon"),
    .project(target: "Account", path: "../Features/Account"),
    .project(target: "Cart", path: "../Features/Cart"),
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
        // MARK: - App targets

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

        // MARK: - Unit test targets

        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.modular.swiftui.app.tests",
            deploymentTargets: .iOS("17.0"),
            buildableFolders: ["Tests"],
            dependencies: [
                .target(name: "App"),
                .project(target: "Core", path: "../Core"),
            ],
            settings: .modularTests
        ),
        .target(
            name: "AppDevTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.modular.swiftui.app.devtests",
            deploymentTargets: .iOS("17.0"),
            buildableFolders: ["Tests"],
            dependencies: [
                .target(name: "AppDev"),
                .project(target: "Core", path: "../Core"),
            ],
            settings: .modularTests(addingConditions: "DEV")
        ),

        // MARK: - UI test targets

        .target(
            name: "AppUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.modular.swiftui.app.uitests",
            deploymentTargets: .iOS("17.0"),
            buildableFolders: ["UITests"],
            dependencies: [.target(name: "App")],
            settings: Settings.modularUITests(targetName: "App")
        ),
        .target(
            name: "AppDevUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.modular.swiftui.app.devuitests",
            deploymentTargets: .iOS("17.0"),
            buildableFolders: ["UITests"],
            dependencies: [.target(name: "AppDev")],
            settings: Settings.modularUITests(targetName: "AppDev", addingConditions: "DEV")
        ),
    ],
    schemes: [
        .scheme(
            name: "App",
            buildAction: .buildAction(targets: [.target("App")]),
            testAction: .targets([
                .testableTarget(target: .target("AppTests")),
                .testableTarget(target: .target("AppUITests")),
            ]),
            runAction: .runAction(executable: .target("App"))
        ),
        .scheme(
            name: "AppDev",
            buildAction: .buildAction(targets: [.target("AppDev")]),
            testAction: .targets([
                .testableTarget(target: .target("AppDevTests")),
                .testableTarget(target: .target("AppDevUITests")),
            ]),
            runAction: .runAction(executable: .target("AppDev"))
        ),
    ]
)
