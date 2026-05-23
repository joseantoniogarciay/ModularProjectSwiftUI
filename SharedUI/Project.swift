import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "SharedUI",
    dependencies: [
        .external(name: "Kingfisher"),
    ],
    resources: ["Resources/**"]
)
