Pod::Spec.new do |s|

  s.name         = "MapboxVision"
  s.version      = "0.0.1-alpha.1"
  s.summary      = "ML empowered vision framework"

  s.homepage     = 'https://www.mapbox.com/vision/'

  s.license      = { :type => "CUSTOM", :file => "LICENSE.md" }

  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/vision/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "https://github.com/mapbox/mapbox-vision-ios.git", :tag => "v#{s.version}" }

  s.source_files  = "MapboxVision/**/*.{swift,h,metal}"
  s.resource      = "Resources/Assets.xcassets"

  s.requires_arc = true

  s.swift_version = '4.1'

  s.dependency "MapboxVisionCore", "~> 0.0.1-alpha.1"
  s.dependency "Zip",   "~> 1.1.0"
  s.dependency "MapboxMobileEvents", "~> 0.5.0"

end
