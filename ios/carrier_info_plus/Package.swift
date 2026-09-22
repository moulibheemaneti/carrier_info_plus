// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "carrier_info_plus",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "carrier-info-plus", type: .static, targets: ["carrier_info_plus"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "carrier_info_plus",
      dependencies: [],
      resources: [
        .process("Resources")
      ],
      linkerSettings: [
        .linkedFramework("CoreTelephony"),
        .linkedFramework("MessageUI"),
      ]
    )
  ]
)
