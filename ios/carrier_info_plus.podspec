#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# CocoaPods support, kept alongside Swift Package Manager.
#
# Flutter picks SwiftPM or CocoaPods per consuming app, not per plugin: an app
# resolves plugins through CocoaPods whenever the swift-package-manager feature
# is switched off, or its Xcode project predates the SwiftPM migration. For
# those apps the tooling looks for this file at ios/<name>.podspec, so shipping
# it means neither kind of app has to change anything.
#
# Version, summary, description and homepage are read from pubspec.yaml so this
# file cannot drift from the package metadata. Everything below that point is
# genuinely iOS-specific and has no pubspec equivalent.
#
# Run `pod lib lint carrier_info_plus.podspec` to validate before publishing.
#
require 'yaml'

pubspec = YAML.load_file(File.join(__dir__, '..', 'pubspec.yaml'))
description = pubspec['description'].strip

# CocoaPods warns when a summary runs long, so use the leading sentence only.
summary = description.split('. ').first
summary += '.' unless summary.end_with?('.')

Pod::Spec.new do |s|
  s.name             = 'carrier_info_plus'
  s.version          = pubspec['version']
  s.summary          = summary
  s.description      = description
  s.homepage         = pubspec['repository']
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mouli Bheemaneti' => 'moulibheemaneti99@gmail.com' }
  s.source           = { :path => '.' }
  # Restricted to Swift rather than '**/*': the privacy manifest lives in the
  # same directory and belongs in resource_bundles below, not here.
  s.source_files = 'carrier_info_plus/Sources/carrier_info_plus/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  # Mirrors the linkerSettings in Package.swift, so a CocoaPods consumer
  # links the same frameworks a SwiftPM one does.
  s.frameworks = 'CoreTelephony', 'MessageUI'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # The CocoaPods equivalent of Package.swift's .process("PrivacyInfo.xcprivacy"),
  # so a pod consumer ships the same manifest a SwiftPM one does.
  s.resource_bundles = {
    'carrier_info_plus_privacy' => ['carrier_info_plus/Sources/carrier_info_plus/PrivacyInfo.xcprivacy']
  }
end
