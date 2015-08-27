# w65c816sxb-hacker
A tool for modifying the firmware on your WDC W65C816SXB Development Board

The SXB development board has a 128K Flash ROM that can be updated under
software control. The design of the SXB board divides the ROM into four 32K
banks and maps one these into the memory area between $00:8000 and $00:ffff.

On reset the choice of default bank is controlled by two pull up resistors
on the FAMS and FA15 signal tracks. Once your SXB is running you can change
the bank by configuring one or both of CA1 and CB1 as low outputs using the
PCR register of VIA2.

One or both of the LEDs next to FAMS and FA15 test points (beside the Flash ROM socket)
will light up when one of the reprogramable banks is enabled. If both LEDs
are off then the WDC firmware bank is enabled.

Reprogramming the ROM must be done very carefully. If you erase the WDC ROM
image in bank 3 then your will not be able to use the WDC TIDE tools to
recover your system.

## UART Connections

The hacking tool uses the ACIA to communicate with your PC and download new
ROM images. You will need a USB Serial adapter (like one of the cheap PL2303
modules with jumper wires sold on eBay) to establish a connection. You must
connect the TXD, RXD and GND lines between the SXB and the USB adapter. In
addition you must place a jumper wire between RTS and CTS on the ACIA
connector.

You will need a terminal program like AlphaCom or Tera Term on your PC that
supports XMODEM file transfers. Configure it to work at 19200 baud, 8 data
bits, no parity and 1 stop bit.

## Using W65C816SXB-Hacker

Use the WDC debugger to download the hacking tool to the SXB board and start
execution. The tool will respond with a message in the terminal software.

```
SXB-Hacker [15.08]
.
```
The 'M' command allows you to display memory, for example 'M FFE0 FFFF' will
display the vectors at the top of the memory
```
.M FFE0 FFFF
00:FFE0 FF FF FF FF 1C 81 08 81 19 81 0C 81 24 81 16 81 |............$...|
00:FFF0 1F 81 1F 81 10 81 1F 81 13 81 04 81 2B 81 00 81 |............+...|
```
Using the 'R' command you can pick another memory bank, like 0
```
.R 0
.M FFE0 FFFF
00:FFE0 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF |................|
00:FFF0 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF |................|
```
