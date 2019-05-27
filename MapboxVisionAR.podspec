Pod::Spec.new do |s|

  s.name         = "MapboxVisionAR"
  s.version      = "0.5.0"
  s.summary      = "Easy to use AR Navigation"

  s.homepage     = 'https://www.mapbox.com/vision/'

  s.license      = { :type => "CUSTOM", :file => "LICENSE.md" }

  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/vision/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "https://github.com/mapbox/mapbox-vision-ar-ios.git", :tag => "v#{s.version}" }

  s.source_files  = "MapboxVisionAR/**/*.{swift,h,metal}", "Resources/**/*.swift"
  s.resources     = ["MapboxVisionAR/Models/*", "Resources/Assets.xcassets"]

  s.requires_arc = true

  s.swift_version = '4.2'

  s.dependency "MapboxVisionNativeAll/AR", "#{s.version}"
  s.dependency "MapboxVision", "#{s.version}"
  s.dependency "MapboxDirections.swift", "~> 0.28.0"

end
