# Changelog QoS Booking

## Table of contents

- **[r1.2](#r12) (Fall25 public release)**
- [r1.1](#r11)

**Please be aware that the project will have frequent updates to the main branch. There are no compatibility guarantees associated with code in any branch, including main, until it has been released. For example, changes may be reverted before a release is published. For the best results, use the latest published release.**

The below sections record the changes for each API version in each release as follows:

* for an alpha release, the delta with respect to the previous release
* for the first release-candidate, all changes since the last public release
* for subsequent release-candidate(s), only the delta to the previous release-candidate
* for a public release, the consolidated changes since the previous public release

# r1.2

## Release Notes

This release contains the definition and documentation of
* qos-booking v0.1.0
* qos-booking-and-assignment v0.1.0

The API definition(s) are based on
* Commonalities v0.6.0 (r3.3)
* Identity and Consent Management v0.4.0 (r3.3)

## qos-booking v0.1.0

**qos-booking v0.1.0 is the first initial release of this new API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking.yaml&nocors)
  - [View it on Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/QoSBooking/blob/r1.2/code/API_definitions/qos-booking.yaml)

### Added
* N/A 

### Changed
* N/A

### Fixed
* Align qos-booking with Commonalities r3.3 by @jlurien in [#40](https://github.com/camaraproject/QoSBooking/pull/40)
* Fix files of qos-booking for compliance with centralised linting rules by @Masa8106 in [#41](https://github.com/camaraproject/QoSBooking/pull/41)

### Removed
* N/A

## qos-booking-and-assignment v0.1.0

**qos-booking-and-assignment v0.1.0 is the first initial release of this new API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking-and-assignment.yaml&nocors)
  - [View it on Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking-and-assignment.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/QoSBooking/blob/r1.2/code/API_definitions/qos-booking-and-assignment.yaml)

### Added
* Added examples to address the issue #33 by @RamTMO in [#35](https://github.com/camaraproject/QoSBooking/pull/35)

### Changed
* N/A

### Fixed
* Fix DeviceResponse Issue #30 in QoS Booking and Assignment by @RmaTMO in [#34](https://github.com/camaraproject/QoSBooking/pull/34)
* Align qos-booking with Commonalities r3.3 by @jlurien in [#40](https://github.com/camaraproject/QoSBooking/pull/40)
* Update qos-booking-and-assignment.yaml to support issues by @RmaTMO in [#43](https://github.com/camaraproject/QoSBooking/pull/43)
* Fix DeviceCount related issues by @RmaTMO in [#48](https://github.com/camaraproject/QoSBooking/pull/48)
* bookingId related issues & remaining linting issues by @RmaTMO in [#50](https://github.com/camaraproject/QoSBooking/pull/50)

### Removed
* Remove unnecessary spaces, tabs, lfs in qos-booking-and-assignment.feature file by @RmaTMO in #44
  
# r1.1

## Release Notes

This release contains the definition and documentation of
* qos-booking v0.1.0-rc.1
* qos-booking-and-assignment v0.1.0-rc.1

The API definition(s) are based on
* Commonalities r3.2
* Identity and Consent Management r3.2

## qos-booking v0.1.0-rc.1

**qos-booking v0.1.0-rc.1 is the first release-candidate version for v0.1.0 of QoS Booking API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.1/code/API_definitions/qos-booking.yaml&nocors)
  - [View it on Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.1/code/API_definitions/qos-booking.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/QoSBooking/blob/r1.1/code/API_definitions/qos-booking.yaml)

### Added
* Initial contribution of the QoS Booking API 

## qos-booking-and-assignment v0.1.0-rc.1

**qos-booking-and-assignment v0.1.0-rc.1 is the first release-candidate version for v0.1.0 of QoS Booking And Assignment API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.1/code/API_definitions/qos-booking-and-assignment.yaml&nocors)
  - [View it on Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.1/code/API_definitions/qos-booking-and-assignment.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/QoSBooking/blob/r1.1/code/API_definitions/qos-booking-and-assignment.yaml)

### Added
* Initial contribution of the QoS Booking and Assignment API
