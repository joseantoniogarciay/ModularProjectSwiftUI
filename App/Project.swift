import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    name: "App",
    dependencies: [
        .project(target: "Pokemon", path: "../Features/Pokemon"),
        .project(target: "Data", path: "../Data"),
        .project(target: "Networking", path: "../Networking"),
        .project(target: "SharedUI", path: "../SharedUI"),
        .project(target: "Core", path: "../Core"),
    ]
)
