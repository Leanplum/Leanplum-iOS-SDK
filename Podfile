platform :ios, '10.0'
use_modular_headers!

workspace 'Leanplum.xcworkspace'

def clever_tap
  pod 'CleverTap-iOS-SDK', '~> 6.0'
end

target 'LeanplumSDKApp' do
    project 'LeanplumSDKApp/LeanplumSDKApp.xcodeproj'
    use_frameworks!

    clever_tap
end

target 'LeanplumSDKTests' do
    project 'LeanplumSDKApp/LeanplumSDKApp.xcodeproj'
    use_frameworks!

    pod 'OCMock', '~> 3.3.1'
    pod 'OHHTTPStubs', '~> 9.0.0'
end

target 'Leanplum' do
  project 'LeanplumSDK/LeanplumSDK.xcodeproj'
  workspace 'Leanplum.xcworkspace'
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Leanplum
  clever_tap
end
#

target 'Leanplum-Static' do
  project 'LeanplumSDK/LeanplumSDK.xcodeproj'

  # Pods for Leanplum-Static
  clever_tap
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
