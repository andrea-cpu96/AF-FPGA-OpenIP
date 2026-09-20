# I2C Master — Architecture Document

> **Living document** — updated continuously as the design progresses.
> Target device: Intel Cyclone IV E **EP4CE6E22C8** · Quartus Prime **20.1.0 Lite**
> Top-level entity: `I2C_Master` (`I2C_Master.vhd`) — **implemented and verified** (RTL complete, TB suite 8/8 green, Analysis & Elaboration clean)

---

## 1. System Overview

Single-master **I2C Standard-mode (≤ 100 kHz)** controller: one transaction FSM under one top-level entity, orchestrating reusable sub-blocks.

- **`I2C_Master` FSM** — the sole owner of the bus: START/STOP framing, the address + R/W byte, the per-byte acknowledge phases, the repeated START and all Standard-mode timings. SDA is open-drain: the master only ever pulls it low (`'0'`) or releases it (`'Z'`); START/STOP, the ACK bits and the received data all rely on the external pull-up.
- **`I2C_TX:u_tx`** — byte serialiser: parallel byte in, one bit out per SCL falling edge, **MSB first** (I2C bit order).
- **`I2C_RX:u_rx`** — byte de-serialiser: one bit sampled per SCL rising edge (I2C data is valid while SCL is high), MSB first.
- **`clock_div:u_clk_div`** — divides `clk` down to SCL: `enable`-gated (parked low at IDLE, phase-aligned restart), `hold_high` freeze for the setup/hold intervals, `scl_in` feedback that holds the high phase while a slave stretches.

Key philosophy: **I2C is half-duplex on one shared wire**, so the bus framing belongs to one FSM alone; TX/RX only own the bit pacing of the bytes they handle and report a `byte_done` per byte. Every FSM transition is timed on the **real bus edges** (2-FF synchronised SCL/SDA), so a slave holding SCL low (clock stretching) simply delays the pulses — the master never fights the line.

One request = one full transaction: `n_write` data bytes written, then — through a **repeated START** — `n_read` data bytes read back after re-addressing the slave with R/W = 1 (the classic *write a register pointer, then read it back* idiom). Either count may be zero: write-only, read-only, or a bare address probe.

### 1.1 Module hierarchy

```
I2C_Master (top level: transaction FSM + bus framing + timings)
│
├── clock_div:u_clk_div            — SCL divider (enable-gated, hold_high freeze, scl_in stretch feedback)
│
├── I2C_TX:u_tx                    — byte serialiser (paces on SCL falling edges, MSB first)
│   └── parallel_to_serial:u_p2s   — N-bit load/shift register, G_MSB_FIRST = true
│
├── I2C_RX:u_rx                    — byte de-serialiser (paces on SCL rising edges, MSB first)
│   └── serial_to_parallel:u_s2p   — N-bit shift register, G_MSB_FIRST = true
│
├── 2-FF input synchronizers       — SDA and SCL (the only asynchronous inputs), To_X01-normalised
│
├── open-drain drivers             — SDA: pull-down / release
│                                    SCL: pull-down gated by scl_en_r / release
│
└── Standard-mode timing counters  — tHD;STA / tSU;STA / tSU;STO + bus-free tBUF timer
                                    (ns → clk cycles at elaboration, ceiling)
```

### 1.2 Top-level RTL view

*Not captured yet — pending (roadmap §9). The `I2C_DUT` sub-project (`I2C_DUT/`) is elaborated as a separate Quartus project for board-level verification.*

## 2. Module Map

| Module | Parent | Role | Status |
|---|---|---|---|
| `I2C_Master` | — | Transaction FSM: framing, ACK phases, timings, open-drain drivers, sync stages | ✅ |
| `clock_div` | `I2C_Master` | SCL divider; `enable`-gated, `hold_high` freeze, `scl_in` stretch feedback | ✅ |
| `I2C_TX` | `I2C_Master` | Byte serialiser, MSB first, paced on SCL falling edges | ✅ |
| `parallel_to_serial` (P2S) | `I2C_TX` | N-bit load/shift register, `G_MSB_FIRST = true` | ✅ |
| `I2C_RX` | `I2C_Master` | Byte de-serialiser, MSB first, paced on SCL rising edges | ✅ |
| `serial_to_parallel` (S2P) | `I2C_RX` | N-bit shift register, `G_MSB_FIRST = true` | ✅ |
| `I2C_DUT` | — (separate project `I2C_DUT/`) | Board wrapper: 4-pin interface + stimulus FSM for oscilloscope/logic-analyzer probes | ✅ |

