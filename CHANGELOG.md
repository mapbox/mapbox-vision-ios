# Changelog

## 0.10.0 - Unreleased


## 0.9.0

### Vision
- Added property `delegate` to `VisionManager` and `VisionReplayManager`
- Added method `start()` to `VisionManager` and `VisionReplayManager`
- Added new `SignType`s: RegulatoryKeepLeftPicture, RegulatoryKeepLeftText, AheadSpeedLimit, WarningSpeedLimit, RegulatoryNoUTurnRight, WarningTurnRightOnlyArrow
- Deprecated method `start(delegate:)` in `VisionManager` and `VisionReplayManager`

### AR
- Added method `set(arManager:)` to `VisionARViewController`
- Added methods `visionARManager(_:didUpdateARMaskImage:)` and `visionARManager(visionARManager:didUpdateARLaneCutoffDistance:)` to `VisionARManagerDelegatet`
- Added property `delegate`
- Changed AR Lane appearance
- Methods `present(sampleBuffer:)`, `present(camera:)`, `present(lane:)` were made unavailable. You need to call `set(arManager:)` to set up `VisionARViewController`
- Deprecated property `laneVisualParams` in `VisionARViewController`
- Deprecated method `create(visionManager:delegate:)`. You need to create vision AR manager with `create(visionManager:)` and set the delegate as property
- Moved AR rendering to native

### Safety
- Added property `delegate` to `VisionSafetyManager`
- Deprecated method `create(visionManager:delegate:)`. You need to create vision safety manager with `create(visionManager:)` and set the delegate as property

## 0.8.1

### Vision
- Removed dependency on `CoreBluetooth`

## 0.8.0

### Vision
- Fixed applying dynamic mode of ML performance for the merged model
- Add monitoring of device state in order to detect the effect on performance

## 0.7.1

### Vision
- Fixed issue with `dynamic` FPS for a `Merge model`

## 0.7.0

### Vision
- Improved lane detection

## 0.6.0

### Vision
- Added MapboxAccounts dependency
- Added `currentLaneCenter`, `currentLaneWidth` to `RoadDescription`
- Added method `pointsWithSegmentsNumber:` and property `curve` in `MBVLaneEdge`
- Added method `pointsWithSegmentsNumber:` in `BezierCubic3D`
- Fixed the bug with crashes on destroy
- Renamed `currentLanePosition` to `relativePositionInLane` in `RoadDescription`
- Renamed `getPoint:` to `point:` in `BezierCubic3D`
- Renamed `getPoints:` to `points:` in `BezierCubic3D`
- Renamed `getDerivatives:` to `derivatives` in `BezierCubic3D`
- Renamed `getControlPoints` to `controlPoints` in `BezierCubic3D`
- Updated source code of `Reachability.swift` dependency

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
