Feature: CAMARA QoS Booking and Assignment API, v0.2.0-rc.2 - Operation retrieveBookingByDevice
  # CAMARA Commonalities: 0.9.0
  #
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Scenarios marked as CONDITIONAL in their comments apply only if the implementation supports the option they test; the implementation informs the tester of the supported options.
  # * Supported booking confirmation mode(s) for createBooking: synchronous (SCHEDULED or ACTIVATED in the 201 response) and/or asynchronous (REQUESTED followed by a booking-status-changed event).
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address. networkAccessIdentifier is not currently supported by this API.
  #
  # Testing assets:
  # * A valid QoS profile name, and the maximum duration allowed for it.
  # * A valid service area compliant with the Area schema.
  # * At least two valid devices (device objects) applicable for the service, identified by identifier types supported by the implementation.
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable, if any.
  # * A 2-legged access token, and a 3-legged access token identifying a single device.
  # * A device with no QoS booking.
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment-wip-alignedto_r4dot4.yaml

  Background: Common "retrieveBookingByDevice" setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking-and-assignment/v0.2rc2/qos-bookings/retrieve"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/RetrieveBookingByDevice"

############################ Happy Path Scenarios #############################################

  @qos_booking_and_assignment_retrieveBookingByDevice_01_generic_success_scenario
  Scenario: Get the QoS bookings of a device using a 2-legged access token
    Given the header "Authorization" is set to a valid 2-legged access token
    And a valid testing device with an existing QoS booking created by operation "createBooking" and assigned by operation "assignDevices"
    And the request body property "$.device" is set to that device
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/RetrieveBookingsOutput"
    And the response body is a non-empty array of items compliant with the OAS schema at "#/components/schemas/BookingDetails"
    And the response property "$[0].bookingId" exists and is a valid UUID
    And the response property "$[0].qosProfile" has the value provided for createBooking
    And the response property "$[0].startTime" has the value provided for createBooking
    And the response property "$[0].duration" has the value provided for createBooking
    And the response property "$[0].serviceArea" has the value provided for createBooking

  @qos_booking_and_assignment_retrieveBookingByDevice_02_three_legged_token
  Scenario: Get the QoS bookings of the device identified by a 3-legged access token
    Given the header "Authorization" is set to a valid 3-legged access token identifying a device with an existing QoS booking
    And the request body property "$.device" is not included
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/RetrieveBookingsOutput"
    And the response body is a non-empty array of items compliant with the OAS schema at "#/components/schemas/BookingDetails"

  @qos_booking_and_assignment_retrieveBookingByDevice_03_no_bookings_for_device
  Scenario: No QoS bookings exist for the device
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.device" is set to a valid device with no QoS booking
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body is an empty array "[]"

  @qos_booking_and_assignment_retrieveBookingByDevice_04_multiple_bookings_for_device
  Scenario: Several QoS bookings exist for the device
    Given the header "Authorization" is set to a valid 2-legged access token
    And a valid testing device assigned to at least two QoS bookings created by operation "createBooking"
    And the request body property "$.device" is set to that device
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response body is an array with at least two items compliant with the OAS schema at "#/components/schemas/BookingDetails"
    And the response body contains the "bookingId" of each of those QoS bookings

############################ Error Scenarios #############################################

  # Syntax Error scenarios

  # applicable for operations with a mandatory request body
  @qos_booking_and_assignment_retrieveBookingByDevice_400.1_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_retrieveBookingByDevice_400.2_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "#/components/schemas/RetrieveBookingByDevice"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_retrieveBookingByDevice_400.3_invalid_x-correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The API rejects undeclared properties (see section Request body strictness of the API description)
  @qos_booking_and_assignment_retrieveBookingByDevice_400.4_unknown_property
  Scenario: Request body contains a property not declared in the schema
    Given the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Service Error scenarios

  ## Authentication/Authorization errors

    # Generic 401 errors

  @qos_booking_and_assignment_retrieveBookingByDevice_401.1_no_authorization_header
  Scenario: Error response for no header Authorization
    Given the header "Authorization" is not sent
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_retrieveBookingByDevice_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_retrieveBookingByDevice_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 403 errors

  @qos_booking_and_assignment_retrieveBookingByDevice_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking-and-assignment:qos-bookings:retrieve-by-device"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Device error scenarios (Commonalities C01 - device errors)

  @qos_booking_and_assignment_retrieveBookingByDevice_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to: {}
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_retrieveBookingByDevice_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | device_identifier                | oas_spec_schema                              |
      | $.device.phoneNumber             | #/components/schemas/PhoneNumber             |
      | $.device.ipv4Address             | #/components/schemas/DeviceIpv4Address       |
      | $.device.ipv6Address             | #/components/schemas/DeviceIpv6Address       |
      | $.device.networkAccessIdentifier | #/components/schemas/NetworkAccessIdentifier |

  @qos_booking_and_assignment_retrieveBookingByDevice_C01.03_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is set to a valid device
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_retrieveBookingByDevice_C01.04_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # CONDITIONAL: networkAccessIdentifier is not currently supported by this API, so it can be used as the unsupported identifier
  @qos_booking_and_assignment_retrieveBookingByDevice_C01.05_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # CONDITIONAL: only applicable when the service is offered to certain types of devices or subscriptions
  @qos_booking_and_assignment_retrieveBookingByDevice_C01.06_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  # Generic 429 errors

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @qos_booking_and_assignment_retrieveBookingByDevice_429.1_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given a valid request for "retrieveBookingByDevice"
    And the header "Authorization" is set to a valid access token
    And the threshold of requests has been reached
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
