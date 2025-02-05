Pod::Spec.new do |s|
  s.name = 'Leanplum-iOS-Location'
  version = `cat sdk-version.txt`
  s.version = version
  s.summary = 'Supplementary Leanplum pod to provide geofencing support.'
  s.description = 'Use LeanplumLocationAndBeacons instead if you also want support for iBeacons.'
  s.homepage = 'https://www.leanplum.com'
  s.license = { :type => 'Commercial', :text => 'See https://www.leanplum.com/tos' }
  s.author = { 'Leanplum' => 'support@leanplum.com' }
  s.social_media_url = 'https://twitter.com/leanplum'
  s.platform = :ios, '10.0'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Leanplum/Leanplum-iOS-SDK.git', :tag => s.version.to_s}
  s.source_files = 'LeanplumSDKLocation/LeanplumSDKLocation/Classes/**/*'
  s.resource_bundles = {'LeanplumLocation' => ['LeanplumSDKLocation/LeanplumSDKLocation/*.{xcprivacy}']}
  s.frameworks = 'CoreLocation'
  s.documentation_url = 'https://docs.leanplum.com/'
  s.dependency 'Leanplum-iOS-SDK', "~> 7.0"
  s.module_name = 'LeanplumLocation'
  s.swift_versions = '5.0'
end
