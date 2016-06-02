Pod::Spec.new do |s|
  s.name             = 'TwitterLoggingService'
  s.version          = '2.2.0'
  s.summary          = 'Twitter Logging Service is a robust and performant logging framework for iOS clients'
  s.description      = <<-DESC
Twitter created a framework for logging in order to fulfill the following requirements:
    - fast (no blocking the main thread)
    - thread safe
    - as easy as NSLog in most situations
    - support pluggable "outputs streams" to which messages will be delivered
    - "outputs streams" filter messages rather than global filtering for all "output streams"
    - able to categorize log messages (log channels)
    - able to designate importance to log messages (log levels)
    - force opt-in for persisted logs (a security requirement, fulfilled by using the context feature of TLS)
                       DESC
  s.homepage         = 'https://github.com/twitter/ios-twitter-logging-service'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'Twitter' => 'opensource@twitter.com' }
  s.source           = { :git => 'https://github.com/twitter/ios-twitter-logging-service.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Classes/*'
  s.public_header_files = 'Classes/*.h'
end
