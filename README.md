# Custom serial transfer utility for RC2014/RomWBW

Piggy is an optimised serial file transfer protocol - custom built - to minimise the time it take to
transmit a file from a PC to a RC2014 or RomWBW based Z80 computer.

Its designed to run under CPM with HBIOS support.

## How to

run the following on the PC

`node piggyserver.js --port COM6 --baud 115200`

> for more options run `node piggyserver.js --help`

On the RC2014 unit, under CPM

`pget.com <FILE>`

## Setup and prepare

Connect PC to RC2014 via the 2nd serial port.

copy the binary pget.com to your RC2014 using XM (xmodem)

## Building/installing

`npm ci`

`make`

## Build prerequisite

* [z88dk](https://github.com/z88dk/z88dk)
* [node v14.7 or higher](https://nodejs.org/)
