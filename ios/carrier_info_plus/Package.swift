// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "carrier_info_plus",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "carrier-info-plus", targets: ["carrier_info_plus"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "carrier_info_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // Apple expects a privacy manifest from any third-party SDK.
                // Declaring it here also silences SwiftPM's "unhandled file"
                // warning, since the manifest sits inside the source directory.
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                // CoreTelephony for the radio, service and cellular-data reads.
                // MessageUI for MFMessageComposeViewController.canSendText(),
                // which is the only way iOS answers "can this device send SMS".
                // Xcode usually auto-links imported system frameworks, but
                // SwiftPM is less reliable about it, so both are declared.
                .linkedFramework("CoreTelephony"),
                .linkedFramework("MessageUI"),
            ]
        )
    ]
)
