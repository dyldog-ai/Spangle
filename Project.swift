import ProjectDescription

let qyayICloudContainer = "iCloud.com.qyay.QYay"
let queKitICloudContainer = "iCloud.com.dylanelliott.QueKit"

let commonInfoPlist: [String: Plist.Value] = [
    "UILaunchScreen": [:],
    "CFBundleDisplayName": "Spangle",
    "UISupportedInterfaceOrientations": [
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight",
    ],
]

var developerInfoPlist = commonInfoPlist
developerInfoPlist["CFBundleDisplayName"] = "Spangle Dev"
developerInfoPlist["NSUbiquitousContainers"] = [
    qyayICloudContainer: [
        "NSUbiquitousContainerName": "QYay",
        "NSUbiquitousContainerIsDocumentScopePublic": true,
    ],
    queKitICloudContainer: [
        "NSUbiquitousContainerName": "QueKit",
        "NSUbiquitousContainerIsDocumentScopePublic": true,
    ],
]

let developerEntitlements: [String: Plist.Value] = [
    "com.apple.developer.icloud-container-identifiers": [
        .string(qyayICloudContainer),
        .string(queKitICloudContainer),
    ],
    "com.apple.developer.icloud-services": ["CloudDocuments"],
    "com.apple.developer.ubiquity-container-identifiers": [
        .string(qyayICloudContainer),
        .string(queKitICloudContainer),
    ],
    "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)com.spangle.app.dev",
]

let commonSettings: SettingsDictionary = [
    "GENERATE_INFOPLIST_FILE": "YES",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "6CW3378X23",
]
var developerSettings = commonSettings
developerSettings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) DEVELOPER_INTEGRATIONS DEVELOPER_FEATURES"

let project = Project(
    name: "Spangle",
    packages: [
        .local(path: "../Que/QueKit"),
        .local(path: "../QYayKit"),
    ],
    targets: [
        // Store/production target: no developer packages, code paths, resources,
        // iCloud containers, or developer tools are linked into this product.
        .target(
            name: "Spangle",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.spangle.app",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            infoPlist: .extendingDefault(with: commonInfoPlist),
            buildableFolders: ["Spangle/Sources", "Spangle/Resources"],
            entitlements: .dictionary([:]),
            settings: .settings(base: commonSettings)
        ),
        // Developer target: QYay notes, QueKit lists, the visual level
        // creator, and developer settings are all explicitly enabled here.
        .target(
            name: "SpangleDev",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.spangle.app.dev",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            infoPlist: .extendingDefault(with: developerInfoPlist),
            buildableFolders: ["Spangle/Sources", "Spangle/Resources"],
            entitlements: .dictionary(developerEntitlements),
            dependencies: [
                .package(product: "QueKit"),
                .package(product: "QYayKit"),
            ],
            settings: .settings(base: developerSettings)
        ),
        .target(
            name: "SpangleTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.spangle.app.tests",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            buildableFolders: ["Spangle/Tests"],
            dependencies: [.target(name: "Spangle")]
        ),
        .target(
            name: "SpangleDevTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.spangle.app.dev.tests",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            buildableFolders: ["Spangle/DevTests"],
            dependencies: [.target(name: "SpangleDev")],
            settings: .settings(base: [
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEVELOPER_FEATURES",
            ])
        ),
    ]
)
