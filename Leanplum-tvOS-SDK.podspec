Pod::Spec.new do |s|
  s.name = 'Leanplum-tvOS-SDK'
  s.version = '2.0.2'
  s.summary = 'Mobile Marketing Platform. Integrated. ROI Engine.'
  s.description = 'Leanplum delivers meaningful engagement across channels through Automation, Personalization, A/B Testing, and Analytics.'
  s.homepage = 'https://www.leanplum.com'
  s.license = { :type => 'Commercial', :text => 'See https://www.leanplum.com/tos' }
  s.author = { 'Leanplum' => 'support@leanplum.com' }
  s.social_media_url = 'https://twitter.com/leanplum'
  s.tvos.deployment_target = '8.0'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/Leanplum/Leanplum-tvOS-SDK.git', :tag => s.version.to_s }
  s.frameworks = 'CFNetwork', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
  s.weak_frameworks = 'AdSupport', 'StoreKit'
  s.library = 'sqlite3'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }
  s.preserve_paths = 'LeanplumTV.framework'
  s.documentation_url = 'https://www.leanplum.com/docs#/docs'
  s.source_files = 'LeanplumTV.framework/Headers/*.h'
  s.public_header_files = 'LeanplumTV.framework/Headers/*.h'
  s.vendored_frameworks = 'LeanplumTV.framework'
end
