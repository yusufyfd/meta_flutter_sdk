#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint meta_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'meta_flutter_sdk'
  s.version          = '0.1.0'
  s.summary          = 'Explicit Flutter access to the native Facebook SDK.'
  s.description      = <<-DESC
Privacy-aware Facebook Login, App Events, and Graph API access for Flutter.
                       DESC
  s.homepage         = 'https://github.com/yusufyfd/meta_flutter_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Yusuf Demir' => 'yusuf@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'meta_flutter_sdk/Sources/meta_flutter_sdk/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.dependency 'FBSDKCoreKit', '18.0.3'
  s.dependency 'FBSDKLoginKit', '18.0.3'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'meta_flutter_sdk_privacy' => ['meta_flutter_sdk/Sources/meta_flutter_sdk/PrivacyInfo.xcprivacy']}
end