> Reuse note: `parallel_to_serial` / `serial_to_parallel` are the same converter modules used by the UART project, extended with a **`G_MSB_FIRST` generic** (default `false` = UART LSB-first, behaviour unchanged; `true` = I2C MSB-first). The `I2C/` folder keeps its own copies of the sources.

### 2.1 Source files

All six RTL files are registered in `I2C_Master.qsf`:

| File | Content |
|---|---|
| `I2C_Master.vhd` | `I2C_Master` — transaction FSM + drivers + timing constants |
| `clock_div.vhd` | `clock_div` |
| `I2C_TX.vhd` | `I2C_TX` (instantiates the P2S) |
| `I2C_RX.vhd` | `I2C_RX` (instantiates the S2P) |
| `parallel_to_serial.vhd` | `parallel_to_serial` (P2S, MSB-first capable) |
| `serial_to_parallel.vhd` | `serial_to_parallel` (S2P, MSB-first capable) |

Other files (not in the QSF):

| File | Content |
|---|---|
| `I2C_DUT/I2C_DUT.vhd` | board DUT wrapper — own Quartus project (`I2C_DUT/I2C_DUT.qsf`, same device) |
| `tmpack_tb.vhd` | throwaway ACK-handover check on a simulated bus (VHDL-2008 external-name probe of `ack_reg`/`sda_reg`); kept for reference |
| `I2C_Master.vhd.before_*.bak` | historical backups (pre protocol-fix / pre repeated-START) |

### 2.2 Simulation folders (one project = one DUT = one TB)

| Folder | Testbench | Scope |
|---|---|---|
| `sim_i2c_tx/` | `i2c_tx_tb.vhd` | byte serialisation: bit order, busy/`byte_done` alignment, stretched cell, back-to-back |
| `sim_i2c_rx/` | `i2c_rx_tb.vhd` | byte capture: MSB-first rebuild, ACK-cell immunity, re-arm |
| `sim_i2c_master/` | 5 TBs (see §8) | transaction level: write / read / stretch / multibyte / Sr + multi-stretch |
| `sim_i2c_freq/` | `i2c_master_freq_tb.vhd` | SCL frequency: ceiling divider (`G_I2C_FREQ` as a **maximum**) |

All TBs are simulation-only and are **not** registered in `I2C_Master.qsf`.

---

## 3. Top-Level — `I2C_Master`

### 3.1 External interface (as implemented)

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | System clock |
| `rst_n` | in | 1 | Reset, active-low (synchronous inside the block) |
| `w` / `r` | in | 1 | Write / read request — level, hold until `busy = '1'`, then drop; `r` wins if both are high |
| `addr[6:0]` | in | 7 | 7-bit slave address (captured when the request is accepted) |
| `data_to_transmit[7:0]` | in | 8 | Next write byte — sampled per byte; update on each `tx_data_done` pulse |
| `n_write[3:0]` | in | 4 | Data bytes in the write phase (default `0001`; 0 = none) |
| `n_read[3:0]` | in | 4 | Data bytes to read after the repeated START (default `0000`) |
| `data_to_read[7:0]` | out | 8 | Last complete read byte (registered; zero on reset) |
| `tx_done` | out | 1 | 1-clk pulse: address **or** data byte fully serialized |
| `tx_data_done` | out | 1 | 1-clk pulse: write-data byte serialized (streaming handover) |
| `rx_valid` | out | 1 | 1-clk pulse: a read byte landed in `data_to_read` |
| `busy` | out | 1 | `'1'` while a transaction is in progress |
| `ack` | out | 1 | Last sampled slave ACK: `'0'` = ACK, `'1'` = NACK |
| `sda` | inout | 1 | I2C data line (open-drain, external pull-up) |
| `scl` | inout | 1 | I2C clock line (open-drain, external pull-up) |

