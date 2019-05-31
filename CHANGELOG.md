# Changelog

## 0.5.0 - Unreleased
- Add support for UK country
- Support setting of attitudeOrient via DeviceMotionData

## 0.4.0
- `VisionARManager` allows to change ARLane's length
- `boundingBox` property on `MBVDetection` now stores normalized relative coordinates

### Vision
- Added `startRecording` and `stopRecording` methods on `VisionManager` to record sessions.
- Added `VisionReplayManager` class for replaying recorded sessions.
- Changed the type of `visionManager` parameter in every `VisionManagerDelegate` method to `VisionManagerProtocol`.
- Changed `boundingBox` property on `MBVDetection` to store normalized relative coordinates.
- Fixed `CVPixelBuffer` memory leak.

### AR
- Added `set(laneLength:)` method on `VisionARManager` to customize the length of `ARLane`.
