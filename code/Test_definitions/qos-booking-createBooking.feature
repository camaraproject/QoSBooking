Feature: CAMARA QoS Booking API, vwip - Operation createBooking
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address.
  #   For this version, CAMARA does not allow the use of networkAccessIdentifier, so it is considered by default as not supported.
  # * List of application server IP formats which are not supported, among ipv4 and ipv6.
  #
  # Testing assets:
  # * A device object applicable for QoS Booking service.
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable, if any.
  #

  # References to OAS spec schemas refer to schemas specified in qos-booking.yaml

  Background: Common createBooking setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking/vwip/device-qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    # Properties not explicitly overwritten in the Scenarios can take any values compliant with the schema
    And the request body is set by default to a request body compliant with the schema at "/components/schemas/CreateBooking"


  # Response 201

  @qos_booking_createBooking_01_common_success_scenario
  Scenario Outline: Common validations for a success scenario
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request property "$.qosProfile" is set to a valid QoS Profile
    And the request property "$.startTime" is set to a valid value in the future compliant with the service restrictions
    And the request property "$.duration" is set to a valid duration for the selected QoS profile
    And the request property "$.serviceArea" is set to a valid value compliant with the service restrictions
    And any optional request property if included is set to a valid value
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    # The response has to comply with the generic response schema which is part of the spec
    And the response body complies with the OAS schema at "/components/schemas/BookingInfo"
    # Additionally, any success response has to comply with some constraints beyond the schema compliance
    And the response property "<property>" matches the rule: <condition>

    Examples:
      | property                 | condition                                                                                                 |
      | $.device                 | exists only if provided in the request body and contains only one of the identifier values in the request |
      | $.qosProfile             | same value as in the request body                                                                         |
      | $.startTime              | is in the future                                                                                          |
      | $.status                 | is "REQUESTED", "SCHEDULED" or "UNAVAILABLE"                                                              |
      | $.statusInfo             | only exists if "$.status" = "UNAVAILABLE", and value is "NETWORK_TERMINATED"                              |
      | $.devicePorts            | exists only if provided in the request body and with the same value                                       |
      | $.applicationServerPorts | exists only if provided in the request body and with the same value                                       |
      | $.sink                   | exists only if provided in the request body and with the same value                                       |

    # Open questions:
    # serviceArea has to have same value as in the request body or implementations can make adjustments
    # startTime has to have same value as in the request body or implementations can make adjustments, to be returned when status = UNAVAILABLE?
    # duration to be returned when when status = UNAVAILABLE?
    # bookingId to be returned when when status = UNAVAILABLE?
    # statusInfo should have another value when status = UNAVAILABLE after creation, e.g. BOOKING_CANNOT_BE_FULFILLED or open string
    # sinkCredential may be returned in the response in any case or it should be removed for security

  @qos_booking_createBooking_02_no_device_in_response
  Scenario: Device is not returned if not included in the creation
    # Valid testing device and default request body compliant with the schema
    Given the header "Authorization" is set to a valid 3-legged access token associated to a valid testing device supported by the service
    And the request property "$.device" is not included
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BookingInfo"
    And the response property "$.device" does not exist

  @qos_booking_createBooking_03_single_device_identifier_in_response
  Scenario: Single device is returned even if several are provided
    # Valid testing device and default request body compliant with the schema
    Given the header "Authorization" is set to a valid 2-legged access token
    And the request property "$.device" includes several identifiers for the device
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BookingInfo"
    And the response property "$.device" includes only one device

  # Lifecycle of a successful booking    

  @qos_booking_createBooking_04_1_sinkcredential_provided
  Scenario: Create QoS booking with sink and sinkCredential provided
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request property "$.startTime" is set to a value in the future
    And the request property "$.duration" is set to a valid value for the QoS profile requested
    And the request property "$.sink" is set to a URL where events can be monitored
    And the request property "$.sinkCredential.credentialType" is set to "ACCESSTOKEN"
    And the request property "$.sinkCredential.accessTokenType" is set to "bearer"
    And the request property "$.sinkCredential.accessToken" is set to a valid access token accepted by the events receiver
    And the request property "$.sinkCredential.accessTokenExpiresUtc" is set to a time value later than "$.startTime" + "$.duration"
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.sink" has the same value as in the request
    And the response property "$.status" is set to "REQUESTED" or "SCHEDULED"
    And the response property "$.startTime" has a value in the future
    And the response property "$.duration" has the value granted by the implementation

  # This step is optional, for cases when implementation did not grant the booking synchronously
  @qos_booking_createBooking_04_2_event_received_scheduled
  Scenario: Event is received when a booking status changes from requested to scheduled
    Given a QoS booking was created successfully with status = "REQUESTED" and includes a valid sink and sinkCredentials
    And the time value of "createBooking" request property "$.sinkCredential.accessTokenExpiresUtc" has not been reached
    When the status of the booking becomes scheduled
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "/components/schemas/EventStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking.v0.status-changed"
    And the event body property "$.data.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.status" is "SCHEDULED"
    And the event body property "$.data.statusInfo" is not included

  @qos_booking_createBooking_04_3_event_received_available
  Scenario: Event is received when a booking status changes from scheduled to available
    Given a QoS booking is already in status "SCHEDULED" and includes a valid sink and sinkCredentials
    And the time value of "createBooking" request property "$.sinkCredential.accessTokenExpiresUtc" has not been reached
    When the time value of "createBooking" response property "$.startTime" is reached
    And the status of the booking becomes available
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "/components/schemas/EventStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking.v0.status-changed"
    And the event body property "$.data.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.status" is "AVAILABLE"
    And the event body property "$.data.statusInfo" is not included

  @qos_booking_createBooking_04_4_event_received_unavailable_duration_expired
  Scenario: Event is received when a booking status changes from available to unavailable after the duration expires
    Given a QoS booking is already in status "AVAILABLE" and includes a valid sink and sinkCredentials
    And the time value of "createBooking" request property "$.sinkCredential.accessTokenExpiresUtc" has not been reached
    When the time value of "createBooking" response property "$.startTime" + the interval value of response property "$.duration" is reached
    And the status of the booking becomes unavailable
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "/components/schemas/EventStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking.v0.status-changed"
    And the event body property "$.data.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.status" is "UNAVAILABLE"
    And the event body property "$.data.statusInfo" is set to "DURATION_EXPIRED"

  # This step is optional, for cases when the implementation terminated the booked session before the scheduled duration
  @qos_booking_createBooking_04_5_event_received_unavailable_network_terminated
  Scenario: Event is received when a booking status changes from available to unavailable before the scheduled duration expires
    Given a QoS booking is already in status "AVAILABLE" and includes a valid sink and sinkCredentials
    And the time value of "createBooking" request property "$.sinkCredential.accessTokenExpiresUtc" has not been reached
    And  the time value of "createBooking" response property "$.startTime" + the interval value of response property "$.duration" has not been reached
    When the booked session is terminated by the operator
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "/components/schemas/EventStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking.v0.status-changed"
    And the event body property "$.data.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.status" is "UNAVAILABLE"
    And the event body property "$.data.statusInfo" is set to "NETWORK_TERMINATED"

  # This step is optional, for cases when the implementation did not grant the booking synchronously and later rejects the booking
  # or when it was granted (SCHEDULED) but implementation decides to revoke it before the start
  # TBD if a better status or statusInfo is specified for this use case, e.g. status = "REJECTED" or status = "UNAVAILABLE" + statusInfo = "NOT_SCHEDULED" or "REVOKED"
  @qos_booking_createBooking_04_6_event_received_unavailable_network_terminated
  Scenario: Event is received when a booking status changes from requested to unavailable
    Given a QoS booking was created successfully and its status = "REQUESTED" or "SCHEDULED", and includes a valid sink and sinkCredentials
    And the time value of "createBooking" request property "$.sinkCredential.accessTokenExpiresUtc" has not been reached
    When the operator decides that the booking cannot be granted
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "/components/schemas/EventStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking.v0.status-changed"
    And the event body property "$.data.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.status" is "UNAVAILABLE"
    And the event body property "$.data.statusInfo" is set to "NETWORK_TERMINATED"
    
  # Response 400

  ## Code INVALID_ARGUMENT

  @qos_booking_createBooking_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to: {}
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | device_identifier                | oas_spec_schema                             |
      | $.device.phoneNumber             | /components/schemas/PhoneNumber             |
      | $.device.ipv4Address             | /components/schemas/DeviceIpv4Addr          |
      | $.device.ipv6Address             | /components/schemas/DeviceIpv6Address       |
      | $.device.networkAccessIdentifier | /components/schemas/NetworkAccessIdentifier |

  @qos_booking_createBooking_400.1_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "/components/schemas/CreateBooking"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_400.2_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_400.3_empty_request_body
  Scenario: Empty object as request body
    Given the request body is set to {}
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_400.4_empty_property
  Scenario Outline: Error response for empty property in request body
    Given the request body property "<non_empty_property>" is set to {}
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | non_empty_property       |
      | $.applicationServer      |
      | $.devicePorts            |
      | $.applicationServerPorts |

  @qos_booking_createBooking_400.5_non_existent_qos_profile
  Scenario: Error response for invalid qos profile in request body
    Given the request body property "$.qosProfile" is set to a non existent QoS profile
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  ## Code OUT_OF_RANGE

  # The maximum is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @qos_booking_createBooking_400.6_out_of_range_port
  Scenario Outline: Out of range port
    Given the request body property "<port_property>" is set to a value not between between 0 and 65535
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | port_property                        |
      | $.device.ipv4Address.publicPort      |
      | $.devicePorts.ranges.from            |
      | $.devicePorts.ranges.to              |
      | $.devicePorts.ports[*]               |
      | $.applicationServerPorts.ranges.from |
      | $.applicationServerPorts.ranges.to   |
      | $.applicationServerPorts.ports[*]    |

  ## Code INVALID_CREDENTIAL

  # For current version, sinkCredential.credentialType MUST be set to ACCESSTOKEN if provided.
  # PLAIN and REFRESHTOKEN are considered in the schema so INVALID_ARGUMENT is not expected
  @qos_booking_createBooking_400.7_invalid_sink_credential
  Scenario Outline: Invalid credential
    Given the request body property  "$.sinkCredential.credentialType" is set to "<unsupported_credential_type>"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_CREDENTIAL"
    And the response property "$.message" contains a user friendly text

    Examples:
      | unsupported_credential_type |
      | PLAIN                       |
      | REFRESHTOKEN                |

  ## Code INVALID_TOKEN

  # Only "bearer" is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @qos_booking_createBooking_400.8_sink_credential_invalid_token
  Scenario: Invalid token
    Given the request body property  "$.sinkCredential.credentialType" is set to "ACCESSTOKEN"
    And the request body property  "$.sinkCredential.accessTokenType" is set to a value other than "bearer"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_TOKEN" or "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_400.9_sink_credential_expired_token
  Scenario: Expired token
    Given the request body property  "$.sinkCredential.credentialType" is set to "ACCESSTOKEN"
    And the request body property  "$.sinkCredential.accessTokenExpiresUtc" is set to a value in the past
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlatofr"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_TOKEN"
    And the response property "$.message" contains a user friendly text

  ## Code INVALID_SINK

  @qos_booking_createBooking_400.10_invalid_sink
  Scenario: Invalid sink
    Given the request body property  "$.sink" is set to an invalid or not acceptable value
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_SINK"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_400.11_invalid_duration
  Scenario: Invalid duration
    Given the request body property "$.duration" is set to an invalid duration for the selected qosProfile
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "QOS_BOOKING.DURATION_OUT_OF_RANGE"
    And the response property "$.message" contains a user friendly text

  # Response 401

  ## Code UNAUTHENTICATED

  @qos_booking_createBooking_401.1_no_authorization_header
  Scenario: Error response for no header "Authorization"
    Given the header "Authorization" is not sent
    And the request body is set to a valid request body
    When the request "createBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # In this case both codes could make sense depending on whether the access token can be refreshed or not
  @qos_booking_createBooking_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body is set to a valid request body
    When the request "createBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_createBooking_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body is set to a valid request body
    When the request "createBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Response 403

  ## Code PERMISSION_DENIED

  @qos_booking_createBooking_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking:device-qos-bookings:create"
    When the request "createBooking" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Response 404

  ## Code NOT_FOUND

  # No use case for this code in this operation so it may be removed

  ## Code IDENTIFIER_NOT_FOUND

  @qos_booking_createBooking_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is compliant with the schema but does not identify a valid device
    When the request "createBooking" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text


  # Response 409

  ## Code CONFLICT

  @qos_booking_createBooking_409.1_session_conflict
  Scenario: Booking in conflict
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And an incompatible QoS booking already exists for that device
    When the request "createBooking" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "CONFLICT"
    And the response property "$.message" contains a user friendly text  


  # Response 422

  ## Code UNNECESSARY_IDENTIFIER

  @qos_booking_createBooking_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is set to a valid device
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  ## Code MISSING_IDENTIFIER

  @qos_booking_createBooking_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  ## Code UNSUPPORTED_IDENTIFIER

  @qos_booking_createBooking_C01.06_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  ## Code SERVICE_NOT_APPLICABLE

  @qos_booking_createBooking_C01.07_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user-friendly text

