import Foundation
import ProjectDescription

// Developer-only QueKit import tooling and QYay notes are intentionally absent
// from normal generated projects and every production archive. Opt in locally
// with: SPANGLE_DEVELOPER_INTEGRATIONS=1 tuist generate --no-open
let includesDeveloperIntegrations = ProcessInfo.processInfo.environment[
    "SPANGLE_DEVELOPER_INTEGRATIONS"
] == "1"

let qyayICloudContainer = "iCloud.com.qyay.QYay"
let queKitICloudContainer = "iCloud.com.dylanelliott.QueKit"

let packages: [Package] = includesDeveloperIntegrations
    ? [.local(path: "../QueKit"), .local(path: "../QYayKit")]
    : []
let appDependencies: [TargetDependency] = includesDeveloperIntegrations
    ? [.package(product: "QueKit"), .package(product: "QYayKit")]
    : []

var infoPlistValues: [String: Plist.Value] = [
    "UILaunchScreen": [:],
    "CFBundleDisplayName": "Spangle",
    "UISupportedInterfaceOrientations": [
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight",
    ],
]
var entitlementsValues: [String: Plist.Value] = [:]
var appSettings: SettingsDictionary = [
    "GENERATE_INFOPLIST_FILE": "YES",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "6CW3378X23",
]

if includesDeveloperIntegrations {
    infoPlistValues["NSUbiquitousContainers"] = [
        qyayICloudContainer: [
            "NSUbiquitousContainerName": "QYay",
            "NSUbiquitousContainerIsDocumentScopePublic": true,
        ],
        queKitICloudContainer: [
            "NSUbiquitousContainerName": "QueKit",
            "NSUbiquitousContainerIsDocumentScopePublic": true,
        ],
    ]
    entitlementsValues = [
        "com.apple.developer.icloud-container-identifiers": [
            .string(qyayICloudContainer),
            .string(queKitICloudContainer),
        ],
        "com.apple.developer.icloud-services": ["CloudDocuments"],
        "com.apple.developer.ubiquity-container-identifiers": [
            .string(qyayICloudContainer),
            .string(queKitICloudContainer),
        ],
    ]
    appSettings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) DEVELOPER_INTEGRATIONS"
}

let project = Project(
    name: "Spangle",
    packages: packages,
    targets: [
        .target(
            name: "Spangle",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.spangle.app",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            infoPlist: .extendingDefault(with: infoPlistValues),
            buildableFolders: [
                "Spangle/Sources",
                "Spangle/Resources",
            ],
            entitlements: .dictionary(entitlementsValues),
            dependencies: appDependencies,
            settings: .settings(base: appSettings)
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
    ]
)
