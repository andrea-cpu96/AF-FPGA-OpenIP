# Serial-to-Parallel Converter (S2P)

> **Reusable, project-independent module** — shifts in 8 serial bits LSB-first and presents them as a parallel byte.
> 
> Originally developed as part of the [UART](../UART/) IP, extracted here as a standalone reusable block.

## Overview

The `serial_to_parallel` is an 8-bit shift register that converts a serial bit stream into parallel data. It is used in the UART receiver to deserialize incoming data bits into bytes.

## Features

- **8-bit width**: standard byte-oriented interface
- **LSB-first shifting**: compliant with UART convention (first received bit lands in position 0)
- **Serial input**: single-bit data input
- **Async reset**: returns the register to all-zeros

## Interface

### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | in | std_logic | System clock |
| `rst_n` | in | std_logic | Active-low asynchronous reset |
| `shift` | in | std_logic | Shift enable (high = shift in one bit) |
| `data_in` | in | std_logic | Serial data input (shifted into MSB position) |
| `data_out` | out | std_logic_vector(7 downto 0) | Parallel data output |

## Architecture

```
clk ──────┐
          │
rst_n ────┤    ┌──────────────────────┐
          ├───►│  serial_to_parallel  │
shift ────┤    │                      │
          │    │  ┌──────────────┐    │
data_in ──┤    │  │  8-bit reg   │    │
          │    │  │  [7:0]       │────┼──► data_out
          │    │  └──────────────┘    │
          │    └──────────────────────┘
```

**Operation:**
1. When `shift = '1'`, the register shifts right by one position
2. `data_in` is shifted into the MSB (position 7)
3. After 8 shifts, the original byte is reconstructed in `data_out`

## Usage

```vhdl
u_s2p : entity work.serial_to_parallel
    port map (
        clk      => clk,
        rst_n    => rst_n,
        shift    => s2p_shift,
        data_in  => rxd_sync,
        data_out => rx_byte
    );
```

## Testbench

The testbench (`serial_to_parallel_tb.vhd`) verifies:

1. Shift in byte `0xA5` LSB-first → assert `data_out = 0xA5`
2. Shift in byte `0xC3` LSB-first → assert `data_out = 0xC3`
3. Reports hex-formatted mismatches on error

## File List

| File | Description |
|------|-------------|
| `serial_to_parallel.vhd` | RTL source |
| `serial_to_parallel_tb.vhd` | Testbench |
