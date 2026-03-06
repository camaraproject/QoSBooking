Feature: CAMARA QoS Booking API, vwip - Operation getBookingById
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  #
  # Testing assets:
  # * The bookingId of an existing QoS booking, and the request properties used for createBooking
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking.yaml

  Background: Common getBookingById setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking/vwip/device-qos-bookings/{bookingId}"
    # Unless indicated otherwise the booking must be created by the same API client given in the access token
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the path parameter "bookingId" is set by default to a existing QoS booking bookingId

  # Response 200

  @qos_booking_getBookingById_01_get_existing_booking
  Scenario: Get an existing QoS booking by bookingId
    Given an existing QoS booking created by operation createBooking
    And the path parameter "bookingId" is set to the value for that QoS booking
    When the request "getBookingById" is sent
    Then the response status code is 200
    And the response header "x-correlator" has same value as the request header "x-correlator"
    # The response has to comply with the generic response schema which is part of the spec
    And the response body complies with the OAS schema at "#/components/schemas/BookingInfo"
    # Additionally any success response has to comply with some constraints beyond the schema compliance
    And the response property "$.device" exists only if provided for createBooking and with the same value
    And the response property "$.applicationServer" exists only if provided for createBooking and with the same value
    And the response property "$.qosProfile" has the value provided for createBooking
    And the response property "$.devicePorts" exists only if provided for createBooking and with the same value
    And the response property "$.applicationServerPorts" exists only if provided for createBooking and with the same value
    And the response property "$.sink" exists only if provided for createBooking and with the same value
    # sinkCredential not explicitly mentioned to be returned if present, as this is debatable for security concerns
    And the response property "$.startedAt" exists only if "$.status" is "AVAILABLE" and the value is in the past
    And the response property "$.statusInfo" exists only if "$.status" is "UNAVAILABLE"

  @qos_booking_getBookingById_02_get_recent_unavailable
  Scenario: QOS Session becoming "UNAVAILABLE" is not released for at least 360 seconds
    Given an existing QoS booking failed to be created in the last 360 seconds
    And the path parameter "bookingId" is set to the value for that QoS booking
    When the request "getBookingById" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/BookingInfo"
    And the response property "$.qosStatus" is "UNAVAILABLE"

  # Response 400

  # Code INVALID_ARGUMENT

  # 404 NOT_FOUND is an alternative if path parameter format is not validated
  @qos_booking_getBookingById_400.1_invalid_booking_id
  Scenario: Invalid bookingId
    Given the path parameter "bookingId" has not a UUID format
    When the request "getBookingById" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Implementations may decide to not send x-correlator in the response if is invalid in the request
  # (but not explicitly forbidden either)
  @qos_booking_getBookingById_400.2_invalid_correlator
  Scenario: Invalid x-correlator
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "getBookingById" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Code OUT_OF_RANGE

  # No use case for this code so it could be removed from the spec

  # Response 401

  # Code UNAUTHENTICATED

  @qos_booking_getBookingById_401.1_no_authorization_header
  Scenario: Error response for no header "Authorization"
    Given the header "Authorization" is not sent
    When the request "getBookingById" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_getBookingById_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "getBookingById" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_getBookingById_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "getBookingById" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Response 403

  # Code PERMISSION_DENIED

  @qos_booking_getBookingById_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking:device-qos-bookings:read"
    When the request "getBookingById" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_getBookingById_403.2_booking_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    # To test this, a token have to be obtained for a different client
    Given the header "Authorization" is set to a valid access token emitted to a client which did not created the QoS booking
    When the request "getBookingById" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Response 404

  # Code NOT_FOUND

  @qos_booking_getBookingById_404.1_not_found
  Scenario: bookingId of a non-existing QoS booking
    Given the path parameter "bookingId" is set to a random UUID
    When the request "getBookingById" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Response 429

  # Code QUOTA_EXCEEDED

  # Code TOO_MANY_REQUESTS

  # No specific test scenarios for these response
