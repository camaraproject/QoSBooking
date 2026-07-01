Feature: CAMARA QoS Booking and Assignment, vwip
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # References to OAS spec schemas refer to schemas specified in qos-booking-and-assignment.yaml

  Background: Common QoS Booking setup
    Given an environment at "apiRoot"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"

  # Success scenarios for POST /qos-bookings
  # Reserve a set of devices for a given qos profile, service area, scheduled future time and duration
  @qos_bookings_createBooking_201_success
  Scenario: Create a QoS booking with valid parameters
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the operationId is "createBooking"
    And the request body is set to a request body compliant with the schema at "/components/schemas/BookingInput"
    And the request body property "$.numDevices" is set to a valid number of devices
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a valid time
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a valid service area compliant with schema at "/components/schemas/Area"
    And the request body property "$.sink" is set to a valid notification URL
    And the request body property "$.sinkCredential.credentialType" is set to a value compliant with schema at "/components/schemas/SinkCredential"
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response body property "$.bookingId" exists and is a valid UUID
    And the response body property "$.status" is set to a value "SUCCESSFUL"

  @qos_bookings_createBooking_201_success_echo
  Scenario: Create booking echoes selected request fields in response
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And the operationId is "createBooking"
    And the request body is set to a request body compliant with the schema at "/components/schemas/BookingInput"
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a valid time
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a valid service area compliant with schema at "/components/schemas/Area"
    And the request body property "$.sink" is set to a valid notification URL
    When the request "createBooking" is sent
    Then the response status code is 201
    And the response body property "$.qosProfile" has the same value as in the request body
    And the response body property "$.startTime" has the same value as in the request body
    And the response body property "$.duration" has the same value as in the request body
    And the response body property "$.serviceArea" has the same value as in the request body
    And the response body property "$.sink" exists only if provided in the request body and with the same value

  # Success scenarios for GET /qos-bookings/{bookingId}
  # Given a bookingID, this GET operation gets the details of the original booking
  @qos_bookings_getBookingById_200_success
  Scenario: Get an existing QoS booking by bookingId
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And an existing QoS booking with "bookingId" is created by the operation "createBooking"
    And the operationId is "getBookingById"
    When the request "getBookingById" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BookingOutput"
    And the response body property "$.bookingId" exists and is a valid UUID
    And the response body property "$.totalDevices" has the same value "$.numDevices" as in the request body
    And the response body property "$.remainingDevices" is set to a valid number greater than or equal to 0 and should be less than or equal to "$.totalDevices"
    And the response body property "$.startTime" has the same value as in the request body
    And the response body property "$.serviceArea" has the same value as in the request body
    And the response body property "$.status" is set to a value compliant with schema at "/components/schemas/Status"
    And the response body property "$.status" is set to a value "SUCCESSFUL"

  # Success scenarios for DELETE /qos-bookings/{bookingId}
  # This operation deletes a booking identified by bookingID.
  @qos_bookings_deleteBooking_200_success
  Scenario: Delete a QoS booking
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And "bookingId" is created by operation "createBooking"
    And the operationId is "deleteBooking"
    When the request "deleteBooking" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/BookingOutput"
    And the response body property "$.bookingId" exists and is a valid UUID
    And the response body property "$.totalDevices" has the same value "$.numDevices" as in the request body
    And the response body property "$.remainingDevices" is set to a valid number greater than or equal to 0 and should be less than or equal to "$.totalDevices"
    And the response body property "$.status" is set to a value "SUCCESSFUL"

  # Success scenarios for POST /qos-bookings/{bookingId}/devices/assign
  # This operation assigns set of devices to a booking.
  @devices_assignDevices_201_success
  Scenario: Assign a set of devices to a QoS booking
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices/assign"
    And the "bookingId" is created by operation "createBooking"
    And the operationId is "assignDevices"
    And the request body complies with the OAS schema at "/components/schemas/DeviceAssignmentInput"
    And the request body property "$.devices" is set to a valid array of device identifiers set to a value compliant with schema at "/components/schemas/Devices"
    And the request body property "$.sink" is set to a valid notification URL
    And the request body property "$.sinkCredential.credentialType" is set to a value compliant with schema at "/components/schemas/SinkCredential"
    When the request "assignDevices" is sent
    Then the response status code is 201
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/DeviceAssignmentOutput"
    And the response body property "$.devices" exists and should have atleast one device identifier a value compliant with schema at "/components/schemas/Devices"
    And the response body property "$.devices" should contain the same or the subset of the device identifiers given in the request body
    And the response body property "$.status" is set to a value "SUCCESSFUL"

  # Success scenarios for POST qos-bookings/{bookingId}/devices/release
  # This operation releases a set of devices from a booking which are already assigned to the booking
  @devices_releaseDevices_200_success
  Scenario: Release one or more of already assigned devices from a QoS booking
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices/release"
    And the "bookingId" is created by operation "createBooking"
    And the operationId is "releaseDevices"
    And the request body complies with the OAS schema at "/components/schemas/DeviceAssignmentInput"
    And the request body property "$.devices" is set to a valid array of device identifiers set to a value compliant with schema at "/components/schemas/Devices"
    And the request body property "$.sink" is set to a valid notification URL
    And the request body property "$.sinkCredential.credentialType" is set to a value compliant with schema at "/components/schemas/SinkCredential"
    When the request "releaseDevices" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/DeviceAssignmentOutput"
    And the response body property "$.devices" is set to a value compliant with schema at "/components/schemas/Devices"
    And the response body property "$.status" is set to a value "SUCCESSFUL"

  # Success scenarios for GET /qos-bookings/{bookingId}/devices
  # This operation gets the list of devices assigned to a booking
  @devices_getDevicesByBookingId_200_success
  Scenario: Get a list of devices assigned to a QoS booking
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices"
    And the "bookingId" is created by operation "createBooking"
    And the operationId is "getDevicesByBookingId"
    When the request "getDevicesByBookingId" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/DeviceAssignmentOutput"
    And the response body property "$.devices" is set to a value compliant with schema at "/components/schemas/Devices"
    And the response body property "$.devices" may contain one or more device identifiers set originally during "assignDevices"
    And the response body property "$.status" is set to a value "SUCCESSFUL"

  # Success scenarios for POST /qos-bookings/retrieve
  @devices_retrieveBooking_200_success
  Scenario: Get QoS Booking resource information details for a device
    Given a valid testing device with an existing QoS Booking, identified by the token or provided in the request body
    And the resource "/qos-booking-and-assignment/vwip/qos-bookings/retrieve"
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/RetrieveBookingsOutput"
    # Additionally any success response has to comply with some constraints beyond the schema compliance
    And the response body is a non-empty array of items compliant with the OAS schema at "/components/schemas/BookingDetails"
    And the response body property "$[0].bookingId" exists and is a valid UUID
    And the response body property "$[0].qosProfile" has the value provided for createBooking
    And the response body property "$[0].startTime" has the value provided for createBooking
    And the response body property "$[0].duration" has the value provided for createBooking
    And the response body property "$[0].serviceArea" has the value provided for createBooking

  # Error scenarios for POST /qos-bookings
  @qos_bookings_createBooking_400_num_devices_out_of_range
  Scenario: Create booking fails when numDevices exceeds maximum of 50
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the operationId is "createBooking"
    And the request body is set to a request body compliant with the schema at "/components/schemas/BookingInput"
    And the request body property "$.numDevices" is set to 51
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a valid time
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a valid service area compliant with schema at "/components/schemas/Area"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 400
    And the response body property "$.code" is "OUT_OF_RANGE"

  @qos_bookings_createBooking_400_duration_out_of_range
  Scenario: Create booking fails when duration exceeds maximum of 86400 seconds
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the operationId is "createBooking"
    And the request body is set to a request body compliant with the schema at "/components/schemas/BookingInput"
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a valid time
    And the request body property "$.duration" is set to 86401
    And the request body property "$.serviceArea" is set to a valid service area compliant with schema at "/components/schemas/Area"
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 400
    And the response body property "$.code" is "QOS_BOOKING_AND_ASSIGNMENT.DURATION_OUT_OF_RANGE"

  @qos_bookings_createBooking_400_unknown_property
  Scenario: Create booking fails when request body contains a property not declared in the schema
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the operationId is "createBooking"
    And the request body is set to a request body compliant with the schema at "/components/schemas/BookingInput"
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a valid time
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a valid service area compliant with schema at "/components/schemas/Area"
    And the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "createBooking" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 400
    And the response body property "$.code" is "INVALID_ARGUMENT"

  @qos_bookings_createBooking_409_incompatible_state
  Scenario: Create booking fails when an incompatible booking already exists for the same device and overlapping schedule
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings"
    And the header "Content-Type" is set to "application/json"
    And the operationId is "createBooking"
    And an existing QoS booking already exists for the same device with an overlapping time slot and service area
    And the request body is set to a request body compliant with the schema at "/components/schemas/BookingInput"
    And the request body property "$.qosProfile" is set to a valid QoS Profile as returned by QoS Profiles API
    And the request body property "$.startTime" is set to a time overlapping with the existing booking
    And the request body property "$.duration" is set to a valid duration for the selected QoS profile
    And the request body property "$.serviceArea" is set to a service area overlapping with the existing booking
    When the request "createBooking" is sent
    Then the response status code is 409
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 409
    And the response body property "$.code" is "INCOMPATIBLE_STATE"

  # Error scenarios for POST /qos-bookings/{bookingId}/devices/assign
  @devices_assignDevices_400_too_many_devices
  Scenario: Assign devices fails when the devices array exceeds the maximum of 50
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices/assign"
    And the "bookingId" is created by operation "createBooking"
    And the operationId is "assignDevices"
    And the request body property "$.devices" is set to an array of 51 valid device identifiers compliant with schema at "/components/schemas/Device"
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 400
    And the response body property "$.code" is "INVALID_ARGUMENT"

  @devices_assignDevices_400_unknown_property
  Scenario: Assign devices fails when request body contains a property not declared in the schema
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings/{bookingId}/devices/assign"
    And the "bookingId" is created by operation "createBooking"
    And the operationId is "assignDevices"
    And the request body complies with the OAS schema at "/components/schemas/DeviceAssignmentInput"
    And the request body property "$.devices" is set to a valid array of device identifiers compliant with schema at "/components/schemas/Devices"
    And the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "assignDevices" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 400
    And the response body property "$.code" is "INVALID_ARGUMENT"

  # Error scenarios for POST /qos-bookings/retrieve
  @devices_retrieveBooking_400_unknown_property
  Scenario: Retrieve booking fails when request body contains a property not declared in the schema
    Given the resource "/qos-booking-and-assignment/vwip/qos-bookings/retrieve"
    And the operationId is "retrieveBookingByDevice"
    And the request body complies with the OAS schema at "/components/schemas/RetrieveBookingByDevice"
    And the request body includes an undeclared property "$.unexpectedParam" set to any value
    When the request "retrieveBookingByDevice" is sent
    Then the response status code is 400
    And the response header "Content-Type" is "application/json"
    And the response body property "$.status" is 400
    And the response body property "$.code" is "INVALID_ARGUMENT"
