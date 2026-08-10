import ProjectDescription

let qyayICloudContainer = "iCloud.com.qyay.QYay"
let queKitICloudContainer = "iCloud.com.dylanelliott.QueKit"

let project = Project(
    name: "Spangle",
    packages: [
        .local(path: "../QueKit"),
        .local(path: "../QYayKit"),
    ],
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
                "NSUbiquitousContainers": [
                    qyayICloudContainer: [
                        "NSUbiquitousContainerName": "QYay",
                        "NSUbiquitousContainerIsDocumentScopePublic": true,
                    ],
                    queKitICloudContainer: [
                        "NSUbiquitousContainerName": "QueKit",
                        "NSUbiquitousContainerIsDocumentScopePublic": true,
                    ],
                ],
            ]),
            buildableFolders: [
                "Spangle/Sources",
                "Spangle/Resources",
            ],
            entitlements: .dictionary([
                "com.apple.developer.icloud-container-identifiers": .array([
                    .string(qyayICloudContainer),
                    .string(queKitICloudContainer),
                ]),
                "com.apple.developer.icloud-services": .array([.string("CloudDocuments")]),
                "com.apple.developer.ubiquity-container-identifiers": .array([
                    .string(qyayICloudContainer),
                    .string(queKitICloudContainer),
                ]),
            ]),
            dependencies: [
                .package(product: "QueKit"),
                .package(product: "QYayKit"),
            ],
            settings: .settings(base: [
                "GENERATE_INFOPLIST_FILE": "YES",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "CODE_SIGN_STYLE": "Automatic",
                "DEVELOPMENT_TEAM": "6CW3378X23",
            ])
        ),
    ]
)
