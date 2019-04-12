Pod::Spec.new do |s|

  s.name         = "MapboxVisionAll"
  s.version      = "0.3.0"
  s.summary      = "ML empowered vision framework"

  s.homepage     = 'https://www.mapbox.com/vision/'

  s.license      = { :type => "CUSTOM", :file => "LICENSE.md" }

  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/vision/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "https://github.com/mapbox/mapbox-vision-ios.git", :tag => "v#{s.version}" }

  s.requires_arc = true

  s.swift_version = '4.1'

  s.default_subspec = "Vision", "AR", "Safety"

  s.subspec 'Vision' do |vision|
      vision.dependency "MapboxVision", "~> 0.3.0"
  end

  s.subspec 'AR' do |ar|
      ar.dependency "MapboxVisionAR", "~> 0.3.0"
  end

  s.subspec 'Safety' do |safety|
      safety.dependency "MapboxVisionSafety", "~> 0.3.0"
  end

end
