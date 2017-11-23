#
# Be sure to run `pod lib lint Leanplum-SDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'Leanplum-tvOS-SDK-source'
  s.version = '2.0.3-SNAPSHOT'
  s.summary = 'Mobile Marketing Platform. Integrated. ROI Engine.'
  s.description = 'Leanplum delivers meaningful engagement across channels through Automation, Personalization, A/B Testing, and Analytics.'
  s.homepage = 'https://www.leanplum.com'
  s.license = { :type => 'Commercial', :text => 'See https://www.leanplum.com/tos' }
  s.author = { 'Leanplum' => 'support@leanplum.com' }
  s.social_media_url = 'https://twitter.com/leanplum'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Leanplum/Leanplum-tvOS-SDK-Internal.git', :tag => s.version.to_s }
  s.tvos.deployment_target = '9.0'
  s.frameworks = 'CFNetwork', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
  s.weak_frameworks = 'AdSupport', 'StoreKit'
  s.library = 'sqlite3'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'BITCODE_GENERATION_MODE' => 'bitcode' }
  s.documentation_url = 'https://www.leanplum.com/docs#/docs'
  s.source_files = 'Leanplum-SDK/Classes/**/*'
  s.module_name = 'LeanplumTV'
end
