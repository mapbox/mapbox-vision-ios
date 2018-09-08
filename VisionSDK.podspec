#
#  Be sure to run `pod spec lint VisionSDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

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

  s.source_files  = "VisionSDK"
  s.resource      = "Resources/Assets.xcassets"

  s.requires_arc = true

  s.swift_version = '4.1'

  s.dependency "VisionCore", "~> 0.0.1-alpha-1"
  s.dependency "Zip",   "~> 1.1.0"
  s.dependency "MapboxMobileEvents", "~> 0.5.0"

end
