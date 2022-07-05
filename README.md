# DHT11

A Toit driver for the DHT11 temperature and humidity sensor.

This package uses bit-banging to communicate with the sensor. A more recent
  package `dhtxx` uses the RMT peripheral for communication and is thus significantly
  more stable and uses less CPU. If you are using the open-source version of Toit,
  then prefer the dhtxx package.

## Usage

A simple usage example:

```
import dht11
import gpio

PIN_NUMBER ::= 32

main:
  sensor := dht11.Dht11 (gpio.Pin PIN_NUMBER)

  (Duration --ms=500).periodic:
    exception := catch:
      print sensor.read
    if exception:
      print "Error: $exception"
```
