import ProjectDescription

let workspace = Workspace(
    name: "ModularProjectSwiftUI",
    projects: [
        "App",
        "Core",
        "Networking",
        "Data",
        "SharedUI",
        "Features/**",
    ]
)
