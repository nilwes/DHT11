// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import gpio

class DhtResult:
  /** Temperature read from the DHT11 sensor in degrees Celcius. */
  temperature/float

  /** Humidity read from the DHT11 sensor. */
  humidity/float

  constructor.init_ .temperature .humidity:

  /** See $super.*/
  operator == other/any -> bool:
    return other is DhtResult and temperature == other.temperature and humidity == other.humidity

  hash_code -> int:
    return (temperature * 10).to_int * 11 + (humidity * 10).to_int * 13

  /** See $super. */
  stringify -> string:
    return "T: $(%.2f temperature), H: $(%.2f humidity)"

class Dht11:
  static DHT_PULSES_   ::= 41    // Bit pulses produced by DHT sensor. Initialization + 40 bits data.
  static DHT_MAX_COUNT_ ::= 1000 // Timeout while waiting for edges.

  pin_ /gpio.Pin

  constructor pin/gpio.Pin:
    pin_ = pin
    pin.config --input --output --open_drain
    pin.set 1

    sleep --ms=1000 // Allow the sensor to stabilize after power-up.

  /**
  Reads the temperature and humidity from the DHT11.

  When reading no or invalid data the function will retry up to $max_retries times.

  Throws a CHECKSUM_ERROR or READ_ERROR if no valid data could be read.
  */
  read --max_retries/int=3 -> DhtResult:
    checksum_error := false
    for i := 0; i <= max_retries; i++:
      if i != 0: sleep --ms=100

      pulse_counts := read_
      if not pulse_counts:
        continue

      data := extract_bytes_ pulse_counts

      // Checksum control
      if data[4] != (data[0] + data[1] + data[2] + data[3]) & 0xFF:
        checksum_error = true
        continue

      return DhtResult.init_ data[2].to_float data[0].to_float

    // Prefer to return a checksum error to a read error.
    if checksum_error: throw "CHECKSUM_ERROR"
    else: throw "READ_ERROR"

  /**
  Triggers the DHT11 sensor to emit data stream, and subsequently reads this bit stream.
  Returns a list with pulse durations if successful.
  Returns null otherwise.
  */
  read_ -> List?:
    // Allocate the list before the time-critical part.
    pulse_counts := List (DHT_PULSES_ * 2) 0  // Should be initial bits + 40 bits with zeros inbetween.

    count := 0

    // Time critical section starts here. Avoid adding code!
    // Send start signal to DHT11 sensor: >=18 ms LOW
    pin_.set 0
    sleep --ms=18
    pin_.set 1

    // Immediately start waiting for falling edge
    while pin_.get == 1:
      if ++count >= DHT_MAX_COUNT_:
        return null

    // Record pulse widths for the expected result bits.
    for i := 0; i < DHT_PULSES_ * 2; i += 2:
      // The low signal is 50us long.
      // The high signal can be as short as 26us. As such we want to do more
      // work in the beginning or the end.
      pulse_count_low := 0
      pulse_count_high := 0

      // Count how long pin is low and store in pulse_counts[i]
      while pin_.get != 1:
        if ++pulse_count_low >= DHT_MAX_COUNT_:
          return null

      // Count how long pin is high and store in pulse_counts[i+1]
      while pin_.get == 1:
        if ++pulse_count_high >= DHT_MAX_COUNT_:
          return null

      pulse_counts[i] = pulse_count_low
      pulse_counts[i+1] = pulse_count_high

    // Time critical section stops here.
    return pulse_counts

  /**
  Calculates the average of pulse lengths between bits (threshold).
  */
  calculate_threshold_ pulse_counts/List -> int:
    // The pulse_counts consist of low, followed by high durations.
    // The low duration should always be 50us.
    // The high duration can vary between 26us and 70us.
    // We compute the threshold by averaging the low pulses.
    // However, we avoid the first one, as it generally seems to be a bit too high.
    pulse_sum := 0
    count := 0
    for i := 2; i < pulse_counts.size; i += 2:
      pulse_sum += pulse_counts[i]
      count++
    threshold := pulse_sum / count
    return threshold

  /**
  Extracts the data bytes from the received bit stream from the DHT11.
  */
  extract_bytes_ pulse_counts/List -> ByteArray:
    // The pulse_counts consist of low, followed by high durations.
    // The low duration should always be 50us.
    // The high duration can vary between 26us (for a 0) and 70us (for a 1).
    // We compute the threshold by averaging the low pulses.
    threshold := calculate_threshold_ pulse_counts

    pulse_index := 3
    return ByteArray 5:
      byte := 0
      8.repeat:
        byte <<= 1
        if pulse_counts[pulse_index] >= threshold:
          byte |= 1
        pulse_index += 2
      byte
