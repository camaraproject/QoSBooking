Feature: CAMARA QoS Booking and Assignment API, vwip - Operation releaseDevices
  # CAMARA Commonalities: 0.9.0
  #
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Scenarios marked as CONDITIONAL in their comments apply only if the implementation supports the option they test; the implementation informs the tester of the supported options.
  # * Whether event notification delivery is supported for the sink registered with createBooking.
  # * Whether releaseDevices is resolved synchronously (200), asynchronously (202 followed by an assignment-status-changed event) or both.
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address. networkAccessIdentifier is not currently supported by this API.
  #
  # Testing assets:
  # * A valid QoS profile name, and the maximum duration allowed for it.
  # * A valid service area compliant with the Area schema.
  # * At least two valid devices (device objects) applicable for the service, identified by identifier types supported by the implementation.
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable, if any.
  # * A 2-legged access token, and a 3-legged access token identifying a single device.
  # * An https endpoint able to receive CloudEvents, with a valid access token to be used as sinkCredential (credentialType ACCESSTOKEN) when creating the QoS booking.
  # * An access token emitted to a different API client than the one that created the QoS booking.
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment.yaml

  Background: Common "releaseDevices" setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices/release"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the path parameter "bookingId" is set by default to the identifier of an existing QoS booking created by operation "createBooking" with devices assigned by operation "assignDevices"
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/DeviceAssignmentInput"

############################ Happy Path Scenarios #############################################

  @qos_booking_and_assignment_releaseDevices_01_generic_success_scenario
  Scenario Outline: Common validations for any success scenario
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.devices" is set to a valid array of device identifiers that are assigned to the QoS booking
    When the request "releaseDevices" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    # Additionally, any success response has to comply with some constraints beyond the schema compliance
    And the response property "<property>" matches the rule: <condition>

    Examples:
      | property                          | condition                                                                               |
      | $.assignmentStatus                | is "RELEASED"                                                                           |
      | $.devices                         | contains the device identifiers released from the QoS booking                           |
      | $.bookingDetails.bookingId        | same value as the path parameter "bookingId"                                            |
      | $.bookingDetails.remainingDevices | increased by the number of released devices, compared with its value before the request |

  @qos_booking_and_assignment_releaseDevices_02_three_legged_token
  Scenario: Release the device identified by a 3-legged access token
    Given the header "Authorization" is set to a valid 3-legged access token identifying a single device assigned to the QoS booking
    And the request body property "$.devices" is not included
    When the request "releaseDevices" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.assignmentStatus" is "RELEASED"
    And the response property "$.bookingDetails.remainingDevices" is increased by 1

  @qos_booking_and_assignment_releaseDevices_03_released_devices_not_listed
  Scenario: Released devices are no longer returned by getDevicesByBookingId
    Given the header "Authorization" is set to a valid 2-legged access token
    And devices assigned to the QoS booking have been released with operation "releaseDevices"
    And the path parameter "bookingId" is set to the identifier of that QoS booking
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 200
    And the response property "$.devices" does not contain any of the released device identifiers

  # CONDITIONAL: only applicable if the API provider supports partial release
  @qos_booking_and_assignment_releaseDevices_04_partial_success
  Scenario: Only some of the requested devices can be released
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.devices" includes devices assigned to the QoS booking and at least one device that cannot be released
    When the request "releaseDevices" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.assignmentStatus" is "PARTIAL_SUCCESS"
    And the response property "$.statusInfo" exists
    And the response property "$.devices" contains only the device identifiers that were released

  # CONDITIONAL: only applicable if the API provider resolves releases asynchronously
  @qos_booking_and_assignment_releaseDevices_05_asynchronous_processing
  Scenario: Release accepted for asynchronous processing
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.devices" is set to a valid array of device identifiers that are assigned to the QoS booking
    When the request "releaseDevices" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.assignmentStatus" is "REQUESTED"

  # CONDITIONAL: only applicable if the API provider resolves releases asynchronously and supports event notifications
  @qos_booking_and_assignment_releaseDevices_06_event_notification
  Scenario: Event is received when the release outcome is known after using sink
    Given the QoS booking has been created with operation "createBooking" and includes a valid sink and sinkCredentials
    And a device release has been accepted for asynchronous processing (status code 202) with operation "releaseDevices"
    When the release outcome is known
    Then an event is received at the address of the createBooking request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the createBooking request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "#/components/schemas/EventAssignmentStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking-and-assignment.v0.assignment-status-changed"
    And the event body property "$.data.deviceDetails.bookingDetails.bookingId" has the same value as the path parameter "bookingId" of the request
    And the event body property "$.data.deviceDetails.assignmentStatus" is "RELEASED", "PARTIAL_SUCCESS" or "FAILURE"

