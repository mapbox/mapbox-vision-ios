![Swift version](https://img.shields.io/static/v1.svg?label=Swift&message=4.2&color=orange)
![Platform support](https://img.shields.io/static/v1.svg?label=iOS&message=%3E=%2011.2&color=brightgreen)

# Mapbox Vision SDK

# Table of contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [License](#license)

# Overview

The current repository is a part of [Vision SDK](https://vision.mapbox.com).

The Vision SDK provides developers with cutting-edge AI and AR tools to build better driving experiences. It’s smart enough to understand the road, yet lean enough to run on devices that billions of drivers use everyday.

The key features are:
- Navigation in augemented reality;
- Scene segmentation;
- Sign detection;
- Safety alerts;
- Object detection;
- Lane detection.

Vision SDK for iOS contains several modules which built on top of Vision Core library (the implementation of Vision Core is in private repository):
  1. `Vision SDK` - an end-user SDK with a lot of helpers such as:
      * Device camera session implementation;
      * Interfaces and additional functions for an API data structures;
      * Views of segmentation, detection, for debugging purposes.
  1. `VisionAR SDK` for AR experience on iOS platform. It has own API to control:
      * configuration of AR lane:
          - lane's color;
           - lane's geometry;
          - lane's material (shaders, textures, parameters of light source.
      * customize occlusion;
      * draw custom objects?
      * add objects to draw as pins;
      * etc.
  1. `VisionSafety SDK` implements API for a safety features such as:
      * speed limits;
      * collision alerts;
      * etc.

# Getting Started

## Requirements

The Vision SDK for iOS is written in Swift 4.2 and can be used with:
  - iOS 11.2 and higher (iOS 13 support is under development);
  - iPhone 6s or newer.
  
You can find all requirements at [Documentation page](https://docs.mapbox.com/ios/vision/overview/#requirements).

## Build process

To set up the Vision SDK you will need to download the SDK, install the frameworks relevant to your project, and complete a few configuration steps. You can find all details at [Documentation page](https://docs.mapbox.com/ios/vision/overview/#getting-started).

# Documentation

The lastest version of documentation is available at [Vision's page](https://docs.mapbox.com/ios/vision).

# Contributing

Please see our contribution guide for more details about the process.

## Code of conduct

Everyone is invited to participate in Mapbox's open source projects and public discussions: we want to create a welcoming and friendly environment. Harassment of participants or other unethical and unprofessional behavior will not be tolerated in our spaces.

The [Contributor Covenant](https://www.contributor-covenant.org) applies to all projects under the Mapbox organization whether they explicitly include the Contributor Covenant's [CODE_OF_CONDUCT.md](https://www.contributor-covenant.org/version/1/4/code-of-conduct.html) or not.

# Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on repository](https://github.com/mapbox/mapbox-vision-ios/tags).

Changes in repository is in sync with changes in Vision Core library (which is under-the-hood of Vision SDK).

# License

For details, read our [terms of service](https://www.mapbox.com/tos/#vision) and [privacy policy](https://www.mapbox.com/privacy/).
