Pod::Spec.new do |s|
  s.name         = "DatadogSDKSessionReplay"
  s.module_name  = "DatadogSessionReplay"
  s.version      = "1.14.0-sr-beta1"
  s.summary      = "Official Datadog Session Replay SDK for iOS. This module is currently in beta - contact Datadog to request a try."
  
  s.homepage     = "https://www.datadoghq.com"
  s.social_media_url   = "https://twitter.com/datadoghq"

  s.license            = { :type => "Apache", :file => 'LICENSE' }
  s.authors            = { 
    "Maciek Grzybowski" => "maciek.grzybowski@datadoghq.com",
    "Maciej Burda" => "maciej.burda@datadoghq.com",
    "Maxime Epain" => "maxime.epain@datadoghq.com"
  }

  s.swift_version      = '5.1'
  s.ios.deployment_target = '11.0'

  s.source = { :git => "https://github.com/DataDog/dd-sdk-ios.git", :tag => s.version.to_s }
  
  s.source_files = ["DatadogSessionReplay/Sources/**/*.swift"]
  s.dependency 'DatadogSDK', s.version.to_s
end
