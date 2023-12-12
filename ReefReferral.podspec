Pod::Spec.new do |s|
  s.name           = 'ReefReferral'
  s.version        = '0.0.0'
  s.summary        = 'ReefReferral iOS SDK'
  s.author         = 'ReefReferral'
  s.homepage       = 'https://www.reefreferral.com/'
  s.platform       = :ios, '13.0'
  s.swift_version  = '5.4'
  s.source         = { git: 'https://github.com/Reef-Referral/reef-referral-ios.git' }
  s.static_framework = true

  s.dependency 'Logging', '~> 1.4.0'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
  
  s.source_files = "Sources/**/*.swift"
end
