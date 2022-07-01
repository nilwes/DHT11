// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import gpio

class DHTsensor:
  static DHT_PULSES_   ::= 41      // Bit pulses produced by DHT sensor. Initialization + 40 bits data
  static DHT_MAXCOUNT_ ::= 200_000 // Timeout while waiting for edges

  dht_pin_       := ?
  dht_signal_pin_ := ?

  // We need one pin for reading and one pin for writing since using the same pin and switching it
  // between being input and output takes too long.
  constructor pin/int signal_pin/int:
    dht_pin_     = gpio.Pin pin       --input
    dht_signal_pin_ = gpio.Pin signal_pin
    dht_signal_pin_.config --open_drain --output

    dht_signal_pin_.set 1 // Default '1'. Setting to '0' starts the DHT sensor.

    sleep    --ms=1000 // Allow the sensor to stabilize after power-up.

  /**
  Reads the temperature and humidity from the DTH11 and returns a List, containing
    [temperature, humidity].
  If [-1,-1] is returned, this indicates that it was not
    possible to read from the sensor.
  If [-2,-2] is returned, there was an error in the data checksum
  */
  read_sensor -> List:
    readTries   := 0
    threshold   := 0
    data        := List 5 0
    pulse_counts := List DHT_PULSES_*2 0 // Should be initial bits + 40 bits with zeros inbetween

    // Retry reading DHT a few times if not working
    pulse_counts = read_
    while pulse_counts[0] == -1:
      sleep --ms=100
      pulse_counts = read_
      if ++readTries > 3:
        return [-1, -1]

    // Check length of low segments. According to DHT specs, these should be 50us.
    // This will be our baseline threshold when extracting bytes
    threshold = calc_hreshold_ pulse_counts
    data      = extract_bytes_  pulse_counts threshold

    // Checksum control
    if data[4] == (data[0] + data[1] + data[2] + data[3]) & 0xFF:
        return [data[2], data[0]] //Return temp and hum in that order
    else:
        return [-2, -2]

  /**
  Triggers the DHT11 sensor to emit data stream, and subsequently reads this bit stream.
  Returns list with pulse durations if successful.
  Returns list [-1] if timeout while reading.
  */
  read_ -> List:
    pulse_counts := List DHT_PULSES_*2 0  // Should be initial bits + 40 bits with zeros inbetween.
    count       := 0
    i           := 0

    // Time critical section starts here. Avoid adding code!
    // Send start signal to DHT11 sensor: >=18 ms LOW
    dht_signal_pin_.set 0
    sleep --ms=18
    dht_signal_pin_.set 1

    // Immediately start waiting for falling edge
    while dht_pin_.get == 1:
      if ++count >= DHT_MAXCOUNT_:
        return [-1]

    // Record pulse widths for the expected result bits.
    for i = 0; i < DHT_PULSES_ * 2; i += 2:
      // The low signal is 50us long.
      // The high signal can be as short as 26us. As such we want to do more
      // work in the beginning or the end.
      pulse_count_low := 0
      pulse_count_high := 0

      // Count how long pin is low and store in pulse_counts[i]
      while dht_pin_.get != 1:
        if ++pulse_count_low >= DHT_MAXCOUNT_:
          return [-1]

      // Count how long pin is high and store in pulse_counts[i+1]
      while dht_pin_.get == 1:
        if ++pulse_count_high >= DHT_MAXCOUNT_:
          return [-1]

      pulse_counts[i] = pulse_count_low
      pulse_counts[i+1] = pulse_count_high

    // Time critical section stops here.
    //print "pulse_counts: $pulse_counts"
    return pulse_counts

  /**
  Calculates the average of pulse lengths between bits (threshold).
  */
  calc_hreshold_ pulse_counts/List -> int:
    pulse_sum := pulse_counts.reduce: | a b | a + b
    threshold := pulse_sum / (DHT_PULSES_ - 1)
    return threshold

  /**
  Extracts the data bytes from the received bit stream from the DHT11.
  If the length of a high pulse is < threshold, it should be interpreted as a '0'.
  If the length of a high pulse is >= threshold, it should be interpreted as a '1'.
  */
  extract_bytes_ pulse_counts/List threshold/int -> List:
    i     := 0
    index := 0
    data  := List 5 0

    for i = 3; i < DHT_PULSES_ * 2 ;i += 2:
      index = (i-3)/16 // Increase index every 8th iteration (8bits shifted in before taking next element in data list)
      data[index] = data[index] << 1
      if pulse_counts[i] >= threshold:
        data[index] = data[index] | 0b0000_0001 // Add a '1'' at LSB if long pulse
    //else
        //just leave the zero

    return data
