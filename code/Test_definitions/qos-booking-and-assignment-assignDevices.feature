Feature: CAMARA QoS Booking and Assignment API, v0.2.0-rc.2 - Operation assignDevices
  # CAMARA Commonalities: 0.9.0
  #
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Scenarios marked as CONDITIONAL in their comments apply only if the implementation supports the option they test; the implementation informs the tester of the supported options.
  # * Whether event notification delivery (sink) is supported. If not, the scenarios for 422 EVENT_NOTIFICATIONS_NOT_SUPPORTED apply.
  # * Whether assignDevices is resolved synchronously (201), asynchronously (202 followed by an assignment-status-changed event) or both.
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address. networkAccessIdentifier is not currently supported by this API.
  #
  # Testing assets:
  # * A valid QoS profile name, and the maximum duration allowed for it.
  # * A valid service area compliant with the Area schema.
  # * At least two valid devices (device objects) applicable for the service, identified by identifier types supported by the implementation.
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable, if any.
  # * A 2-legged access token, and a 3-legged access token identifying a single device.
  # * An https endpoint able to receive CloudEvents, with a valid access token to be used as sinkCredential (credentialType ACCESSTOKEN).
  # * An access token emitted to a different API client than the one that created the QoS booking.
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment-wip-alignedto_r4dot4.yaml

  Background: Common "assignDevices" setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking-and-assignment/v0.2rc2/qos-bookings/{bookingId}/devices/assign"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the path parameter "bookingId" is set by default to the identifier of an existing QoS booking created by operation "createBooking", in status "SCHEDULED" or "ACTIVATED", with remaining device capacity
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/DeviceAssignmentInput"

############################ Happy Path Scenarios #############################################

  @qos_booking_and_assignment_assignDevices_01_generic_success_scenario
  Scenario Outline: Common validations for any success scenario
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.devices" is set to a valid array of device identifiers compliant with the schema at "#/components/schemas/Devices"
    When the request "assignDevices" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    # Additionally, any success response has to comply with some constraints beyond the schema compliance
    And the response property "<property>" matches the rule: <condition>

    Examples:
      | property                          | condition                                                                                    |
      | $.assignmentStatus                | is "ASSIGNED"                                                                                |
      | $.devices                         | exists and contains the same or a subset of the device identifiers given in the request body |
      | $.bookingDetails.bookingId        | same value as the path parameter "bookingId"                                                 |
      | $.bookingDetails.remainingDevices | decreased by the number of assigned devices, compared with its value before the request      |

  @qos_booking_and_assignment_assignDevices_02_three_legged_token
  Scenario: Assign the device identified by a 3-legged access token
    Given the header "Authorization" is set to a valid 3-legged access token identifying a single device
    And the request body property "$.devices" is not included
    When the request "assignDevices" is sent
    Then the response status code is 201
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.assignmentStatus" is "ASSIGNED"
    And the response property "$.bookingDetails.remainingDevices" is decreased by 1
    And the response property "$.devices" may not contain the assigned device information

  @qos_booking_and_assignment_assignDevices_03_assigned_devices_listed
    Scenario: Assigned devices are returned by getDevicesByBookingId
    Given the header "Authorization" is set to a valid 2-legged access token
    And devices have been assigned to the QoS booking with operation "assignDevices" using a valid array of device identifiers compliant with the schema at "#/components/schemas/Devices"
    And the path parameter "bookingId" is set to the identifier of that QoS booking
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 200
    And the response property "$.devices" contains the device identifiers returned by the assignDevices response

  # CONDITIONAL: only applicable if the API provider supports partial assignment
  @qos_booking_and_assignment_assignDevices_04_partial_success
  Scenario: Only some of the requested devices can be assigned
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.devices" includes valid devices and at least one device that cannot be assigned
    When the request "assignDevices" is sent
    Then the response status code is 201
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.assignmentStatus" is "PARTIAL_SUCCESS"
    And the response property "$.statusInfo" exists
    And the response property "$.devices" contains only a subset of the device identifiers given in the request body

  # CONDITIONAL: only applicable if the API provider resolves assignments asynchronously
  @qos_booking_and_assignment_assignDevices_05_asynchronous_processing
  Scenario: Assignment accepted for asynchronous processing
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request body property "$.devices" is set to a valid array of device identifiers compliant with the schema at "#/components/schemas/Devices"
    When the request "assignDevices" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceAssignmentOutput"
    And the response property "$.assignmentStatus" is "REQUESTED"

  # CONDITIONAL: only applicable if the API provider resolves assignments asynchronously and supports event notifications
  @qos_booking_and_assignment_assignDevices_06_event_notification
  Scenario: Event is received when the assignment outcome is known after using sink
    Given a device assignment has been accepted for asynchronous processing (status code 202) with operation "assignDevices"
    And the request included a valid sink and sinkCredentials
    When the assignment outcome is known
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "#/components/schemas/EventAssignmentStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking-and-assignment.v0.assignment-status-changed"
    And the event body property "$.data.deviceDetails.bookingDetails.bookingId" has the same value as the path parameter "bookingId" of the request
    And the event body property "$.data.assignmentStatus" is "ASSIGNED", "PARTIAL_SUCCESS" or "FAILURE"

