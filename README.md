# mb85rc-spin 
-------------

This is a P8X32A/Propeller driver object for MB85RCxxx series FRAM from Fujitsu

## Salient Features

* I2C connection at up to 1MHz
* Read, write a single byte, or multiple bytes per transaction
* Read device ID
* Supports alternate slave addresses

## Requirements

* 1 extra core/cog for PASM I2C driver

## Compiler Compatibility

- [x] OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO

- [x] Implement support for alternate slave addresses
