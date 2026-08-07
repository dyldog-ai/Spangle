import ProjectDescription

let project = Project(
    name: "Spangle",
    targets: [
        .target(
            name: "Spangle",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.spangle.app",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "CFBundleDisplayName": "Spangle",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
            ]),
            buildableFolders: [
                "Spangle/Sources",
                "Spangle/Resources",
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            ])
        ),
    ]
)
