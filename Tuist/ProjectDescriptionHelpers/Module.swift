import ProjectDescription

private let modularBaseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "",
    "DEVELOPMENT_REGION": "en",
    "ENABLE_MODULE_VERIFIER": "NO",
    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
    "STRING_CATALOG_GENERATE_SYMBOLS": "NO",
]

extension Settings {
    public static let modular: Settings = .settings(base: modularBaseSettings)

    public static func modular(addingConditions conditions: String) -> Settings {
        modular(overriding: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) \(conditions)"])
    }

    /// Like `modular` but merges arbitrary extra keys on top of the shared base.
    /// Later entries in `overrides` win over the base.
    public static func modular(overriding overrides: SettingsDictionary) -> Settings {
        var base = modularBaseSettings
        for (key, value) in overrides { base[key] = value }
        return .settings(base: base)
    }

    /// Settings for unit-test targets: code-signing disabled + warnings as errors.
    public static let modularTests: Settings = modularTests()

    public static func modularTests(addingConditions conditions: String = "") -> Settings {
        var base = modularBaseSettings
        base["CODE_SIGN_IDENTITY"] = ""
        base["CODE_SIGNING_REQUIRED"] = "NO"
        base["CODE_SIGNING_ALLOWED"] = "NO"
        base["SWIFT_TREAT_WARNINGS_AS_ERRORS"] = "YES"
        if !conditions.isEmpty {
            base["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) \(conditions)"
        }
        return .settings(base: base)
    }

    /// Settings for UI test targets: TEST_TARGET_NAME + warnings as errors.
    public static func modularUITests(targetName: String, addingConditions conditions: String = "") -> Settings {
        var base = modularBaseSettings
        base["SWIFT_TREAT_WARNINGS_AS_ERRORS"] = "YES"
        base["TEST_TARGET_NAME"] = .string(targetName)
        if !conditions.isEmpty {
            base["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) \(conditions)"
        }
        return .settings(base: base)
    }
}

public extension TargetScript {
    static let swiftLint: TargetScript = .pre(
        script: """
        PROJECT_ROOT="${SRCROOT}"
        while [ ! -d "${PROJECT_ROOT}/Tuist" ] && [ "${PROJECT_ROOT}" != "/" ]; do
            PROJECT_ROOT="$(dirname "${PROJECT_ROOT}")"
        done
        SWIFTLINT="${PROJECT_ROOT}/Tuist/.build/artifacts/swiftlint/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint"
        CONFIG="${PROJECT_ROOT}/.swiftlint.yml"
        if [ -f "$SWIFTLINT" ]; then
            "$SWIFTLINT" lint --quiet --config "$CONFIG" "${SRCROOT}/Sources"
        else
            echo "warning: SwiftLint binary not found at $SWIFTLINT. Run 'tuist install'."
        fi
        """,
        name: "SwiftLint",
        basedOnDependencyAnalysis: false
    )
}

public extension Project {
    /// Static framework: Sources/ auto-discovered via buildableFolders.
    static func framework(
        name: String,
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        testDependencies: [TargetDependency]? = nil
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: name,
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "com.modular.swiftui.\(name.lowercased())",
                deploymentTargets: .iOS("17.0"),
                resources: resources,
                buildableFolders: ["Sources"],
                scripts: [.swiftLint],
                dependencies: dependencies,
                settings: .modular
            )
        ]

        if let testDependencies {
            targets.append(
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "com.modular.swiftui.\(name.lowercased())tests",
                    deploymentTargets: .iOS("17.0"),
                    buildableFolders: ["Tests"],
                    dependencies: [.target(name: name)] + testDependencies,
                    settings: .modularTests
                )
            )
        }

        let testAction: TestAction? = testDependencies.map { _ in
            .targets([.testableTarget(target: .target("\(name)Tests"))])
        }

        let scheme = Scheme.scheme(
            name: name,
            buildAction: .buildAction(targets: [.target(name)]),
            testAction: testAction
        )

        return Project(
            name: name,
            options: .options(automaticSchemesOptions: .disabled),
            settings: .modular,
            targets: targets,
            schemes: [scheme]
        )
    }
}
