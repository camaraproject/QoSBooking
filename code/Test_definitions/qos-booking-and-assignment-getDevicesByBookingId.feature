Feature: CAMARA QoS Booking and Assignment API, vwip - Operation getDevicesByBookingId
  # CAMARA Commonalities: 0.9.0
  #
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Scenarios marked as CONDITIONAL in their comments apply only if the implementation supports the option they test; the implementation informs the tester of the supported options.
  #
  # Testing assets:
  # * A valid QoS profile name, and the maximum duration allowed for it.
  # * A valid service area compliant with the Area schema.
  # * At least two valid devices (device objects) applicable for the service, identified by identifier types supported by the implementation.
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable, if any.
  # * A 2-legged access token, and a 3-legged access token identifying a single device.
  # * An access token emitted to a different API client than the one that created the QoS booking.
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment.yaml

  Background: Common "getDevicesByBookingId" setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the path parameter "bookingId" is set by default to the identifier of an existing QoS booking created by operation "createBooking" with devices assigned by operation "assignDevices"

############################ Happy Path Scenarios #############################################

  @qos_booking_and_assignment_getDevicesByBookingId_01_generic_success_scenario
  Scenario Outline: Common validations for any success scenario
    Given an existing QoS booking with devices assigned by operation "assignDevices"
    And the path parameter "bookingId" is set to the value of the identifier for that QoS booking
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    # Additionally, any success response has to comply with some constraints beyond the schema compliance
    And the response property "<property>" matches the rule: <condition>

    Examples:
      | property                   | condition                                                                     |
      | $.assignmentStatus         | is "ASSIGNED"                                                                 |
      | $.bookingDetails.bookingId | same value as the path parameter "bookingId"                                  |
      | $.devices                  | contains one or more device identifiers set originally during "assignDevices" |

  # CONDITIONAL: only applicable if the API provider withholds device identifiers under a disclosure policy
  @qos_booking_and_assignment_getDevicesByBookingId_02_device_disclosure_policy_applied
  Scenario: Device identifiers are withheld due to privacy or legal requirements
    Given an existing QoS booking with devices assigned, some of which cannot be disclosed due to privacy or legal requirements
    And the path parameter "bookingId" is set to the value of the identifier for that QoS booking
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.statusInfo" is "DEVICE_DISCLOSURE_POLICY_APPLIED"
    And the number of device identifiers in "$.devices" is lower than the number of devices assigned to the booking
    And the number of devices assigned to the booking is the difference between "$.bookingDetails.bookingDeviceCount" and "$.bookingDetails.remainingDevices"

############################ Error Scenarios #############################################

  # Syntax Error scenarios

  @qos_booking_and_assignment_getDevicesByBookingId_400.1_invalid_booking_id
  Scenario: Invalid bookingId path parameter
    Given the path parameter "bookingId" is set to a value that is not a valid UUID
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_getDevicesByBookingId_400.2_invalid_x-correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Service Error scenarios

  ## Authentication/Authorization errors

    # Generic 401 errors

  @qos_booking_and_assignment_getDevicesByBookingId_401.1_no_authorization_header
  Scenario: Error response for no header Authorization
    Given the header "Authorization" is not sent
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_getDevicesByBookingId_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_getDevicesByBookingId_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 403 errors

  @qos_booking_and_assignment_getDevicesByBookingId_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking-and-assignment:qos-bookings:devices:read"
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # To test this, a token has to be obtained for a different client
  @qos_booking_and_assignment_getDevicesByBookingId_403.2_api_client_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    Given the header "Authorization" is set to a valid access token emitted to an API client which did not create the QoS booking
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Generic 404 errors

  @qos_booking_and_assignment_getDevicesByBookingId_404.1_not_found
  Scenario: Non-existing "bookingId"
    Given the path parameter "bookingId" is set to a random UUID that does not correspond to any existing QoS booking
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Generic 429 errors

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @qos_booking_and_assignment_getDevicesByBookingId_429.1_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given a valid request for "getDevicesByBookingId"
    And the header "Authorization" is set to a valid access token
    And the threshold of requests has been reached
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
