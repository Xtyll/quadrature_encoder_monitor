# The quadrature encoder monitor

The repo contains 2 modules:

* encoder_monitor
* encoder_emulator

## encoder_monitor

Receives the external encoder signals, decodes them, and sends a message with the current value through the AXIStream interface.
The current encoder position is also available through the AXI4Lite interface.
The user is able to set a required value through the AXI4Lite interface.
The module doesn't contain any dedicated addresses in the AXI4Lite bus. So writing to any address will set the value, reading from any address return a value.

## encoder_emulator

Implemented just to simplify the `encoder_monitor` debugging. The `encoder_emulator` emulated the real encoder with the required parameters.
The module contains 3 registers available through AXI4Lite

|name               | offset | description|
|-------------------|--------|------------|
|p_end_value_addr   |    0x00| Set the maximum value of the encoder. When the value will be achieved the module will finish the generation of a new value. When the end value is updated the encoder switch to the initial state |
|p_clk_divider_addr |    0x10| The main clock divider. Sets the number of system clocks per one encoder step |
|p_direction_addr   |    0x20| Seth the encoder direction |

## Wrappers

Each RTL module is implemented in the SV with SV interfaces. To provide the chance to use modules in the Vivado BD implemented wrappers with Verilog-style interfaces

## TODO

The modules required some refactoring:

* Add `default_nettype none` to all RTL modules
* Add a dedicated addresses and registers map to the `encoder_monitor`
* Move an AXI4Lite slave to a dedicaЁted common module
* Add byteenable support to the AXI4Lite interface
* Add checkers to testbenches
* Add a regression script for modules and a list of tests
* Rework the current regression scripts to remove the dedicated Vivado version lock
