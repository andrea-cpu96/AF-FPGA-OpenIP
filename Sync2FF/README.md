# Sync2FF — Two-Flip-Flop Synchronizer

> **Reusable, project-independent module** — resynchronizes a single-bit asynchronous level into the `clk` domain.

## Overview

The `sync_2ff` module implements the classic two-flip-flop synchronizer for single-bit **level** signals crossing from an asynchronous source (board pin, foreign clock domain) into the `clk` domain. The first flip-flop may go metastable when `async_in` violates `clk` setup/hold; the second flip-flop gives the downstream logic a clean, settled sample.

## Features

- **Metastability protection**: 2-FF chain gives the metastable first stage one full clock to settle
- **Registered output**: `sync_out` is FF-driven — glitch-free at the module boundary
- **Constant latency**: exactly 2 `clk` cycles from the sampling edge to `sync_out`
- **Minimal**: no reset (the chain settles within 2 clocks by itself; powers up at `'0'`), no generics

## Interface

### Ports

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk` | in | std_logic | Destination (receiving) clock domain |
| `async_in` | in | std_logic | Asynchronous level (or foreign-domain signal) |
| `sync_out` | out | std_logic | Synchronized level, 2 `clk` latency |

## Architecture

```
async_in ──► [ sync(0) ] ──► [ sync(1) ] ──► sync_out
                 │                │
clk ─────────────┴────────────────┘  (rising edges)
```

On every rising edge: `sync <= sync(0) & async_in;` — `sync_out <= sync(1);`

**Important**: this synchronizer is for **single-bit levels only**. Multi-bit buses need a handshake or a Gray-coded / async-FIFO crossing (a per-bit 2-FF sync would tear the bus). It also **cannot catch pulses shorter than one `clk` period** — use an edge-catcher/toggle synchronizer for those.

## Usage

```vhdl
u_sync : entity work.sync_2ff
    port map (
        clk      => clk,
        async_in => button_pin,   -- e.g. asynchronous board input
        sync_out => button_sync   -- use THIS downstream (never the raw pin)
    );
```

## Testbench

The self-checking testbench (`sim_sync_2ff/sync_2ff_tb.vhd`) verifies:

1. **Power-up value** `'0'` (template init) while the input is quiet
2. **Constant 2-cycle latency**: every `async_in` transition sampled at edge N appears on `sync_out` at edge N+2
3. **Pattern tracking** over a 60-transition deterministic pseudorandom (LFSR-driven) toggle sequence with off-edge, asynchronous timing

Metastability itself cannot be produced in a zero-delay RTL simulation — functionality and latency only.

### Running the simulation

```tcl
# From the sim_sync_2ff/ folder, in ModelSim:
do sim_run.do
```

Batch (no GUI), from `sim_sync_2ff/`:

```
vsim -c -do sim_run.do
```

## File List

| File | Description |
|------|-------------|
| `sync_2ff.vhd` | RTL source |
| `sim_sync_2ff/sync_2ff_tb.vhd` | Self-checking testbench |
| `sim_sync_2ff/sim_run.do` | ModelSim run script |

## Notes

- **No reset on purpose**: resetting the sync chain is not required for correctness and the template keeps the FF pair minimal. Add CDC `set_false_path` (or `set_max_delay -datapath_only`) from `async_in` to `sync(0)` in the SDC constraints.
- Same 2-FF pattern already used inside `UART_RX` (`data_in_meta` → `data_in_sync`) — this module extracts it as a standalone reusable block.