############################ Error Scenarios #############################################

  # Syntax Error scenarios

  # applicable for operations with a mandatory request body
  @qos_booking_and_assignment_assignDevices_400.1_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_400.2_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "#/components/schemas/DeviceAssignmentInput"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_400.3_empty_property
  Scenario Outline: Error response for empty property in request body
    Given the request body property "<property>" is set to <value>
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | property         | value |
      | $.devices        | []    |
      | $.sinkCredential | {}    |

  @qos_booking_and_assignment_assignDevices_400.4_invalid_booking_id
  Scenario: Invalid bookingId path parameter
    Given the path parameter "bookingId" is set to a value that is not a valid UUID
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_400.5_invalid_x-correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # PLAIN and REFRESHTOKEN are not valid credentialType values in the common SinkCredential schema, so a schema validator may fail
  # the request with INVALID_ARGUMENT instead of INVALID_CREDENTIAL, and both could be accepted
  @qos_booking_and_assignment_assignDevices_400.6_invalid_sink_credential
  Scenario Outline: Invalid credential
    Given the request body property "$.sinkCredential.credentialType" is set to "<unsupported_credential_type>"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_CREDENTIAL" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | unsupported_credential_type |
      | PLAIN                       |
      | REFRESHTOKEN                |

  # Only "bearer" is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @qos_booking_and_assignment_assignDevices_400.7_sink_credential_invalid_token
  Scenario: Invalid token
    Given the request body property "$.sinkCredential.accessTokenType" is set to a value other than "bearer"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_TOKEN" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The sink must be an https URL. A generic schema validator may report INVALID_ARGUMENT instead of INVALID_SINK, and both could be accepted
  @qos_booking_and_assignment_assignDevices_400.8_invalid_sink
  Scenario Outline: Invalid sink
    Given the request body property "$.sink" is set to "<invalid_sink>"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_SINK" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | invalid_sink                     |
      | http://endpoint.example.com/sink |
      | ftp://endpoint.example.com/sink  |

  # The API rejects undeclared properties (see section Request body strictness of the API description)
  @qos_booking_and_assignment_assignDevices_400.9_unknown_property
  Scenario: Request body contains a property not declared in the schema
    Given the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The maximum is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @qos_booking_and_assignment_assignDevices_400.10_too_many_devices
  Scenario: The devices array exceeds the maximum of 50
    Given the request body property "$.devices" is set to an array of 51 valid device identifiers compliant with the schema at "#/components/schemas/Device"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Service Error scenarios

  ## Authentication/Authorization errors

    # Generic 401 errors

  @qos_booking_and_assignment_assignDevices_401.1_no_authorization_header
  Scenario: Error response for no header Authorization
    Given the header "Authorization" is not sent
    When the request "assignDevices" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "assignDevices" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "assignDevices" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 403 errors

  @qos_booking_and_assignment_assignDevices_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking-and-assignment:qos-bookings:devices:create"
    When the request "assignDevices" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # To test this, a token has to be obtained for a different client
  @qos_booking_and_assignment_assignDevices_403.2_api_client_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    Given the header "Authorization" is set to a valid access token emitted to an API client which did not create the QoS booking
    When the request "assignDevices" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Generic 404 errors

  @qos_booking_and_assignment_assignDevices_404.1_not_found
  Scenario: Non-existing "bookingId"
    Given the path parameter "bookingId" is set to a random UUID that does not correspond to any existing QoS booking
    When the request "assignDevices" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Generic 409 errors

  # CONDITIONAL: only applicable if the API provider does not allow concurrent modifications of the same booking
  @qos_booking_and_assignment_assignDevices_409.1_request_aborted
  Scenario: Conflict due to the QoS booking being modified by a concurrent request
    Given a concurrent assignment or release operation is in progress for the same QoS booking and the service does not allow concurrent modifications
    When the request "assignDevices" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "ABORTED"
    And the response property "$.message" contains a user friendly text

  # Devices can only be assigned to a booking in status SCHEDULED or ACTIVATED
  @qos_booking_and_assignment_assignDevices_409.2_incompatible_state
  Scenario: Conflict due to the QoS booking being in an incompatible state
    Given the path parameter "bookingId" is set to the identifier of a QoS booking in status "TERMINATED"
    When the request "assignDevices" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "INCOMPATIBLE_STATE"
    And the response property "$.message" contains a user friendly text

  # Device error scenarios (Commonalities C01 - device errors)

  @qos_booking_and_assignment_assignDevices_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices[0]" is set to: {}
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "assignDevices" is sent
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
  @qos_booking_and_assignment_assignDevices_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices[0]" is compliant with the schema but does not identify a valid device
    When the request "assignDevices" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.devices[0]" is set to a valid device
    When the request "assignDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_assignDevices_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices" is not included
    When the request "assignDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # CONDITIONAL: networkAccessIdentifier is not currently supported by this API, so it can be used as the unsupported identifier
  @qos_booking_and_assignment_assignDevices_C01.06_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.devices[0]" only includes device identifiers not supported by the implementation
    When the request "assignDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # CONDITIONAL: only applicable when the service is offered to certain types of devices or subscriptions
  @qos_booking_and_assignment_assignDevices_C01.07_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "assignDevices" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  # 422 errors

  # CONDITIONAL: only applicable if the API provider does not implement event notification delivery
  # The resource MUST NOT be created when the request is rejected
  @qos_booking_and_assignment_assignDevices_422.1_event_notifications_not_supported
  Scenario: Event notifications capability not supported
    Given the request body includes property "$.sink" with a valid value
    And the API provider does not implement event notifications delivery for the operation "assignDevices"
    When the request "assignDevices" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "EVENT_NOTIFICATIONS_NOT_SUPPORTED"
    And the response property "$.message" contains a user friendly text

  # N+1 must not exceed 50, the maximum size of the devices array
  @qos_booking_and_assignment_assignDevices_422.2_device_quota_exceeded
  Scenario: The number of devices exceeds the remaining capacity of the QoS booking
    Given the header "Authorization" is set to a valid 2-legged access token
    And the path parameter "bookingId" is set to the identifier of a QoS booking with N remaining devices
    And the request body property "$.devices" is set to an array of N+1 valid device identifiers compliant with the schema at "#/components/schemas/Devices"
    When the request "assignDevices" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "QOS_BOOKING_AND_ASSIGNMENT.DEVICE_QUOTA_EXCEEDED"
    And the response property "$.message" contains a user friendly text

  # Generic 429 errors

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @qos_booking_and_assignment_assignDevices_429.1_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given a valid request for "assignDevices"
    And the header "Authorization" is set to a valid access token
    And the threshold of requests has been reached
    When the request "assignDevices" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
