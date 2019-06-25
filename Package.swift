// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "[vision-ios-examples]",
    dependencies: [
      .package(url: "https://github.com/orta/Komondor.git", from: "1.0.4")
    ]
)

#if canImport(PackageConfig)
    import PackageConfig

    let config = PackageConfiguration([
        "komondor": [
            "pre-commit": "secret-shield --check-and-run 2018-07-05"
        ],
    ]).write()
#endif
