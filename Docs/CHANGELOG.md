# Changelog

## 0.13.0 - Unreleased

### Vision
- Added `VisionManager.set(cameraHeight:)`
- Fixed applying non-BGRA image formats

### AR
- Added `aspectRatio`, `roll`, `pitch`, `yaw`, `height` properties to `Camera`
- Deprecated `ARCamera` class and `VisionManagerDelegate.visionManager(_:didUpdateARCamera:)` method in favor of utilization of `Camera` class

### Safety

## 0.12.0

### Vision
- Added `Japan` country and support for the detection of Japanese traffic signs
- Added property `progress` to the `VisionReplayManager`
- Added read-only property `duration` to the `VisionReplayManager`
- Added new `SignType`s:
  - `InformationRestrictedParking`
  - `RegulatorySchoolZone`
  - `RegulatoryBicyclesAndPedestriansCrossing`
  - `RegulatoryNoBusesAndHeavyVechicles`
- Changed `VisionReplayManager`'s behaviour:
  - method `start` continues session replay from the current progress
  - method `stop` stops session replay without changing the progress
  - end of the session does not trigger `stop` method
- Deprecated separate detection and segmentation models configuration (use `modelPerformance` instead of `modelPerformanceConfig` on `VisionManager`)
- Improved camera calibration algorithm
- Improved lanes detection algorithm
- Utilized new ML models that reduce resource consumption

### AR
- Added `visionARManager(_:, didUpdateRoute:)` method to the `VisionARManagerDelegate` to support route replay from the recorded session
- Fixed the bug with the inability to set AR visual params

### Documentation
- Added Getting Started code snippet showing basic SDK configuration steps
- Added POI drawing, AR customization, and Safety alerts examples for according tutorials posted at https://docs.mapbox.com/ios/vision/help/#tutorials

## 0.11.0

### Vision
- Added `Germany` country
- Added new `VisionUtils.isVisionSupported` method that checks whether Vision SDK is supported and can be run on the current device
- Added new `SignTypes`:
  `InformationCarWashing`, `InformationBusStop`, `RegulatoryPedestriansCrossingUp`,
  `RegulatoryPedestriansCrossingDown`, `InformationAutoService`, `InformationFood`,
  `InformationTown`, `InformationTownEnd`, `RegulatoryControl`,
  `RegulatoryDoubleUTurn`, `SpeedLimitZone`, `SpeedLimitEndZone`
- Changed methods `createCVPixelBuffer` and `createCGImage` on the `Image` class to return retained values instead of `Unmanaged`
- Updated EU classifier
- Improved performance on iPhone 11 family
- Removed location update in background
- Fixed a crash with `ReachabilityCallback`
- Fixed a crash on receiving location updates while stopping VisionManager
- Fixed a crash due to race condition in ObservableVideoSource
- Fixed a crash happening on `VisionManager.destroy`

### AR
- Added new `Fence` AR style. May be enabled via `VisionARViewController.isFenceVisible` property
- Added `FenceVisualParams` class and `VisionARViewController.setFenceVisualParams` method for customization of `Fence` rendering
- Added `VisionARViewController.setArQuality` method to set overall quality of AR objects
- Added `VisionARViewController.isFenceVisible` and `VisionARViewController.isLaneVisible` to manage displayed AR features
- Fixed issues with AR not shown on some devices

## 0.10.1

### Vision
- Increased allowed performance of ML models on iPhone 11 family

### AR
- Fixed displaying AR in conditions of low GPS accuracy

## 0.10.0

### Vision
- Added detection of two adjacent lanes
- Added method `set(visionManager:)` to `VisionPresentationViewController`
- Added new `ConstructionCone` class to `DetectionClass`
- Completely new segmentation model which has the following classes: Crosswalk, Hood, MarkupDashed, MarkupDouble, MarkupOther, MarkupSolid, Other, Road, RoadEdge, Sidewalk. Improved performance at night.
- Improved delivery of camera parameters in `CameraVideoSource`
- Improved performance of lanes detection
- Fixed a crash on `VisionReplayManager` destroy
- Fixed the bug with unrecorded session
- Fixed a bug when hash table was mutated while being enumerated
- Moved `VisionPresentationViewController` to `MapboxVisionNative` module
- Made unavailable methods `present(frame:)`, `present(segmentation:)` and `present(detections:)`. You need to call `set(visionManager:)` to set up `VisionPresentationViewController`
- Renamed property `frameVisualizationMode` to `visualizationMode` in `VisionPresentationViewController`
- Updated detection models, added construction cone class, improved metrics

### AR
- Changed `VisionARViewController` to show camera frames as long as `VisionARManager` exists

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