## Code QOS_BOOKING.NOT_MANAGED_AREA_TYPE

  @qos_booking_createBooking_422.01_not_managed_area_type
  Scenario Outline: Unsupported area type
    Given that the operator does not support a service area of type "<unsupported_area_type>"
    And the request body property "$.serviceArea.areaType" is set to "<unsupported_area_type>"
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "QOS_BOOKING.NOT_MANAGED_AREA_TYPE"
    And the response property "$.message" contains a user-friendly text
    
    Examples:
      | unsupported_area_type |
      | CIRCLE                |
      | POLYGON               |
      | AREANAME              |

## Code QOS_BOOKING.INVALID_AREA

  @qos_booking_createBooking_422.02_invalid_area
  Scenario Outline: Invalid area
    Given the request body property "$.serviceArea.areaType" is set to "<area_type>"
    And the request body property "$.serviceArea" is not compliant with the schema "<area_type_schema>"
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "QOS_BOOKING.INVALID_AREA"
    And the response property "$.message" contains a user-friendly text
        
    Examples:
      | area_type | area_type_schema             |
      | CIRCLE    | /components/schemas/Circle   |
      | POLYGON   | /components/schemas/Polygon  |
      | AREANAME  | /components/schemas/AreaName |

## Code QOS_BOOKING.AREA_NOT_COVERED

  @qos_booking_createBooking_422.03_area_not_covered
  Scenario: Area not covered
    Given the request body property "$.serviceArea" is set to an area where the service is not provided by the operator
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "QOS_BOOKING.AREA_NOT_COVERED"
    And the response property "$.message" contains a user-friendly text

## Code QOS_BOOKING.QOS_PROFILE_NOT_APPLICABLE to be added in next version

  @qos_booking_createBooking_422.04_qos_profile_not_applicable
  Scenario: QoS Profile not applicable for booking creation
    Given the request body property "$.qosProfile" exists but is not applicable for the booking
    When the request "createBooking" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "QOS_BOOKING.QOS_PROFILE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

# Response 429

## Code QUOTA_EXCEEDED

# No clear test scenario for this code

## Code TOO_MANY_REQUESTS

# No clear test scenario for this code
