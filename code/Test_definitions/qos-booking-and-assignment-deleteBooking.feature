Feature: CAMARA QoS Booking and Assignment API, vwip - Operation deleteBooking
  # CAMARA Commonalities: 0.9.0
  #
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * Scenarios marked as CONDITIONAL in their comments apply only if the implementation supports the option they test; the implementation informs the tester of the supported options.
  # * Supported booking confirmation mode(s) for createBooking: synchronous (SCHEDULED or ACTIVATED in the 201 response) and/or asynchronous (REQUESTED followed by a booking-status-changed event).
  # * Whether deleteBooking is processed synchronously (204), asynchronously (202) or both.
  # * Whether deleteBooking is rejected with 409 INCOMPATIBLE_STATE while devices remain assigned, or releases them automatically.
  #
  # Testing assets:
  # * A valid QoS profile name, and the maximum duration allowed for it.
  # * A valid service area compliant with the Area schema.
  # * An https endpoint able to receive CloudEvents, with a valid access token to be used as sinkCredential (credentialType ACCESSTOKEN).
  # * An access token emitted to a different API client than the one that created the QoS booking.
  #
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment-wip-alignedto_r4dot4.yaml

  Background: Common "deleteBooking" setup
    Given an environment at "apiRoot"
    And the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the path parameter "bookingId" is set by default to the identifier of an existing QoS booking created by operation "createBooking"

############################ Happy Path Scenarios #############################################

  # CONDITIONAL: only applicable if the API provider processes the deletion synchronously
  @qos_booking_and_assignment_deleteBooking_01_sync_success_scenario
  Scenario: Delete a QoS booking processed synchronously
    Given an existing QoS booking created by operation "createBooking" with no devices assigned
    And the path parameter "bookingId" is set to the value of the identifier for that QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 204
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body is empty

  # CONDITIONAL: only applicable if the API provider processes the deletion asynchronously
  @qos_booking_and_assignment_deleteBooking_02_async_success_scenario
  Scenario: Delete a QoS booking processed asynchronously
    Given an existing QoS booking created by operation "createBooking" with no devices assigned
    And the path parameter "bookingId" is set to the value of the identifier for that QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/BookingOutput"
    And the response property "$.bookingId" has the same value as the path parameter "bookingId"
    And the response property "$.bookingStatus" is "REQUESTED"
    And the response property "$.statusInfo" is "DELETE_REQUESTED"

  # CONDITIONAL: applicable if the API provider processes the deletion synchronously. For asynchronous processing the check applies once the cancellation event has been received
  @qos_booking_and_assignment_deleteBooking_03_booking_not_readable_after_deletion
  Scenario: A deleted QoS booking can no longer be read
    Given an existing QoS booking created by operation "createBooking" with no devices assigned
    And the QoS booking has been deleted with operation "deleteBooking" and the deletion has completed
    And the path parameter "bookingId" is set to the value of the identifier for that QoS booking
    When the request "getBookingById" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_deleteBooking_04_event_notification
  Scenario: Cancellation event is received after using sink
    Given a QoS booking has been created successfully with operation "createBooking" and includes a valid sink and sinkCredentials
    And its deletion has been requested successfully with operation "deleteBooking"
    When the booking cancellation is completed
    Then an event is received at the address of the request property "$.sink"
    And the event header "Authorization" is set to "Bearer " + the value of the request property "$.sinkCredential.accessToken"
    And the event header "Content-Type" is set to "application/cloudevents+json"
    And the event body complies with the OAS schema at "#/components/schemas/EventBookingStatusChanged"
    And the event body property "$.id" is unique
    And the event body property "$.type" is set to "org.camaraproject.qos-booking-and-assignment.v0.booking-status-changed"
    And the event body property "$.data.bookingDetails.bookingId" has the same value as createBooking response property "$.bookingId"
    And the event body property "$.data.bookingStatus" is "TERMINATED"
    And the event body property "$.data.statusInfo" is "BOOKING_CANCELLED"

############################ Error Scenarios #############################################

  # Syntax Error scenarios

  @qos_booking_and_assignment_deleteBooking_400.1_invalid_booking_id
  Scenario: Invalid bookingId path parameter
    Given the path parameter "bookingId" is set to a value that is not a valid UUID
    When the request "deleteBooking" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_deleteBooking_400.2_invalid_x-correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    When the request "deleteBooking" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Service Error scenarios

  ## Authentication/Authorization errors

    # Generic 401 errors

  @qos_booking_and_assignment_deleteBooking_401.1_no_authorization_header
  Scenario: Error response for no header Authorization
    Given the header "Authorization" is not sent
    When the request "deleteBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_deleteBooking_401.2_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "deleteBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @qos_booking_and_assignment_deleteBooking_401.3_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "deleteBooking" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 403 errors

  @qos_booking_and_assignment_deleteBooking_403.1_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "qos-booking-and-assignment:qos-bookings:delete"
    When the request "deleteBooking" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # To test this, a token has to be obtained for a different client
  @qos_booking_and_assignment_deleteBooking_403.2_api_client_token_mismatch
  Scenario: QoS booking not created by the API client given in the access token
    Given the header "Authorization" is set to a valid access token emitted to an API client which did not create the QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Generic 404 errors

  @qos_booking_and_assignment_deleteBooking_404.1_not_found
  Scenario: Non-existing "bookingId"
    Given the path parameter "bookingId" is set to a random UUID that does not correspond to any existing QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Generic 409 errors

  # CONDITIONAL: only applicable if the API provider rejects the deletion of bookings with assigned devices (provider-dependent, see the deleteBooking description)
  @qos_booking_and_assignment_deleteBooking_409.1_incompatible_state
  Scenario: Conflict due to devices still assigned to the QoS booking
    Given an existing QoS booking created by operation "createBooking" with at least one device assigned by operation "assignDevices"
    And the path parameter "bookingId" is set to the value of the identifier for that QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 409
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 409
    And the response property "$.code" is "INCOMPATIBLE_STATE"
    And the response property "$.message" contains a user friendly text

  # Generic 429 errors

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @qos_booking_and_assignment_deleteBooking_429.1_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given a valid request for "deleteBooking"
    And the header "Authorization" is set to a valid access token
    And the threshold of requests has been reached
    When the request "deleteBooking" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS"
    And the response property "$.message" contains a user friendly text
