# DHT11

A Toit driver for the DHT11 temperature and humidity sensor.

The temperature is returned in Celcius in a 2-element list. Temperature is stored in the first element. Humidity is stored in the second.

## Usage

You will need two GPIO pins to use this driver. Normally, a single 
GPIO pin would be used as output for triggering the sensor, 
and subsequently switched to input for reading the response.
However, since the DHT response comes so quickly, there is no time to
switch the pin from output to input. Hence two pins are needed: One
for triggering the data, and a second for reading data.
Both should be connected to the data pin of your DTH sensor.

A simple usage example:

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
