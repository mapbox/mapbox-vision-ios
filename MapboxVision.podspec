Pod::Spec.new do |s|

  s.name         = "MapboxVision"
  s.version      = "0.13.0"

  s.summary      = "ML empowered Vision framework"
  s.description  = <<-DESC
                   ML empowered Vision framework
                   DESC

  s.homepage          = 'https://www.mapbox.com/vision/'
  s.documentation_url = 'https://docs.mapbox.com/ios/vision/'
  s.license           = { :type => "CUSTOM", :file => "Docs/LICENSE.md" }
  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/vision/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "https://github.com/mapbox/mapbox-vision-ios.git", :tag => "v#{s.version}" }

  s.source_files  = "MapboxVision/**/*.{swift,h,metal}", "Resources/**/*.swift"
  s.resource      = "Resources/Assets.xcassets"

  s.requires_arc = true

  s.swift_version = '4.2'

  s.dependency "MapboxVisionNativeAll/Vision", "#{s.version}"
  s.dependency "MapboxMobileEvents", "~> 0.10.2"
  s.dependency "ZIPFoundation", "~> 0.9.9"

end
