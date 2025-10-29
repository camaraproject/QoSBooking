Feature: CAMARA QoS Booking API, vwip - Operation deleteBooking
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  #
  # Testing assets:
  # * The bookingId of any existing booking.
  # * The bookingId of an existing booking with status "REQUESTED", and with provided values for "sink" and "sinkCredential".
  # * The bookingId of an existing booking with status "SCHEDULED", and with provided values for "sink" and "sinkCredential".
  # * The bookingId of an existing booking with status "AVAILABLE", and with provided values for "sink" and "sinkCredential".
  # * The bookingId of an existing booking with status "UNAVAILABLE", and with provided values for "sink" and "sinkCredential".
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking.yaml

  Background: Common deleteBooking setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking/vwip/device-qos-bookings/{bookingId}"
    # Unless indicated otherwise the QoS booking must be created by the same API client given in the access token
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the path parameter "bookingId" is set by default to an existing QoS booking bookingId

  # Response 202

  # From the current spec it is assumed that only booking in status "SCHEDULED" or "AVAILABLE" may be asynchronously deleted
  # If booking is in status "REQUESTED" or "UNAVAILABLE", a synchronous deletion is expected
  @qos_booking_deleteBooking_202_async_delete_existing_qos_booking
  Scenario: Delete an existing QoS booking (async deletion process)
    Given an existing QoS booking created by operation createBooking in status "SCHEDULED" or "AVAILABLE"
    And the deletion process for that QoS booking in the implementation is asynchronous
    And the path parameter "bookingId" is set to the value for that QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/BookingInfo"
    # Additionally any success response has to comply with some constraints beyond the schema compliance
    And the response property "$.device" exists only if provided for createBooking and with the same value
    And the response property "$.applicationServer" exists only if provided for createBooking and with the same value
    And the response property "$.qosProfile" has the value provided for createBooking
    And the response property "$.devicePorts" exists only if provided for createBooking and with the same value
    And the response property "$.applicationServerPorts" exists only if provided for createBooking and with the same value
    And the response property "$.sink" exists only if provided for createBooking and with the same value
    # sinkCredential not explicitly mentioned to be returned if present, as this is debatable for security concerns
    And the response property "$.status" is "SCHEDULED" or "AVAILABLE"
    And the response property "$.startedAt" exists only if "$.status" is "AVAILABLE" and the value is in the past
    And the response property "$.statusInfo" is "DELETE_REQUESTED"

  # Response 204

  @qos_booking_deleteBooking_01_delete_existing_qos_booking
  Scenario: Delete an existing QoS booking (sync deletion)
    Given an existing QoS booking created by operation createBooking
    And the path parameter "bookingId" is set to the value for that QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 204
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"

  @qos_booking_deleteBooking_02_event_notification
  Scenario: Event is received if the booking was SCHEDULED or AVAILABLE and sink was provided
    Given an existing QoS booking created by operation createBooking with provided values for "sink" and "sinkCredential", and with status "AVAILABLE" or "SCHEDULED"
    And the path parameter "bookingId" is set to the value for that QoS booking
    When QoS booking status changes to "UNAVAILABLE"
    Then an event is received at the address of the "$.sink" provided for createBooking
    And the event header "Authorization" is set to "Bearer " + the value of the property "$.sinkCredential.accessToken" provided for createBooking
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "/components/schemas/EventStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking.v0.status-changed"
    And the event body property "$.data.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.status" is "UNAVAILABLE"
    And the event body property "$.data.statusInfo" is set to "DELETE_REQUESTED"

  # Response 400

  # Code INVALID_ARGUMENT

  # 404 NOT_FOUND is an alternative if path parameter format is not validated
  @qos_booking_deleteBooking_400.1_invalid_booking_id
  Scenario: Invalid bookingId
    Given the path parameter "bookingId" has not a UUID format
    When the request "deleteBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Implementations may decide to not send x-correlator in the response if is invalid in the request
  # (but not explicitly forbidden either)
  @qos_booking_deleteBooking_400.2_invalid_correlator
  Scenario: Invalid x-correlator
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "deleteBooking" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Code OUT_OF_RANGE

  # No use case for this code so it could be removed from the spec

  # Response 401

  # Code UNAUTHENTICATED

  @qos_booking_deleteBooking_401.1_no_authorization_header
  Scenario: Error response for no header "Authorization"
    Given the header "Authorization" is not sent
    When the request "deleteBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_deleteBooking_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "deleteBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_deleteBooking_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "deleteBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Response 403

  # Code PERMISSION_DENIED

  @qos_booking_deleteBooking_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking:device-qos-bookings:delete"
    When the request "deleteBooking" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_deleteBooking_403.2_booking_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    # To test this, a token have to be obtained for a different client
    Given the header "Authorization" is set to a valid access token emitted to a client which did not created the QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Response 404

  # Code NOT_FOUND

  @qos_booking_deleteBooking_404.1_not_found
  Scenario: bookingId of a non-existing QoS booking
    Given the path parameter "bookingId" is set to a random UUID
    When the request "deleteBooking" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Response 429

  # Code QUOTA_EXCEEDED

  # Code TOO_MANY_REQUESTS

  # No specific test scenarios for these response codes are provided