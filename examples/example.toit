// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import dht11
import gpio

PIN_NUMBER ::= 32

main:
  sensor := dht11.Dht11 (gpio.Pin PIN_NUMBER)

  // DHT11 has a minimum sampling period of 1s.
  (Duration --ms=1_200).periodic:
    exception := catch:
      print sensor.read
    if exception:
      print "Error: $exception"
