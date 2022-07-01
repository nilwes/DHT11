// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

/**
This example illustrates how to use the DHT11 sensor with Toit
Normally, the same GPIO pin would be used as output for triggering the sensor,
  and subsequently switched to input for reading the response.
However since the DHT response comes so quickly, there is no time to
  switch the pin from output to input. Hence two pins are needed: One
  for triggering the data, and a second for reading data.
Both should be connected to the data pin of your DTH sensor.
*/

import dht11.DHT11 show *

dataPin   ::= 13
signalPin ::= 12

main:

  sensorData := []
  sensor     := DHTsensor dataPin signalPin

  sensorData = sensor.read_sensor

  if sensorData[0] >= 0:
    print "Temperature: $sensorData[0]"
    print "Humidity: $sensorData[1]"
  else if sensorData[0] == -1:
    print "Error reading sensor"
  else if sensorData[0] == -2:
    print "Checksum error"
  else if sensorData[0] < -2:
    print "Unknown error reading sensor"
