Pod::Spec.new do |s|
  s.name             = 'TwitterLoggingService'
  s.version          = '2.7.0'
  s.summary          = 'Twitter Logging Service is a robust and performant logging framework for iOS and macOS'
  s.description      = 'Twitter created a framework for logging in order to fulfill the numerous needs of Twitter for iOS including being fast, safe, modular and versatile.'
  s.homepage         = 'https://github.com/twitter/ios-twitter-logging-service'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'Twitter' => 'opensource@twitter.com' }
  s.source           = { :git => 'https://github.com/twitter/ios-twitter-logging-service.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'

  s.subspec 'Default' do |sp|
    sp.source_files = 'Classes/**/*'
    sp.public_header_files = 'Classes/**/*.h'
  end

  s.subspec 'ObjC' do |sp|
    sp.source_files = 'Classes/**/*.{h,m,c,cpp,mm}'
    sp.public_header_files = 'Classes/**/*.h'
  end

  s.default_subspec = 'Default'
end
