Pod::Spec.new do |s|

  s.name         = "VisionSDK"
  s.version      = "0.0.1-alpha-1"
  s.summary      = "ML empowered vision framework"

  s.homepage     = 'https://www.mapbox.com/ios-sdk/'

  s.license      = { :type => "CUSTOM", :file => "LICENSE.md" }

  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/ios-sdk/vision/api/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "https://github.com/mapbox/VisionSDK.git", :branch => "alpha-1" }

  s.source_files  = "VisionSDK/**/*.{swift,h,metal}"
  s.resource      = "Resources/Assets.xcassets"

  s.requires_arc = true

  s.swift_version = '4.1'

  s.dependency "VisionCore", "~> 0.0.1-alpha-1"
  s.dependency "Zip",   "~> 1.1.0"
  s.dependency "MapboxMobileEvents", "~> 0.5.0"

end
