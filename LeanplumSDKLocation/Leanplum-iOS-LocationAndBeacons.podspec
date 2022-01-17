Pod::Spec.new do |s|
  s.name = 'Leanplum-iOS-LocationAndBeacons'
  version = `cat ../sdk-version.txt`
  s.version = version
  s.summary = 'Supplementary Leanplum pod to provide geofencing and iBeacons support.'
  s.description = 'Use LeanplumLocation instead if you do not need support for iBeacons.'
  s.homepage = 'https://www.leanplum.com'
  s.license = { :type => 'Commercial', :text => 'See https://www.leanplum.com/tos' }
  s.author = { 'Leanplum' => 'support@leanplum.com' }
  s.social_media_url = 'https://twitter.com/leanplum'
  s.platform = :ios, '9.0'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Leanplum/Leanplum-iOS-SDK.git', :tag => s.version.to_s}
  s.source_files = 'LeanplumSDKLocation/Classes/**/*'
  s.frameworks = 'CoreLocation'
  s.documentation_url = 'https://docs.leanplum.com/'
  s.dependency 'Leanplum-iOS-SDK'
  s.module_name = 'LeanplumLocationAndBeacons'
  s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'LP_BEACON=1' }
end
