Feature: CAMARA QoS Booking and Assignment API, v0.2.0-rc.2 - Operation createBooking
  # CAMARA Commonalities: 0.9.0
  #
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Scenarios marked as CONDITIONAL in their comments apply only if the implementation supports the option they test; the implementation informs the tester of the supported options.
  # * Supported booking confirmation mode(s) for createBooking: synchronous (SCHEDULED or ACTIVATED in the 201 response) and/or asynchronous (REQUESTED followed by a booking-status-changed event).
  # * Whether event notification delivery (sink) is supported. If not, the scenarios for 422 EVENT_NOTIFICATIONS_NOT_SUPPORTED apply.
  #
  # Testing assets:
  # * A valid QoS profile name, and the maximum duration allowed for it.
  # * A valid service area compliant with the Area schema.
  # * An https endpoint able to receive CloudEvents, with a valid access token to be used as sinkCredential (credentialType ACCESSTOKEN).
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment-wip-alignedto_r4dot4.yaml

  Background: Common "createBooking" setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking-and-assignment/v0.2rc2/qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/BookingInput"

############################ Happy Path Scenarios #############################################

  @qos_booking_and_assignment_createBooking_01_generic_success_scenario
  Scenario Outline: Common validations for any success scenario
    Given the request body property "$.qosProfile" is set to a valid QoS profile
    And the request body property "$.startTime" is set to a valid time in the future
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a valid service area compliant with the schema at "#/components/schemas/Area"
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/BookingOutput"
    # Additionally, any success response has to comply with some constraints beyond the schema compliance
    And the response property "<property>" matches the rule: <condition>

    Examples:
      | property             | condition                                                                           |
      | $.bookingId          | exists and is a valid UUID                                                          |
      | $.bookingStatus      | is "REQUESTED", "SCHEDULED" or "ACTIVATED"                                          |
      | $.qosProfile         | same value as in the request body                                                   |
      | $.startTime          | same value as in the request body                                                   |
      | $.duration           | same value as in the request body                                                   |
      | $.serviceArea        | same value as in the request body                                                   |
      | $.bookingDeviceCount | same value as in the request body, if provided                                      |
      | $.remainingDevices   | equal to "$.bookingDeviceCount" of the request body, or to 1 if it was not provided |
      | $.sink               | exists only if provided in the request body and with the same value                 |
      | $.sinkCredential     | does not exist                                                                      |

  @qos_booking_and_assignment_createBooking_02_all_optional_properties
  Scenario: Create a QoS booking providing all optional properties
    Given the request body property "$.bookingDeviceCount" is set to a valid number of devices
    And the request body property "$.sink" is set to a URL where events can be monitored
    And the request body property "$.sinkCredential.credentialType" is set to "ACCESSTOKEN"
    And the request body property "$.sinkCredential.accessToken" is set to a valid access token accepted by the events receiver
    And the request body property "$.sinkCredential.accessTokenType" is set to "bearer"
    And the request body property "$.sinkCredential.accessTokenExpiresUtc" is set to a value long enough in the future
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response body complies with the OAS schema at "#/components/schemas/BookingOutput"
    And the response property "$.bookingDeviceCount" has the same value as in the request body
    And the response property "$.remainingDevices" is equal to the value of "$.bookingDeviceCount"
    And the response property "$.sink" has same value as the request body property "$.sink"
    And the response property "$.sinkCredential" does not exist

  @qos_booking_and_assignment_createBooking_03_booking_device_count_limits
  Scenario Outline: Create a QoS booking with the minimum and maximum number of devices
    Given the request body property "$.bookingDeviceCount" is set to <count>
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response property "$.bookingDeviceCount" is <count>
    And the response property "$.remainingDevices" is <count>

    Examples:
      | count |
      | 1     |
      | 50    |

  # "REQUESTED" is only returned by implementations that confirm the booking asynchronously
  @qos_booking_and_assignment_createBooking_04_future_start_time
  Scenario: Booking with a start time in the future
    Given the request body property "$.startTime" is set to a valid time in the future
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response property "$.bookingStatus" is "SCHEDULED" or "REQUESTED"

  # "REQUESTED" is only returned by implementations that confirm the booking asynchronously
  @qos_booking_and_assignment_createBooking_05_immediate_start_time
  Scenario: Booking with a start time of now or in the past
    Given the request body property "$.startTime" is set to the current time or to a time in the past
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response property "$.bookingStatus" is "ACTIVATED" or "REQUESTED"

  # CONDITIONAL: only applicable if the API provider rejects unfulfillable bookings synchronously (e.g. SERVICE_NOT_AVAILABLE)
  @qos_booking_and_assignment_createBooking_06_synchronous_rejection
  Scenario: Booking that the operator cannot fulfil is terminated synchronously
    Given the API provider can determine synchronously that the booking cannot be fulfilled
    And the request body is compliant with the schema at "#/components/schemas/BookingInput" and requests a booking that cannot be fulfilled
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response body complies with the OAS schema at "#/components/schemas/BookingOutput"
    And the response property "$.bookingStatus" is "TERMINATED"
    And the response property "$.statusInfo" exists
    And the response property "$.bookingId" does not exist

  @qos_booking_and_assignment_createBooking_07_sink_echoed
  Scenario: Sink is returned in the creation response when event delivery is accepted
    Given the request body includes property "$.sink" with a valid value
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response property "$.sink" has same value as the request body property "$.sink"

  @qos_booking_and_assignment_createBooking_08_booking_readable_after_creation
  Scenario: The created booking can be read with getBookingById
    Given a QoS booking has been created successfully with operation "createBooking"
    And the path parameter "bookingId" is set to the value of "$.bookingId" of the createBooking response
    When the request "getBookingById" is sent
    Then the response status code is 200
    And the response property "$.bookingId" has the same value as in the createBooking response
    And the response property "$.qosProfile" has the same value as in the createBooking request body
    And the response property "$.startTime" has the same value as in the createBooking request body
    And the response property "$.duration" has the same value as in the createBooking request body
    And the response property "$.serviceArea" has the same value as in the createBooking request body

  @qos_booking_and_assignment_createBooking_09_event_notification
  Scenario: Event is received when a booking status changes after using sink
    Given a QoS booking has been created successfully with operation "createBooking" and includes a valid sink and sinkCredentials
    When the booking status changes (confirmation of a booking created with status REQUESTED, start time reached, or termination)
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "#/components/schemas/EventBookingStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking-and-assignment.v0.booking-status-changed"
    And the event body property "$.data.bookingDetails.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.bookingStatus" is "SCHEDULED", "ACTIVATED" or "TERMINATED"

