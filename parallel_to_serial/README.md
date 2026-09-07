# Parallel-to-Serial Converter (P2S)

> **Reusable, project-independent module** — shifts an 8-bit byte out LSB-first, one bit per shift pulse.
> 
> Originally developed as part of the [UART](../UART/) IP, extracted here as a standalone reusable block.

## Overview

The `parallel_to_serial` is an 8-bit load/shift register that converts parallel data to a serial bit stream. It is used in the UART transmitter to serialize data bytes before transmission.

## Features

- **8-bit width**: standard byte-oriented interface
- **LSB-first shifting**: compliant with UART convention
- **Load and shift**: separate control signals for loading parallel data and shifting out bits
- **Async reset**: returns the register to all-zeros

## Interface

### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | in | std_logic | System clock |
| `rst_n` | in | std_logic | Active-low asynchronous reset |
| `shift` | in | std_logic | Shift enable (high = shift one position) |
| `load` | in | std_logic | Parallel load (high = load `data_in` into register) |
| `data_in` | in | std_logic_vector(7 downto 0) | Parallel data input |
| `data_out` | out | std_logic | Serial data output (current LSB) |

## Architecture

```
clk ──────┐
          │
rst_n ────┤    ┌──────────────────────┐
          ├───►│  parallel_to_serial  │
load ─────┤    │                      │
          │    │  ┌──────────────┐    │
data_in ──┤    │  │  8-bit reg   │    │
          │    │  │  [7:0]       │────┼──► data_out (LSB)
shift ────┘    │  └──────────────┘    │
               └──────────────────────┘
```

**Operation:**
1. When `load = '1'`, `data_in` is captured into the register
2. When `shift = '1'`, the register shifts right by one position (`'0'` shifted in at MSB)
3. `data_out` always reflects the current LSB (combinational output)

## Usage

```vhdl
u_p2s : entity work.parallel_to_serial
    port map (
        clk      => clk,
        rst_n    => rst_n,
        shift    => p2s_shift,
        load     => p2s_load,
        data_in  => tx_byte,
        data_out => txd
    );
```

## Testbench

The testbench (`parallel_to_serial_tb.vhd`) verifies:

1. Load byte `0xA5` into the register
2. Shift out 8 bits, asserting each bit matches the expected LSB-first sequence
3. Reports pass/fail status

## File List

| File | Description |
|------|-------------|
| `parallel_to_serial.vhd` | RTL source |
| `parallel_to_serial_tb.vhd` | Testbench |
