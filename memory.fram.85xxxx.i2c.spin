{
    --------------------------------------------
    Filename: memory.fram.85xxxx.i2c.spin
    Author: Jesse Burt
    Description: Driver for 85xxxx series FRAM memories
    Copyright (c) 2020
    Started Oct 27, 2019
    Updated Dec 28, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 400_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR

    byte _addr_bits

OBJ

    i2c : "com.i2c"
    core: "core.con.85xxxx.spin"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 400kHz
    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ, %000)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): okay
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   lookdown(ADDR_BITS: %000..%111)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(1)
                _addr_bits := ADDR_BITS << 1
                ' check device bus presence
                if i2c.present(SLAVE_WR | _addr_bits)
                    return okay

    return FALSE                                ' something above failed

PUB Stop{}
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate{}

PUB DeviceID{} | tmp
' Read manufacturer ID from FRAM
    i2c.start{}
    i2c.write(core#RSVD_SLAVE_W)
    i2c.write(SLAVE_WR | _addr_bits)

    i2c.start{}
    i2c.write(core#RSVD_SLAVE_R)
    repeat tmp from 2 to 0
        result.byte[tmp] := i2c.read(tmp == 0)
    i2c.stop{}

PUB Manufacturer{}
' Read manufacturer ID
'   Known values: $00A (Fujitsu)
    result := (deviceid{} >> 12) & $FFF

PUB PartSize{}: size
' Size/density of FRAM chip, in kbits
'   Known values: 256, 512, 1024
'   NOTE: Entries for 4..128kbits are unverifed
'       (mfr. datasheet doesn't specify)
    size := (deviceid{} >> 8) & %1111
    return lookup(size: 4, 16, 64, 128, 256, 512, 1024)

PUB ProductID{}
' Read Product ID
'   Known values: $510 (MB85RC256)
    result := deviceid{} & $FFF

PUB ReadByte(fram_addr)
' Read one byte from FRAM
    readreg(fram_addr, 1, @result)

PUB ReadBytes(fram_start_addr, nr_bytes, ptr_buff)
' Read multiple bytes from FRAM
'   NOTE: If nr_bytes is greater than the number of bytes from the specified start address
'       to the end of the FRAM memory, any reads past the end will wrap around to address $0000
'       Example:
'           A 32kByte FRAM is connected, therefore the end of its memory is $7FFF
'           fram_start_addr is specified as $7FFE
'           nr_bytes is specified as 4
'           Locations actually read:
'           $7FFE, $7FFF, $0000, $0001
    readreg(fram_start_addr, nr_bytes, ptr_buff)

PUB WriteByte(fram_addr, data)
' Write one byte to FRAM
    writereg(fram_addr, 1, @data)

PUB WriteBytes(fram_start_addr, nr_bytes, ptr_buff)
' Write multiple bytes to FRAM
'   NOTE: If nr_bytes is greater than the number of bytes from the specified start address
'       to the end of the FRAM memory, any writes past the end will wrap around to address $0000
'       Example:
'           A 32kByte FRAM is connected, therefore the end of its memory is $7FFF
'           fram_start_addr is specified as $7FFE
'           nr_bytes is specified as 4
'           Locations actually written:
'           $7FFE, $7FFF, $0000, $0001
    writereg(fram_start_addr, nr_bytes, ptr_buff)

PRI readReg(reg, nr_bytes, ptr_buff) | cmd_pkt
' Read num_bytes from the slave device into the address stored in ptr_buff
    case reg
        $00_00..$FF_FF:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg.byte[1]
            cmd_pkt.byte[2] := reg.byte[0]
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rd_block(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}
        other:
            return

PRI writeReg(reg, nr_bytes, ptr_buff) | cmd_pkt
' Write num_bytes to the slave device from the address stored in ptr_buff
    case reg
        $00_00..$FF_FF:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg.byte[1]
            cmd_pkt.byte[2] := reg.byte[0]
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 3)
            i2c.wr_block(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return


DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
