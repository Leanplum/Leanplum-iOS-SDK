Pod::Spec.new do |s|
  s.name = 'Leanplum-iOS-SDK'
  s.version = '1.7.0'
  s.summary = 'Mobile Marketing Platform. Integrated. ROI Engine.'
  s.description = 'Leanplum’s integrated solution delivers meaningful engagement across messaging and the in-app experience. We offer Messaging, Automation, App Editing, Personalization, A/B Testing, and Analytics.'
  s.homepage = 'https://www.leanplum.com'
  s.license = { :type => 'Commercial', :text => 'See https://www.leanplum.com/tos' }
  s.author = { 'Leanplum' => 'support@leanplum.com' }
  s.social_media_url = 'https://twitter.com/leanplum'
  s.platform = :ios, '8.0'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Leanplum/Leanplum-iOS-SDK.git', :tag => s.version.to_s }
  s.frameworks = 'CFNetwork', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
  s.weak_frameworks = 'AdSupport', 'StoreKit'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }
  s.preserve_paths = 'Leanplum.framework'
  s.documentation_url = 'https://www.leanplum.com/docs#/docs'
  s.source_files = 'Leanplum.framework/Headers/*.h'
  s.public_header_files = 'Leanplum.framework/Headers/*.h'
  s.vendored_frameworks = 'Leanplum.framework'
end
