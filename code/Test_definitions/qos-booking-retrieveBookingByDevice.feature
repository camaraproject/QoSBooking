Feature: CAMARA QoS Booking API, vwip - Operation retrieveBookingByDevice
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address.
  #   For this version, CAMARA does not allow the use of networkAccessIdentifier, so it is considered by default as not supported.
  #
  # Testing assets:
  # * A device object applicable for QoS Booking service with any QoS booking associated, and the request properties used for createBooking
  # * A device object applicable for QoS Booking service with NO QoS bookings associated
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable, if any.
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking.yaml

  Background: Common retrieveBookingByDevice setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking/vwip/retrieve-device-qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    # Properties not explicitly overwritten in the Scenarios can take any values compliant with the schema
    And the request body is set by default to a request body compliant with the schema at "/components/schemas/RetrieveBookingByDevice"

  # Response 200

  @qos_booking_retrieveBookingByDevice_01_get_existing_booking_by_device
  Scenario: Get an existing QoS booking by device
    Given a valid testing device supported by the service, identified by the token or provided in the request body, with QoS active bookings associated
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    # The response has to comply with the generic response schema which is part of the spec
    And the response body complies with the OAS schema at "/components/schemas/RetrieveBookingsOutput"
    # Additionally any success response has to comply with some constraints beyond the schema compliance
    And in all items in the response, property "device" exists only if provided for createBooking and with the same value
    And in all items in the response, property "applicationServer" exists only if provided for createBooking and with the same value
    And in all items in the response, property "qosProfile" has the value provided for createBooking
    And in all items in the response, property "devicePorts" exists only if provided for createBooking and with the same value
    And in all items in the response, property "applicationServerPorts" exists only if provided for createBooking and with the same value
    And in all items in the response, property "sink" exists only if provided for createBooking and with the same value
    # sinkCredential not explicitly mentioned to be returned if present, as this is debatable for security concerns
    And in all items in the response, property "startedAt" exists only if "status" is "AVAILABLE" and the value is in the past
    And in all items in the response, property "statusInfo" exists only if "status" is "UNAVAILABLE"

  @qos_booking_retrieveBookingByDevice_02_bookings_not_found
  Scenario: Device has no QoS bookings
    # Valid testing device and default request body compliant with the schema
    Given a valid testing device supported by the service, identified by the token or provided in the request body with no QoS active bookings associated
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body is []

  # Response 400

  # Code INVALID_ARGUMENT

  @qos_booking_retrieveBookingByDevice_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to: {}
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_retrieveBookingByDevice_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the HTTP "POST" request is sent
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

  @qos_booking_retrieveBookingByDevice_400.1_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "/components/schemas/RetrieveBookingByDevice"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_retrieveBookingByDevice_400.2_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Code OUT_OF_RANGE"

  # No use case for this code so it could be removed from the spec

  # Response 401

  # Code UNAUTHENTICATED

  @qos_booking_retrieveBookingByDevice_401.1_no_authorization_header
  Scenario: Error response for no header "Authorization"
    Given the header "Authorization" is not sent
    And the request body is set to a valid request body
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_retrieveBookingByDevice_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body is set to a valid request body
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_retrieveBookingByDevice_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body is set to a valid request body
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Response 403

  # Code PERMISSION_DENIED

  @qos_booking_retrieveBookingByDevice_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking:device-qos-bookings:retrieve-by-device"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_retrieveBookingByDevice_403.2_booking_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    # To test this, a token have to be obtained for a different client
    Given the header "Authorization" is set to a valid access token emitted to a client which did not created the QoS booking
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Response 404

  # Code NOT_FOUND

  # No use case for this code in this operation so it may be removed

  # Code IDENTIFIER_NOT_FOUND

  @qos_booking_retrieveBookingByDevice_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is compliant with the schema but does not identify a valid device
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Response 422

    
  # Code UNNECESSARY_IDENTIFIER

  @qos_booking_retrieveBookingByDevice_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is set to a valid device
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  # Code MISSING_IDENTIFIER

  @qos_booking_retrieveBookingByDevice_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  # Code UNSUPPORTED_IDENTIFIER

  @qos_booking_retrieveBookingByDevice_C01.06_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  # Code SERVICE_NOT_APPLICABLE

  @qos_booking_retrieveBookingByDevice_C01.07_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user-friendly text

  # Response 429

  ## Code QUOTA_EXCEEDED

  # No clear test scenario for this code

  ## Code TOO_MANY_REQUESTS

  # No clear test scenario for this code
