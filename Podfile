project  'Leanplum-SDK.xcodeproj'

if ! ENV['LP_STATIC']
  use_frameworks!
end

target 'Leanplum-iOS-Example' do
  platform :ios, '8.0'

  pod 'Leanplum-iOS-SDK-source', :path => './'
  
  target 'LeanplumSDKTests' do
      inherit! :search_paths

      pod 'Leanplum-iOS-SDK-source', :path => './'
      pod 'OCMock', '~> 3.3.1'
      pod 'OHHTTPStubs'
  end
end

target 'Leanplum-tvOS-Example' do
  platform :tvos, '9.0'
  pod 'Leanplum-tvOS-SDK-source', :path => './'
end