############################ Error Scenarios #############################################

  # Syntax Error scenarios

  # applicable for operations with a mandatory request body
  @qos_booking_and_assignment_releaseDevices_400.1_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_400.2_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "#/components/schemas/DeviceAssignmentInput"
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_400.3_empty_property
  Scenario Outline: Error response for empty property in request body
    Given the request body property "<property>" is set to <value>
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | property  | value |
      | $.devices | []    |

  @qos_booking_and_assignment_releaseDevices_400.4_invalid_booking_id
  Scenario: Invalid bookingId path parameter
    Given the path parameter "bookingId" is set to a value that is not a valid UUID
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_400.5_invalid_x-correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The API rejects undeclared properties (see section Request body strictness of the API description)
  @qos_booking_and_assignment_releaseDevices_400.6_unknown_property
  Scenario: Request body contains a property not declared in the schema
    Given the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The maximum is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @qos_booking_and_assignment_releaseDevices_400.7_too_many_devices
  Scenario: The devices array exceeds the maximum of 50
    Given the request body property "$.devices" is set to an array of 51 valid device identifiers compliant with the schema at "#/components/schemas/Device"
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Service Error scenarios

  ## Authentication/Authorization errors

    # Generic 401 errors

  @qos_booking_and_assignment_releaseDevices_401.1_no_authorization_header
  Scenario: Error response for no header Authorization
    Given the header "Authorization" is not sent
    When the request "releaseDevices" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "releaseDevices" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "releaseDevices" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 403 errors

  @qos_booking_and_assignment_releaseDevices_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking-and-assignment:qos-bookings:devices:delete"
    When the request "releaseDevices" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # To test this, a token has to be obtained for a different client
  @qos_booking_and_assignment_releaseDevices_403.2_api_client_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    Given the header "Authorization" is set to a valid access token emitted to an API client which did not create the QoS booking
    When the request "releaseDevices" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Generic 404 errors

  @qos_booking_and_assignment_releaseDevices_404.1_not_found
  Scenario: Non-existing "bookingId"
    Given the path parameter "bookingId" is set to a random UUID that does not correspond to any existing QoS booking
    When the request "releaseDevices" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Generic 409 errors

  # CONDITIONAL: only applicable if the API provider does not allow concurrent modifications of the same booking
  @qos_booking_and_assignment_releaseDevices_409.1_request_aborted
  Scenario: Conflict due to the QoS booking being modified by a concurrent request
    Given a concurrent assignment or release operation is in progress for the same QoS booking and the service does not allow concurrent modifications
    When the request "releaseDevices" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "ABORTED"
    And the response property "$.message" contains a user friendly text

  # The terminated booking must not yet have been deleted (it is kept for at least 360 seconds after reaching TERMINATED)
  @qos_booking_and_assignment_releaseDevices_409.2_incompatible_state
  Scenario: Conflict due to the QoS booking being in an incompatible state
    Given the path parameter "bookingId" is set to the identifier of a QoS booking in status "TERMINATED" that has not yet been deleted
    When the request "releaseDevices" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "INCOMPATIBLE_STATE"
    And the response property "$.message" contains a user friendly text

  # Device error scenarios (Commonalities C01 - device errors)

  @qos_booking_and_assignment_releaseDevices_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices[0]" is set to: {}
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "releaseDevices" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | device_identifier                    | oas_spec_schema                              |
      | $.devices[0].phoneNumber             | #/components/schemas/PhoneNumber             |
      | $.devices[0].ipv4Address             | #/components/schemas/DeviceIpv4Address       |
      | $.devices[0].ipv6Address             | #/components/schemas/DeviceIpv6Address       |
      | $.devices[0].networkAccessIdentifier | #/components/schemas/NetworkAccessIdentifier |

  # The 404 IDENTIFIER_NOT_FOUND is declared for this operation. Devices that cannot be processed once the request is accepted are reported with assignmentStatus and statusInfo (e.g. DEVICE_NOT_FOUND)
  @qos_booking_and_assignment_releaseDevices_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices[0]" is compliant with the schema but does not identify a valid device
    When the request "releaseDevices" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.devices[0]" is set to a valid device
    When the request "releaseDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_releaseDevices_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices" is not included
    When the request "releaseDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # CONDITIONAL: networkAccessIdentifier is not currently supported by this API, so it can be used as the unsupported identifier
  @qos_booking_and_assignment_releaseDevices_C01.06_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices[0]" only includes device identifiers not supported by the implementation
    When the request "releaseDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # CONDITIONAL: only applicable when the service is offered to certain types of devices or subscriptions
  @qos_booking_and_assignment_releaseDevices_C01.07_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "releaseDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  # Generic 429 errors

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @qos_booking_and_assignment_releaseDevices_429.1_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given a valid request for "releaseDevices"
    And the header "Authorization" is set to a valid access token
    And the threshold of requests has been reached
    When the request "releaseDevices" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
