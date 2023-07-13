# 85xxxx-spin
-------------

This is a P8X32A/Propeller driver object for I2C FRAM memories

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 1MHz (P2 tested up to 700kHz)
* Supports densities up to 1Mbit
* Read, write a single byte, or multiple bytes per transaction
* Read device ID (for devices that support it)
* Supports alternate slave addresses

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for PASM I2C engine
* memory.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* memory.common.spin2h (provided by p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.1.1)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.1.1)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.1.1)       | NuCode       | FTBFS                 |
| P2        | SPIN2    | FlexSpin (6.1.1)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* Very early in development - may malfunction, or outright fail to build
* Mfr/density combinations other than Fujitsu 256kbit are untested

