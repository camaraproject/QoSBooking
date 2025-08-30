<a href="https://github.com/camaraproject/QoSBooking/commits/" title="Last Commit"><img src="https://img.shields.io/github/last-commit/camaraproject/QoSBooking?style=plastic"></a>
<a href="https://github.com/camaraproject/QoSBooking/issues" title="Open Issues"><img src="https://img.shields.io/github/issues/camaraproject/QoSBooking?style=plastic"></a>
<a href="https://github.com/camaraproject/QoSBooking/pulls" title="Open Pull Requests"><img src="https://img.shields.io/github/issues-pr/camaraproject/QoSBooking?style=plastic"></a>
<a href="https://github.com/camaraproject/QoSBooking/graphs/contributors" title="Contributors"><img src="https://img.shields.io/github/contributors/camaraproject/QoSBooking?style=plastic"></a>
<a href="https://github.com/camaraproject/QoSBooking" title="Repo Size"><img src="https://img.shields.io/github/repo-size/camaraproject/QoSBooking?style=plastic"></a>
<a href="https://github.com/camaraproject/QoSBooking/blob/main/LICENSE" title="License"><img src="https://img.shields.io/badge/License-Apache%202.0-green.svg?style=plastic"></a>
<a href="https://github.com/camaraproject/QoSBooking/releases/latest" title="Latest Release"><img src="https://img.shields.io/github/release/camaraproject/QoSBooking?style=plastic"></a>
<a href="https://github.com/camaraproject/Governance/blob/main/ProjectStructureAndRoles.md" title="Sandbox API Repository"><img src="https://img.shields.io/badge/Sandbox%20API%20Repository-yellow?style=plastic"></a>

# QoSBooking

Sandbox API Repository to describe, develop, document, and test the QoSBooking Service API(s) within the Sub Project [QualityOnDemand](https://lf-camaraproject.atlassian.net/wiki/x/XCPe)

* API Repository [wiki page](https://lf-camaraproject.atlassian.net/wiki/x/SADHB)

## Scope

* Service API(s) “QoSBooking” (see APIBacklog.md) 
* The API(s) provide(s) the API consumer with the ability to:  
  * book an assignment of a certain QoS Profile to a certain device with some conditions such as start time, duration and location in advance.
  * update the booking, remove it, and get the information of it.
* Describe, develop, document, and test the API(s)
* Started: January 2025
<!-- * Incubated since: §incubation date$ --> 

## Release Information

* Note: Please be aware that the project will have updates to the main branch. There are no compatibility guarantees associated with code in any branch, including main, until a new release is created. For example, changes may be reverted before a release is created. For best results, use the latest available release.

* **NEW**: **The latest public release is [r1.2](https://github.com/camaraproject/QoSBooking/releases/tag/r1.2), with the following API versions:**

    - qos-booking 0.1.0 (booking QoS for a single device for a certain time and area)<br>[YAML spec file](https://github.com/camaraproject/QoSBooking/blob/r1.2/code/API_definitions/qos-booking.yaml) | [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking.yaml&nocors) | [View it on Swagger Editor](https://camaraproject.github.io/swagger-ui/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking.yaml&nocors)
    - qos-booking-and-assignment 0.1.0 (booking QoS for multiple devices for a certain time and area, and assignment of devices to the booking, e.g. on a later time)<br>[YAML spec file](https://github.com/camaraproject/QoSBooking/blob/r1.2/code/API_definitions/qos-booking-and-assignment.yaml) | [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking-and-assignment.yaml&nocors) | [View it on Swagger Editor](https://camaraproject.github.io/swagger-ui/?url=https://raw.githubusercontent.com/camaraproject/QoSBooking/r1.2/code/API_definitions/qos-booking-and-assignment.yaml&nocors)

## Contributing
* Meetings are held virtually 
    * Schedule: Bi-weekly on Friday at 13:00 UTC
    * [Registration / Join](https://zoom-lfx.platform.linuxfoundation.org/meeting/94112812156?password=f238d6af-c959-48d7-a862-abdb3c648e40)
    * Minutes: Access [meeting minutes](https://lf-camaraproject.atlassian.net/wiki/x/ABje)
* Mailing List
    * Subscribe / Unsubscribe to the mailing list <https://lists.camaraproject.org/g/sp-qod>.
    * A message to the community of this Sub Project can be sent using <sp-qod@lists.camaraproject.org>.
