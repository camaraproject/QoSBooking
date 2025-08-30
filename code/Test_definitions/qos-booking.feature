Feature: CAMARA QoS Booking API, v0.1.0 - API Operations
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
    # * The bookingId of an existing QoS Booking, and the request properties used for createBooking
    # * The BookingInfo of an existing QoS Booking
    # * A device object with an existing QoS Booking associated, and the request properties used for createBooking
    # * A device object with NO existing QoS Booking associated
    #
    # References to OAS spec schemas refer to schemas specified in qos-booking.yaml

  Background: Common QoS Booking setup
    Given an environment at "apiRoot"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"

  # Success scenarios for POST /device-qos-bookings

  @qos_booking_createBooking_01_success
  Scenario: Create a QoS booking with valid parameters
    Given the resource "/qos-booking/v0.1/device-qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the request body is set to a request body compliant with the schema at "/components/schemas/CreateBooking"
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a valid time
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a valid service area
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BookingInfo"
    And the response body property "$.bookingId" exists and is a valid UUID
    And the response body property "$.status" is "REQUESTED"

  # Success scenarios for GET /device-qos-bookings/{bookingId}

  @qos_booking_getBooking_01_success
  Scenario: Get an existing QoS booking by bookingId
    Given the resource "/qos-booking/v0.1/device-qos-bookings/{bookingId}"
    And an existing QoS booking created by operation createBooking
    And the path parameter "bookingId" is set to the value for that QoS booking
    When the request "getBookingById" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BookingInfo"
    # Additionally any success response has to comply with some constraints beyond the schema compliance
    And the response body property "$.device" exists only if provided for createBooking and with the same value
    And the response body property "$.qosProfile" has the value provided for createBooking
    And the response body property "$.startTime" has the value provided for createBooking
    And the response body property "$.duration" has the value provided for createBooking
    And the response body property "$.serviceArea" has the value provided for createBooking
    And the response body property "$.sink" exists only if provided for createBooking and with the same value

  # Success scenarios for DELETE /device-qos-bookings/{bookingId}

  @qos_booking_deleteBooking_01_success
  Scenario: Delete a QoS booking
    Given that implementation deletes QoS booking synchronously
    And an existing QoS booking created by operation createBooking
    And the resource "/qos-booking/v0.1/device-qos-bookings/{bookingId}"
    And the path parameter "bookingId" is set to the value for that QoS booking
    When the request "deleteBooking" is sent
    Then the response status code is 204
    And the response header "x-correlator" has the same value as the request header "x-correlator"

  # Success scenarios for POST /retrieve-device-qos-bookings

  @qos_booking_retrieveBooking_01_success
  Scenario: Get QoS Booking resource information details for a device
    Given a valid testing device with an existing QoS Booking, identified by the token or provided in the request body
    And the resource "/qos-booking/v0.1/retrieve-device-qos-bookings"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/RetrieveBookingsOutput"
    # Additionally any success response has to comply with some constraints beyond the schema compliance
    And the response body property "$.device" exists only if provided for createBooking and with the same value
    And the response body property "$.qosProfile" has the value provided for createBooking
    And the response body property "$.startTime" has the value provided for createBooking
    And the response body property "$.duration" has the value provided for createBooking
    And the response body property "$.serviceArea" has the value provided for createBooking
    And the response body property "$.sink" exists only if provided for createBooking and with the same value
