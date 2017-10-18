#
# Be sure to run `pod lib lint Leanplum-SDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'Leanplum-iOS-SDK-source'
  s.version = '2.0.3'
  s.summary = 'Mobile Marketing Platform. Integrated. ROI Engine.'
  s.description = <<-DESC
Leanplum’s integrated solution delivers meaningful engagement across messaging and the in-app
experience. We offer Messaging, Automation, App Editing, Personalization, A/B Testing, and
Analytics.
    DESC
  s.homepage = 'https://www.leanplum.com'
  s.license = { :type => 'Commercial', :text => 'See https://www.leanplum.com/tos' }
  s.author = { 'Leanplum' => 'support@leanplum.com' }
  s.social_media_url = 'https://twitter.com/leanplum'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Leanplum/Leanplum-SDK-Internal.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '7.0'
  s.frameworks = 'CFNetwork', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
  s.weak_frameworks = 'AdSupport', 'StoreKit'
  s.library = 'sqlite3'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'BITCODE_GENERATION_MODE' => 'bitcode' }
  s.documentation_url = 'https://www.leanplum.com/docs#/docs'
  s.source_files = 'Leanplum-SDK/Classes/**/*'
  s.module_name = 'Leanplum'
end
