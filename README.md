# DHT11

A Toit driver for the DHT11 temperature and humidity sensor.

## Usage

A simple usage example.

```
import ..src.DHT11

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
```

See the `examples` folder for more examples.

## Features and bugs

[tracker]: https://github.com/nilwes/DHT11/issues
