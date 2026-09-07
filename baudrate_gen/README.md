# Baudrate Generator (BRG)

> **Reusable, project-independent module** — divides the system clock into a single-cycle `baud_tick` pulse for UART timing.
> 
> Originally developed as part of the [UART](../UART/) IP, extracted here as a standalone reusable block.

## Overview

The `baudrate_gen` is a clock-divider module that generates a single-cycle tick (`baud_tick`) every `divider` clock cycles. It is used in both the UART transmitter and receiver to time bit-level operations.

## Features

- **Configurable divider**: set via `divider` input (supports runtime changes)
- **Phase offset**: `G_PHASE_OFFSET` generic preloads the counter while disabled, enabling mid-bit sampling (RX) or edge-aligned timing (TX)
- **Enable-gated**: counter frozen when `enable = '0'`, with automatic phase pre-arming
- **Combinational tick output**: zero-latency terminal-count pulse (no registered output that would stretch the start bit)

## Interface

### Generics

| Generic | Type | Default | Description |
|---------|------|---------|-------------|
| `G_PHASE_OFFSET` | natural | 0 | Counter preload while disabled. First tick lands `divider - G_PHASE_OFFSET` edges after enable rises. `0` = edge-aligned (TX), `divider/2` = mid-bit (RX). |

### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | in | std_logic | System clock |
| `rst_n` | in | std_logic | Active-low asynchronous reset |
| `enable` | in | std_logic | Counter enable (high = running) |
| `divider` | in | integer | Division ratio (tick period = `divider` clock cycles) |
| `baud_tick` | out | std_logic | Single-cycle tick pulse (combinational) |

## Architecture

```
clk ──────┐
          │
rst_n ────┤    ┌─────────────────┐
          ├───►│   baudrate_gen  │
enable ────┤    │                 │──► baud_tick
          │    │  counter: 0→N-1 │
divider ──┘    └─────────────────┘
```

The counter increments on each rising clock edge when `enable = '1'`. When it reaches `divider - 1`, it wraps to 0 on the next cycle. The `baud_tick` output goes high for exactly one clock cycle when the counter equals `divider - 1`.

## Usage

```vhdl
u_brg : entity work.baudrate_gen
    generic map (
        G_PHASE_OFFSET => 0          -- edge-aligned (TX)
    )
    port map (
        clk       => clk,
        rst_n     => rst_n,
        enable    => baud_enable,
        divider   => baud_divider,    -- e.g. 434 for 115200 Bd @ 50 MHz
        baud_tick => baud_tick
    );
```

## Testbench

The self-checking testbench (`baudrate_gen_tb.vhd`) verifies:

1. **Tick period** equals `divider` clock cycles (tick-to-tick measurement)
2. **First tick after reset** arrives exactly `divider` edges after reset release
3. **Pulse width** equals 1 clock cycle (for `divider >= 2`)
4. **Mid-run reset** re-aligns the counter correctly

Tested dividers: `4`, `10`, `433` (115200 Bd @ 50 MHz), `5208` (9600 Bd @ 50 MHz).

### Running the simulation

```tcl
# From the baudrate_gen/ folder, in ModelSim:
do sim_run.do
```

## File List

| File | Description |
|------|-------------|
| `baudrate_gen.vhd` | RTL source |
| `baudrate_gen_tb.vhd` | Self-checking testbench |
| `sim_run.do` | ModelSim run script |

## Notes

- `divider = 1` is not tested: the tick stays high continuously (period = 1, no isolated pulse)
- `divider = 0` would hang the DUT (counter never matches `-1`)