Generics: `G_CLK_FREQ` (default 50 MHz), `G_I2C_FREQ` (default 100 kHz — Standard-mode maximum; the generated SCL **never exceeds** it, decision #1).

### 3.2 Utilizzatore contract

- **Request:** assert `w` or `r` (level) and keep it until `busy = '1'`, then drop it. The `request_armed` flag requires the request to be **deasserted** (both `w` and `r` low for at least one clk) before the next transaction — a held level never re-triggers after STOP. If both are high at acceptance, the read wins.
- **Write phase:** the *first* data byte is taken from `data_to_transmit` at the end of the address ACK cell; each following byte on the corresponding `tx_data_done` pulse (one SCL period of headroom). With `n_write = 1` nothing needs streaming.
- **Read phase:** consume `data_to_read` on each `rx_valid` pulse — registered together with the byte, so the pulse always selects that byte, and it arrives well before the closing STOP.
- **NACK handling:** `ack` shows the last sampled ACK. A NACK on the address terminates the transaction with a clean STOP (no data phase); a NACK on a write byte aborts the remaining phases. A NACK is never driven by the master on the write path (it only ACKs its own read bytes, see §5.3).
- `w`, `r`, `addr`, `data_to_transmit`, `n_write`, `n_read` must be **synchronous to `clk`**. A producer on a different clock must synchronize/handshake upstream of this block.
- Parameter constraints (asserted at elaboration): `G_CLK_FREQ ≥ 2 × G_I2C_FREQ`, `G_I2C_FREQ ≤ 100 kHz`, and the generated SCL phases must be wide enough for Standard-mode tLOW/tHIGH.

---

## 4. Transaction FSM and Bus Clock — `I2C_Master` + `clock_div`

### 4.1 Transaction FSM (14 states)

```
IDLE ─ w/r request (bus free ≥ tBUF) ─► START ─ hold tHD;STA ─► ADDR_RW ─ byte_done ─► ACK_ADDR
     ◄──────── STOP_RELEASE ◄─ STOP_HOLD ◄─ STOP ◄─ ACK_DATA / ACK_RX / ACK_ADDR(NACK) ──┘
ACK_ADDR ─► DATA_W ⇄ ACK_DATA (×n_write)      ACK_ADDR ─► DATA_R ⇄ ACK_RX (×n_read)
ACK_DATA (rd pending) ─► RSTART → RSTART_HOLD → RSTART_SDA_HOLD → START   (Sr, R/W flips to 1)
```

| State | Role |
|---|---|
| `IDLE` | SCL gated off (bus released high); counts continuous bus-free time (`bus_free_cnt` → tBUF); accepts one request (`request_armed`) and latches `addr`/`rw_reg`/`n_write`/`n_read` |
| `START` | SDA falls while SCL is still high (that **is** the START); times the tHD;STA hold, then releases the SCL gate (`scl_en_r`) — the divider's parked-low output reaches the pin and SCL falls for real |
| `ADDR_RW` | `I2C_TX` shifts out `{addr(6:0), rw}` MSB first; `tx_data = addr_reg & rw_reg` in this state |
| `ACK_ADDR` | SDA released, slave owns the cell; ACK sampled across the whole high phase on the **real bus level** (rides out a stretch); NACK → STOP; else branch to DATA_W / DATA_R / RSTART by the counters |
| `DATA_W` | next write byte, same handshake; `tx_data = data_to_transmit` |
| `ACK_DATA` | sample the slave ACK; branch: more writes / Sr (read pending) / STOP; NACK aborts |
| `DATA_R` | `I2C_RX` owns the byte (armed on entry); `rx_valid` pulses on byte_done; SDA hands over on the cell-closing falling edge |
| `ACK_RX` | master drives ACK (`'0'`) for every read byte except the last; NACK (`'1'`) on the last so the slave releases SDA for the STOP |
| `RSTART` / `RSTART_HOLD` / `RSTART_SDA_HOLD` | repeated START: SCL already running; wait for the real rise, time tSU;STA (divider frozen by `hold_high`), then hold SDA low for tHD;STA and re-enter START |
| `STOP` / `STOP_HOLD` / `STOP_RELEASE` | SDA held low through the rising edge, tSU;STO timed with the divider frozen, then SDA released — the actual STOP edge; IDLE re-arms the tBUF timer |

### 4.2 Timing (Standard-mode, computed at elaboration)

`cycles_for_ns()` converts absolute ns requirements to clk cycles with a **ceiling**; `safe_divider()` does ceiling division `clk/i2c`, so `G_I2C_FREQ` acts as a **maximum** (50 MHz/90 kHz → divider 556 = 89.93 kHz, never 90.09 kHz). Counter range `C_TIMER_MAX` = max(half-period, tHD;STA, tSU;STA, tSU;STO, tBUF) so the counters can never overflow. Verified by `i2c_master_freq_tb` (§8).

| Constant | Spec | Purpose |
|---|---|---|
| `C_DIVIDER` | `ceil(G_CLK_FREQ/G_I2C_FREQ)` | SCL period (500 clks @ 50 MHz/100 kHz) |
| `C_TLOW` / `C_THIGH` | 4.7 µs / 4.0 µs | assert that the SCL phases meet the spec minimums |
| `C_THD_STA` | 4.0 µs | START hold (also the initial half-period hold) |
| `C_TSU_STA` | 4.7 µs | repeated-START setup (SCL held high) |
| `C_TSU_STO` | 4.0 µs | STOP setup (SCL held high) |
| `C_TBUF` | 4.7 µs | bus-free time before a new START is accepted |

### 4.3 `clock_div` — actual interface

| Item | Dir | Description |
|---|---|---|
| `G_DIVIDER` | generic | `clk_out = clk / G_DIVIDER` (≥ 2) |
| `clk`, `rst_n` | in | Clock / active-low reset |
| `enable` | in | `'0'` = output parked low, counter reset → **deterministic phase** on the first enabled period |
| `hold_high` | in | `'1'` = freeze the current (high) output — tSU;STA / tHD;STA / tSU;STO are timed off the bus while SCL cannot fall |
| `scl_in` | in | resolved bus level: while low, the high phase is extended (clock-stretch tolerance inside the divider itself) |
| `clk_out` | out | **Registered** output — glitch-free |

---

## 5. Byte Paths — `I2C_TX` / `I2C_RX` and the Converters

### 5.1 `I2C_TX` — byte serialiser

Deliberately **no FSM**: a load counter plus the SCL edge detector is all a byte needs (half-duplex: the framing belongs to the master FSM).

- `send` captures the byte (`load = send`): the MSB is presented straight away — no stale level, no gap.
- One bit per SCL **falling** edge (`shift` = busy ∧ fall ∧ not-last-bit); the 9th fall pulses `byte_done` — exactly where the ACK bit cell starts.
- `tx_bit` is the P2S output (already registered); `busy` is registered, one driver per port.

### 5.2 `I2C_RX` — byte de-serialiser

- `receive` arms the capture; one bit sampled per SCL **rising** edge (data valid while SCL is high), MSB first through the S2P.
- The 8th rise samples the last bit and pulses `byte_done` at once (every bit is shifted in, so the last shift and the pulse share the clock edge).
- Fed from `sda_sync` (the synchronised bus copy), never the raw pin. ACK cells find it busy-low → no shift, captured byte untouched.

### 5.3 P2S / S2P — actual interface

| Item | P2S | S2P |
|---|---|---|
| Generics | `G_DATA_WIDTH` (8), `G_MSB_FIRST` (true for I2C) | same |
| Control | `load` (capture `data_in`), `shift` | `shift` only |
| Serial | `data_out` = MSB of the register (MSB-first mode) | `data_in` = `sda_sync` |
| Parallel | `data_in[7:0]` = `tx_data` | `data_out[7:0]` = captured byte |

`G_MSB_FIRST = true`: the P2S shifts left (`'0'` in at the LSB), the S2P shifts left so the first bit received ends in the MSB — without it the I2C byte would come out bit-reversed. The UART use (LSB-first) keeps the default `false`.

---

## 6. Signal Integrity and the Open-Drain Discipline

- **Open-drain everywhere** (commit 4094cb7, "I2C must have open driven lines"): `sda <= '0' when sda_reg = '0' else 'Z'`; `scl <= '0' when (scl_int = '0' and scl_en_r = '1') else 'Z'`. The master only pulls low or releases — it can never fight a slave.
- **2-FF synchronizers on SDA and SCL** — the only asynchronous inputs. The second stage is normalised with `To_X01`: the resolved open-drain bus reads back `'H'` for a released line, and `'H'` is not `'1'` for std_logic comparisons — without the normalisation a received bit would sit in the RX register as a weak `'H'` instead of a clean `'1'`.
- **Everything downstream reads the synchronized copies**: `sda_sync` feeds the ACK sample and `I2C_RX`; `scl_sync` (a.k.a. `scl_level`) feeds the FSM timing, the divider's `scl_in` and both byte engines; edge pulses (`scl_rise`/`scl_fall`) are combinational from the registered history so they react on the first clk edge after the bus edge.
- **Registered SDA output mux**: every SDA transition is uniformly delayed by one clk and the bit cells keep their width (SCL is far slower than clk) — the "SSBG role" pattern reused from the UART TX framing mux.
- **SCL gate `scl_en_r`**: `'1'` during a transaction, `'0'` at IDLE — the bus rests high between transactions and a slave stretching the previous transaction's last clock is never fought.
- The one-cycle SDA latency is compensated in the handovers: on the falling edge that completes a byte the mux releases SDA immediately (slave owns the ACK cell with no gap), and the next byte's MSB is presented on that same bus-low boundary when a leading `'0'` would otherwise be preceded by a short released-SDA glitch.

---

## 7. Design decisions

| # | Decision | Status |
|---|---|---|
| 1 | Standard-mode only (`G_I2C_FREQ ≤ 100 kHz`, asserted); ceiling divider so the frequency is a **maximum** | ✅ |
| 2 | Single owner of the bus: one transaction FSM (framing, ACK, timings); TX/RX own only bit pacing, no FSMs of their own | ✅ |
| 3 | Open-drain lines: pull-down or release only, external pull-ups; `'H'`/`To_X01` handling on the read side | ✅ |
| 4 | FSM timed on the **real bus edges** (2-FF synchronised) → clock stretching tolerated for free; divider adds `hold_high` + `scl_in` feedback so SCL cannot fall inside the setup/hold intervals | ✅ |
| 5 | Multi-byte transactions via `n_write`/`n_read` counts; read-after-write through **repeated START** (either count may be 0) | ✅ |
| 6 | Streaming handshakes: first write byte at address-ACK end, then one per `tx_data_done`; read bytes drained per `rx_valid` | ✅ |
| 7 | NACK: address NACK → clean STOP; data NACK aborts the remaining phases; `ack` exposes the last sample | ✅ |
| 8 | Reusable converters: P2S/S2P gained `G_MSB_FIRST` (default `false` — UART behaviour unchanged) | ✅ |
| 9 | Reset: active-low `rst_n`, synchronous; board-level reset synchronizer still to add | ✅ / 🚧 |
| 10 | Every module output is FF-driven (registered outputs at the module boundaries); 1-clk pulses for all the handshakes | ✅ |
| 11 | `I2C_DUT` board wrapper: 4-pin interface, internal stimulus FSM (write 0xA8 → Sr → read 0xAA → write 0xEE loop), oscilloscope/logic-analyzer friendly | ✅ |
| 12 | Language: VHDL (sim projects run with ModelSim `-2008`; the RTL itself is 93/2002-compatible style) | ✅ |

---

## 8. Verification

| TB | Folder | Scope | Status |
|---|---|---|---|
| `i2c_tx_tb` | `sim_i2c_tx/` | bytes `A5`, `3C` (stretched cell 5) and `81` back-to-back: MSB-first order, exactly one shift per fall, `byte_done` on the 9th fall, busy alignment, idle-cell immunity | ✅ PASS |
| `i2c_rx_tb` | `sim_i2c_rx/` | `A5` then `3C` rebuilt MSB first, one `byte_done` per byte, ACK cell does not corrupt the byte, re-arm | ✅ PASS |
| `i2c_master_tb` | `sim_i2c_master/` | write to 0x68, data 0xA5, ACKing slave; 18 captured SDA bits at the SCL rises (addr + ACK + data + ACK) | ✅ PASS |
| `i2c_master_read_tb` | `sim_i2c_master/` | public read output: bytes 0x65 / 0x96, output held during the address phase, reset behaviour | ✅ PASS |
| `i2c_master_stretch_tb` | `sim_i2c_master/` | clock stretching: slave holds SCL through the address-ACK cell + fixed window; master never raises SCL, stretched ACK sampled, byte 0x2D received | ✅ PASS |
| `i2c_master_multibyte_tb` | `sim_i2c_master/` | W3 (`11 22 33`) and W1-Sr-R2 (`55` → Sr → `C3` + NACK on `7E`): both address bytes, every written byte, master ACK/NACK, Sr is a real Sr (no STOP+START gap), lines released | ✅ PASS |
| `i2c_master_stretch_multi_tb` | `sim_i2c_master/` | W2-Sr-R3 with **ten** scripted stretches (mid-cell + ACK-cell holds, some > 1 SCL period): all holds honoured at full duration, transfer survives, no STOP before the Sr, no Sr while stretched | ✅ PASS |
| `i2c_master_freq_tb` | `sim_i2c_freq/` | SCL period at 90 kHz (ceiling: divider 556 → 89.93 kHz) and 100 kHz (exactly 500 clks); measured within nominal + ≤ 4 clk | ✅ PASS |

Run notes:

- One ModelSim project per folder; compile the RTL from the parent folder + the local TB (see each folder's `sim_run.do`).
- All TBs are **self-checking**; the master-level TBs use black-box slave models (no hierarchical access) driving an open-drain bus (`'H'` pull-up) — `tmpack_tb.vhd` (VHDL-2008 external names) is the only exception and was a throwaway probe.
- The four `sim_i2c_master/` + `sim_i2c_freq/` runs are head-less: `vsim -c -do sim_run.do` (prints the PASS/FAIL verdict, `quit -code` on error).
- Re-verified live on 2026-09-20: `i2c_tx_tb`, `i2c_rx_tb` and both `i2c_master_freq_tb` configurations — 0 errors, 0 warnings; the five master-level runs show **0 errors** in `run_stdout.log`.

**Quartus Analysis & Elaboration:** clean for the main project (`I2C_Master.qsf`, all 6 files) and for the `I2C_DUT/` sub-project (same device, `TOP_LEVEL_ENTITY = I2C_DUT`).

---

## 9. Roadmap

- **Top-level RTL-viewer screenshot** (`doc/I2C_top_RTL_viewer.png`), to mirror the UART document.
- **Fast-mode (400 kHz)**: relax the `G_I2C_FREQ` assert, keep the ceiling divider, re-time the START/STOP intervals.
- **Multi-master support**: arbitration lost detection (monitor SDA while driving `'1'`), bus busy from START/STOP detection.
- **General call / 10-bit addressing** if needed by a target device.
- **Board reset synchronizer** on the `rst_n` pin at the top of the system hierarchy (as in the UART).
- **SDC constraints**: `set_false_path` SDA/SCL → first sync FFs, `set_output_delay` on the open-drain pins; then Fitter + timing sign-off.
- Clean up the historical `.bak` files once the design is stable.

---

## 10. Changelog

Built from the git history of the `I2C/` folder (oldest first).

| Version | Date | Commit | Changes |
|---|---|---|---|
| 0.1 | 2026-09-13 | `f4113b0` | Quartus project + first sources: `I2C_Master` and `clock_div` with their testbench |
| 0.2 | 2026-09-14 | `f5c63af` | `clock_div` promoted to a reusable IP with its own testbench |
| 0.3 | 2026-09-14 | `96d4bd7` | I2C architecture set up: `I2C_TX` serialiser path, address + data sending (commit `5523b0a` on 09-15) |
| 0.4 | 2026-09-15 | `5523b0a` | Sending of the address and the data to the receiver implemented |
| 0.5 | 2026-09-15 | `6f3b7bf` | Data acknowledge and STOP condition added to the TX path |
| 0.6 | 2026-09-15 | `4094cb7` | **Open-drain fix**: the I2C lines must be open-driven — pull-down/release only (decision #3) |
| 0.7 | 2026-09-16 | `0d4ad14` | `I2C_RX` added with its testbench |
| 0.8 | 2026-09-17 | `e8248ea` | MSB handling added to `serial_to_parallel` (later generalised to the `G_MSB_FIRST` generic, shared with the UART converters) |
| 0.9 | 2026-09-17 | `c981cc6` | RX module + FSM status wired into `I2C_Master` |
| 0.10 | 2026-09-18 | `17647d2` | **Clock stretching** feature: FSM timed on the real bus edges, `scl_en_r` SCL gate, divider `scl_in` feedback (decision #4) |
| 0.11 | 2026-09-18 | `d6bd88a` | **Repeated START** + fixes: RSTART states, `n_write`/`n_read` multi-byte interface |
| 0.12 | 2026-09-19 | `e4ddbe8` | Protocol fixes (see the `.before_protocol_fix.bak` backups) |
| 0.13 | 2026-09-19 | `6261e82` | `I2C_DUT` board wrapper added to verify the master on the bench |
| 1.0 | 2026-09-20 | `9bf01e0` | **I2C master verified**: full TB suite green (write / read / stretch / multibyte / Sr + 10 stretches / freq), live re-run of TX/RX/freq — 0 errors, 0 warnings |






