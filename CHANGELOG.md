# Changelog

## 0.5.0

### Vision
- Added support for UK country
- Added support for setting attitudeOrient via DeviceMotionData
- Added `contains(worldCoordinate:)` method to Lane API
- Added `objects(in lane:)`, `objects(with detectionClass:)` methods to WorldDescription API
- Changed implementation of lane detector: it has better quality and improved energy efficiency. Only one ego lane is detected right now
- Changed World-Pixel transformation methods to return optional values
- Changed World-Geo transformation methods to return optional values
- Changed implementation of `DeviceInfoProvider` provider in order to make device's id persistent
- Changed implementation of `DeviceChecker` to increase performance on devices with A12 Bionic SoC
- Removed `MapboxNavigation` dependency
- Updated source code of `Reachability.swift` dependency

### AR
- Added support for changing look and feel for ARLane

## 0.4.2

### Vision
- Changed required versions of dependencies: `MapboxNavigation` to 0.35.0 and `MapboxMobileEvents` to 0.9.5
- Fixed deleting binary telemetry while moving it after recording is finished

## 0.4.1

### Vision
- Fixed a crash that may happen on creating or destroying `VisionARManager` or `VisionSafetyManager`
- Fixed incorrect `ARCamera` values during replaying recorded sessions with `VisionReplayManager`

## 0.4.0

### Vision
- Added `startRecording` and `stopRecording` methods on `VisionManager` to record sessions.
- Added `VisionReplayManager` class for replaying recorded sessions.
- Changed the type of `visionManager` parameter in every `VisionManagerDelegate` method to `VisionManagerProtocol`.
- Changed `boundingBox` property on `MBVDetection` to store normalized relative coordinates.
- Fixed `CVPixelBuffer` memory leak.

### AR
- Added `set(laneLength:)` method on `VisionARManager` to customize the length of `ARLane`.
