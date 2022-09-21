{
    --------------------------------------------
    Filename: memory.fram.85xxxx.spin
    Author: Jesse Burt
    Description: Driver for 85xxxx series I2C FRAM
    Copyright (c) 2022
    Started Oct 27, 2019
    Updated Sep 21, 2022
    See end of file for terms of use.
    --------------------------------------------
}

#include "memory.common.spinh"

CON

    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR|1

    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000
    I2C_MAX_FREQ= core#I2C_MAX_FREQ

    { manufacturers }
    CYPRESS     = $004
    FUJITSU     = $00A

    ERASE_CELL  = $FF

VAR

    byte _addr_bits

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef 85XXXX_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.85xxxx"                     ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, %000)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   lookdown(ADDR_BITS: %000..%111) and I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            _addr_bits := ADDR_BITS << 1
            ' check device bus presence
            if i2c.present(SLAVE_WR | _addr_bits)
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    _addr_bits := 0

PUB device_id{}: id
' Read device identification
'   NOTE: This may not be supported by all devices
    i2c.start{}
    i2c.write(core#RSVD_SLAVE_W)
    i2c.write(SLAVE_WR | _addr_bits)

    id := 0
    i2c.start{}
    i2c.write(core#RSVD_SLAVE_R)
    i2c.rdblock_msbf(@id, 3, i2c#NAK)
    i2c.stop{}

PUB mfr_id{}: id
' Read manufacturer ID
'   Known values:
'       $004 (Cypress)
'       $00A (Fujitsu)
    return (device_id{} >> 12) & $FFF

PUB page_size{}: p
' Page size
'   NOTE: FRAM has no concept of pages, so just return the part's full size
    return (part_size{} / 8) * 1024

PUB part_size{}: size | devid, mfr
' Size/density of FRAM chip, in kbits
'   Known values:
'       mfr_id() == CYPRESS ($004): 256, 512, 1024
'       mfr_id() == FUJITSU ($00A): 256, 512, 1024
    devid := device_id{}
    mfr := (devid >> 12) & $FFF
    size := (devid >> 8) & %1111
    case mfr
        CYPRESS:
            return lookup(size: 1024, 256, 512)
        FUJITSU:
            return lookup(size: 0, 0, 0, 0, 256, 512, 1024)

PUB rd_block_lsbf(ptr_buff, addr, nr_bytes) | cmd_pkt
' Read a block of memory starting at addr, LSB-first
    case addr
        0..$FFFF:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        $1_0000..$1_FFFF:                       ' upper page (for 1Mbit FRAM)
            cmd_pkt.byte[0] := SLAVE_WR | core#PAGE_HI | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        other:
            return

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.start{}
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PUB rd_block_msbf(ptr_buff, addr, nr_bytes) | cmd_pkt
' Read a block of memory starting at addr, MSB-first
    case addr
        0..$FFFF:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        $1_0000..$1_FFFF:                       ' upper page (for 1Mbit FRAM)
            cmd_pkt.byte[0] := SLAVE_WR | core#PAGE_HI | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        other:
            return

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.start{}
    i2c.write(SLAVE_RD)
    i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PUB wr_block_lsbf(addr, ptr_buff, nr_bytes) | cmd_pkt
' Write a block of memory starting at addr, LSB-first
    case addr
        $00..$FFFF:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        $1_0000..$1_FFFF:
            cmd_pkt.byte[0] := SLAVE_WR | core#PAGE_HI | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        other:
            return

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}

PUB wr_block_msbf(addr, ptr_buff, nr_bytes) | cmd_pkt
' Write a block of memory starting at addr, MSB-first
    case addr
        $00..$FFFF:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        $1_0000..$1_FFFF:
            cmd_pkt.byte[0] := SLAVE_WR | core#PAGE_HI | _addr_bits
            cmd_pkt.byte[1] := addr.byte[1]
            cmd_pkt.byte[2] := addr.byte[0]
        other:
            return

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 3)
    i2c.wrblock_msbf(ptr_buff, nr_bytes)
    i2c.stop{}

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

