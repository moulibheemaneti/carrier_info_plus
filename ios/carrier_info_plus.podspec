#
# CocoaPods support, kept alongside Swift Package Manager.
#
# Flutter 3.44 made SwiftPM the default, but apps that have not migrated still
# resolve plugins through CocoaPods, and the CocoaPods registry does not go
# read-only until December 2026. Shipping both means neither kind of app has to
# change anything.
#
Pod::Spec.new do |s|
  s.name             = 'carrier_info_plus'
  s.version          = '1.0.0'
  s.summary          = 'Cellular carrier, SIM and network information for Flutter.'
  s.description      = <<-DESC
Reads carrier, SIM and cellular network state on Android and iOS, and reports
honestly about what each platform can no longer answer.
                       DESC
  s.homepage         = 'https://github.com/moulibheemaneti/carrier_info_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mouli Bheemaneti' => 'moulibheemaneti99@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'carrier_info_plus/Sources/carrier_info_plus/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'CoreTelephony', 'MessageUI'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
  s.resource_bundles = {
    'carrier_info_plus_privacy' => ['carrier_info_plus/Sources/carrier_info_plus/Resources/PrivacyInfo.xcprivacy']
  }
end