############################ Error Scenarios #############################################

  # Syntax Error scenarios

  # applicable for operations with a mandatory request body
  @qos_booking_and_assignment_createBooking_400.1_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_createBooking_400.2_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "#/components/schemas/BookingInput"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The request body has required properties (qosProfile, startTime, duration, serviceArea)
  @qos_booking_and_assignment_createBooking_400.3_empty_request_body
  Scenario: Empty object as request body
    Given the request body is set to {}
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # applicable to properties in the request body which are of type object and have required properties in their value
  @qos_booking_and_assignment_createBooking_400.4_empty_property
  Scenario Outline: Error response for empty property in request body
    Given the request body property "<required_property>" is set to {}
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | required_property |
      | $.serviceArea     |
      | $.sinkCredential  |

  @qos_booking_and_assignment_createBooking_400.5_missing_required_property
  Scenario Outline: Error response for missing required property in request body
    Given the request body property "<required_property>" is not included
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | required_property |
      | $.qosProfile      |
      | $.startTime       |
      | $.duration        |
      | $.serviceArea     |

  # "2030-10-27T15:00:00" has no time zone; "ab" is shorter than the minimum length of qosProfile; "invalid profile!" has characters not allowed by its pattern
  @qos_booking_and_assignment_createBooking_400.6_invalid_property_value
  Scenario Outline: Error response for property values not compliant with the schema
    Given the request body property "<property>" is set to <value>
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | property             | value                 |
      | $.startTime          | "not-a-date-time"     |
      | $.startTime          | "2030-10-27T15:00:00" |
      | $.qosProfile         | "ab"                  |
      | $.qosProfile         | "invalid profile!"    |
      | $.duration           | "one hour"            |
      | $.bookingDeviceCount | "five"                |

  @qos_booking_and_assignment_createBooking_400.7_invalid_x-correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # PLAIN and REFRESHTOKEN are not valid credentialType values in the common SinkCredential schema, so a schema validator may fail
  # the request with INVALID_ARGUMENT instead of INVALID_CREDENTIAL, and both could be accepted
  @qos_booking_and_assignment_createBooking_400.8_invalid_sink_credential
  Scenario Outline: Invalid credential
    Given the request body property "$.sinkCredential.credentialType" is set to "<unsupported_credential_type>"
    When the request "createBooking" is sent
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
  @qos_booking_and_assignment_createBooking_400.9_sink_credential_invalid_token
  Scenario: Invalid token
    Given the request body property "$.sinkCredential.accessTokenType" is set to a value other than "bearer"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_TOKEN" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # The sink must be an https URL. A generic schema validator may report INVALID_ARGUMENT instead of INVALID_SINK, and both could be accepted
  @qos_booking_and_assignment_createBooking_400.10_invalid_sink
  Scenario Outline: Invalid sink
    Given the request body property "$.sink" is set to "<invalid_sink>"
    When the request "createBooking" is sent
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
  @qos_booking_and_assignment_createBooking_400.11_unknown_property
  Scenario: Request body contains a property not declared in the schema
    Given the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # bookingDeviceCount is limited to the range 1 to 50, duration has a minimum of 1 second
  # The maximum is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @qos_booking_and_assignment_createBooking_400.12_out_of_range
  Scenario Outline: Numeric property out of its declared range
    Given the request body property "<property>" is set to <value>
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | property             | value |
      | $.bookingDeviceCount | 0     |
      | $.bookingDeviceCount | 51    |
      | $.duration           | 0     |

  @qos_booking_and_assignment_createBooking_400.13_duration_out_of_range_for_qos_profile
  Scenario: Duration exceeds the maximum allowed by the selected QoS profile
    Given the request body property "$.qosProfile" is set to a valid QoS profile
    And the request body property "$.duration" is set to a value greater than the maximum duration allowed for the selected QoS profile
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "QOS_BOOKING_AND_ASSIGNMENT.DURATION_OUT_OF_RANGE"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_createBooking_400.14_non_existent_qos_profile
  Scenario: Error response for non-existent QoS profile in request body
    Given the request body property "$.qosProfile" is set to a non-existent QoS profile
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Service Error scenarios

  ## Authentication/Authorization errors

    # Generic 401 errors

  @qos_booking_and_assignment_createBooking_401.1_no_authorization_header
  Scenario: Error response for no header Authorization
    Given the header "Authorization" is not sent
    When the request "createBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_createBooking_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "createBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_createBooking_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "createBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 403 errors

  @qos_booking_and_assignment_createBooking_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking-and-assignment:qos-bookings:create"
    When the request "createBooking" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Generic 409 errors

  @qos_booking_and_assignment_createBooking_409.1_duplicated_booking
  Scenario: Conflict due to an existing identical QoS booking
    Given a QoS booking already exists, created by the same API client, with identical parameters to the ones in the request body
    And the request body is set to the same values used to create that QoS booking
    When the request "createBooking" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "ALREADY_EXISTS"
    And the response property "$.message" contains a user friendly text

  # 422 errors

  # CONDITIONAL: only applicable if the API provider does not implement event notification delivery
  # The resource MUST NOT be created when the request is rejected
  @qos_booking_and_assignment_createBooking_422.1_event_notifications_not_supported
  Scenario: Event notifications capability not supported
    Given the request body includes property "$.sink" with a valid value
    And the API provider does not implement event notifications delivery for the operation "createBooking"
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "EVENT_NOTIFICATIONS_NOT_SUPPORTED"
    And the response property "$.message" contains a user friendly text

  # Generic 429 errors

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @qos_booking_and_assignment_createBooking_429.1_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given a valid request for "createBooking"
    And the header "Authorization" is set to a valid access token
    And the threshold of requests has been reached
    When the request "createBooking" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
