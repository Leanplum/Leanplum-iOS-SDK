platform :ios, '9.0'
use_modular_headers!

workspace 'Leanplum.xcworkspace'

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
  pod 'CleverTap-iOS-SDK', '~> 4.1.1'
end
#

target 'Leanplum-Static' do
  project 'LeanplumSDK/LeanplumSDK.xcodeproj'

  # Pods for Leanplum-Static
  pod 'CleverTap-iOS-SDK', '~> 4.1.1'
end

