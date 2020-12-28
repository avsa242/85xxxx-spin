# 85xxxx-spin
-------------

This is a P8X32A/Propeller driver object for I2C FRAM memories

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 1MHz
* Supports densities up to 1Mbit
* Read, write a single byte, or multiple bytes per transaction
* Read device ID (for devices that support it)
* Supports alternate slave addresses

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FlexSpin (tested with 5.0.0)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Mfr/density combinations other than Fujitsu 256kbit are untested

## TODO

- [x] Implement support for alternate slave addresses
- [x] Port to P2/SPIN2
