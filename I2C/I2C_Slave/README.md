# I2C Slave — Architecture Document

> **Living document** — updated as the design progresses.
> Target device: Intel Cyclone IV E **EP4CE6E22C8** · Quartus Prime **20.1.0 Lite**
> Top-level entity: `I2C_Slave` (`I2C_Slave.vhd`) — **implemented and verified** (RTL complete, TB suite 3/3 green, Analysis & Elaboration clean)
> Board DUT wrapper: `I2C_Slave_DUT` in its own project (`../I2C_Slave_DUT/`) — **implemented and verified** (4-pin interface, `0xAA` command → `0xEE` reply dialogue, DUT TB suite 2/2 green)

---

## 1. System Overview

Single-target **I2C Standard-mode (≤ 100 kHz)** peripheral: one transaction FSM
under one top-level entity, orchestrating the same reusable sub-blocks the
master uses plus the two blocks a *target* needs and a controller does not.

- **`I2C_Slave` FSM** — the sole owner of the bus on the slave side: address
  filtering, the ACK/NACK bits, the START / repeated-START / STOP
  interpretation, the read/write phase steering and the clock-stretch request.
  Both `sda` and `scl` are open drain: the slave only ever pulls a line low
  (`'0'`) or releases it (`'Z'`), so it can never fight the master.
- **`sync_2ff` ×2** — SCL and SDA input synchronisers (the only asynchronous
  inputs), followed by `To_X01` normalisation and a delayed copy for the edge
  detector.
- **`start_stop_detect`** — the framing detector: START / repeated START
  (SDA falls while SCL is high) and STOP (SDA rises while SCL is high).
- **`I2C_RX`** — byte de-serialiser: one bit per SCL **rising** edge (data is
  valid while SCL is high), MSB first. Captures the address and the written
  bytes.
- **`I2C_TX`** — byte serialiser: one bit per SCL **falling** edge, MSB first.
  Sends the bytes the master reads back.
- **`scl_stretch`** — **clock stretching**: holds SCL low for a programmable
  number of `clk` cycles; it only pulls the line down, so the master's clock
  generator can never end that phase early.

Key philosophy (mirrors the master): **I2C is half duplex on one shared wire**,
so the bus framing belongs to one FSM alone; TX/RX only own the bit pacing of
one byte and report a `byte_done` per byte. Every FSM transition is timed on the
**real bus edges**, never on a local divider, which is what makes a slave that
stretches SCL trivially legal — the master simply waits.

### 1.1 Features

| Feature | Details |
|---|---|
| **Write** | `<addr+W> <data>...` — every accepted byte appears on `data_received` with an `rx_valid` pulse; the slave ACKs each byte |
| **Read** | `<addr+R> <data>...` — `data_to_transmit` is sampled per byte (streamed, update it on `tx_done`); the slave samples the master's ACK/NACK and stops after a NACK |
| **Repeated START** | a write phase followed by `<Sr> + <addr+R>` re-enters the address phase **inside the same frame** (no STOP, the bus never goes idle) and flips the direction — the classic *write a register pointer, then read it back* idiom |
| **Clock stretching** | SCL is held low in the low phase of **every ACK bit cell** the slave takes part in, for `G_STRETCH_CYCLES` `clk` cycles (`0` compiles the feature out) |
| **Address filtering** | only `G_SLAVE_ADDR` is answered; any other address gets a NACK (SDA stays released) and the rest of the frame is ignored until the next START |

### 1.2 Module hierarchy

```
I2C_Slave (top level: transaction FSM + bus framing + host handshakes)
│
├── sync_2ff:u_sda_sync / u_scl_sync   — SCL/SDA 2-FF resynchronisers
│
├── start_stop_detect:u_start_stop     — START / repeated START / STOP detector
│
├── scl_stretch:u_stretch              — CLOCK STRETCHING: programmable SCL low hold
│
├── I2C_RX:u_rx                        — byte de-serialiser (paces on SCL rising edges)
│   └── serial_to_parallel:u_s2p       — N-bit shift register, G_MSB_FIRST = true
│
├── I2C_TX:u_tx                        — byte serialiser (paces on SCL falling edges)
│   └── parallel_to_serial:u_p2s       — N-bit load/shift register, G_MSB_FIRST = true
│
├── To_X01 + edge detection            — normalised bus levels, scl_rise / scl_fall
│
└── open-drain drivers                 — SDA: pull-down / release
                                        SCL: pull-down (stretch only) / release
```

The board-level sub-project (`../I2C_Slave_DUT/`, §2.3) wraps exactly this
hierarchy in `I2C_Slave_DUT`: the slave is used **unmodified**, an extra dialogue
FSM sits above the byte-stream interface (`0xAA` command written by an external
master → `0xEE` read back) and only `clk`, `rst_n`, `sda` and `scl` leave the
device — see §2.3 for the file/simulation map.

### 1.3 The ACK cell: why the FSM has `*_OPEN` states

Per byte the bus carries 8 data bit cells (the transmitter changes SDA while
SCL is low, the receiver samples on the rise) followed by the 9th, the **ACK
cell**. The rule that shapes the whole FSM is that *SDA may only change while
SCL is low* — an SDA transition during an SCL high phase is a START or a STOP,
not data. The slave therefore splits every ACK cell in two states:

| State | Entered on | Does |
|---|---|---|
| `ACKA_OPEN` / `ACKW_OPEN` | the 8th SCL rising edge (`byte_done`), i.e. **still inside the last bit's high phase** | waits for the falling edge that opens the ACK cell. SDA is left alone on purpose. On that edge it fires the stretch request |
| `ACKA` / `ACKW` | that falling edge | the ACK cell: the output mux pulls SDA low, SCL is stretched. Leaves on the **closing** falling edge, where the direction bit (or the next byte) is decoded |
| `ACKR` | `tx_byte_done`, i.e. the falling edge that opens the master's ACK cell | SDA released (the master drives the ACK), SCL stretched, the ACK bit sampled while SCL is high; ACK → next byte, NACK → frame over |

The same "one registered output mux, evaluated per state" pattern the master
uses is applied to SDA, so the handovers are glitch-free and every transition
happens on a bus-low boundary.

### 1.4 Requested frames

```
write frame              S | addr+W | A | data | A | ... | data | A | P
read frame               S | addr+R | A |   data | m | ... | data | N | P
write + read (the idiom) S | addr+W | A | pointer | A | Sr | addr+R | A | data | N | P
```
`S`/`Sr`/`P` = START / repeated START / STOP, `A`/`N` = acknowledge / not
acknowledge, `m` = the master's ACK/NACK for a byte it received. Only `addr+W`
is answered on the second frame; the whole repeated-START frame stays one busy
period on the slave side.

---

## 2. Module Map

| Module | Parent | Role | Status |
|---|---|---|---|
| `I2C_Slave` | — | Transaction FSM: address filtering, ACK cells, phase steering, stretch request, open-drain drivers | ✅ |
| `sync_2ff` | `I2C_Slave` | 2-FF resynchroniser of SCL and SDA | ✅ |
| `start_stop_detect` | `I2C_Slave` | START / repeated START / STOP condition detector | ✅ (new IP) |
| `scl_stretch` | `I2C_Slave` | Programmable SCL low hold (clock stretching) | ✅ (new IP) |
| `I2C_RX` | `I2C_Slave` | Byte de-serialiser, MSB first, paced on SCL rising edges | ✅ |
| `serial_to_parallel` | `I2C_RX` | N-bit shift register, `G_MSB_FIRST = true` | ✅ |
| `I2C_TX` | `I2C_Slave` | Byte serialiser, MSB first, paced on SCL falling edges | ✅ |
| `parallel_to_serial` | `I2C_TX` | N-bit load/shift register, `G_MSB_FIRST = true` | ✅ |
| `I2C_Slave_DUT` | — (separate project `../I2C_Slave_DUT/`) | Board wrapper: 4-pin interface + command/reply dialogue FSM (`0xAA` written → `0xEE` read back) for external controllers and scope/LA probes | ✅ |

> **Reuse note** — `sync_2ff`, `I2C_TX`, `I2C_RX`, `parallel_to_serial` and
> `serial_to_parallel` already existed in the repository; this folder keeps its
> own copies (the master project keeps its own too) so the slave project is
> self-contained and the two ends stay independent. The two genuinely new
> blocks were promoted the same way `clock_div` was, each in its own
> repository-level IP folder with its own testbench:
>
> | New IP folder | Module | Testbench |
> |---|---|---|
> | `Start_Stop_Detect/` | `start_stop_detect.vhd` | `sim_start_stop_detect/start_stop_detect_tb.vhd` |
> | `Scl_Stretch/` | `scl_stretch.vhd` | `sim_scl_stretch/scl_stretch_tb.vhd` |

### 2.1 Source files

All eight RTL files are registered in `I2C_Slave.qsf`:

| File | Content |
|---|---|
| `I2C_Slave.vhd` | `I2C_Slave` — transaction FSM + drivers + host handshakes |
| `sync_2ff.vhd` | `sync_2ff` (copy of the reusable IP) |
| `start_stop_detect.vhd` | `start_stop_detect` (copy of the new IP) |
| `scl_stretch.vhd` | `scl_stretch` (copy of the new IP) |
| `I2C_TX.vhd` | `I2C_TX` (instantiates the P2S) |
| `I2C_RX.vhd` | `I2C_RX` (instantiates the S2P) |
| `parallel_to_serial.vhd` | `parallel_to_serial` (P2S, MSB-first capable) |
| `serial_to_parallel.vhd` | `serial_to_parallel` (S2P, MSB-first capable) |

### 2.2 Simulation folders (one project = one DUT = one TB)

| Folder | Testbench | Scope |
|---|---|---|
| `sim_i2c_slave/` | `i2c_slave_tb.vhd` | Standalone slave against a scripted open-drain master BFM: write / read / foreign address / repeated START, exact clock-stretch accounting (swept: `G_STRETCH_CYCLES` = 500 and 0) |
| `sim_i2c_slave/` | `i2c_slave_master_tb.vhd` | Integration with the **real `I2C_Master`** on one bus: write 2 bytes, write pointer + Sr + read 2 bytes, foreign address; stretching enabled |

Both testbenches are simulation-only and are **not** registered in
`I2C_Slave.qsf`.

### 2.3 Board DUT sub-project — `../I2C_Slave_DUT/`

Separate Quartus project (`../I2C_Slave_DUT/I2C_Slave_DUT.qsf`, same device
`EP4CE6E22C8`, `TOP_LEVEL_ENTITY = I2C_Slave_DUT`) that puts the target on the
bench: the FPGA plays the slave, the controller is **external** and only the two
bus wires (plus `clk`/`rst_n`) leave the device.

| File | Content |
|---|---|
| `I2C_Slave_DUT.vhd` | Top-level wrapper: 4-pin interface (`clk`, `rst_n`, `sda`, `scl`) + dialogue FSM — `0xAA` written by the master arms the reply, the next read answers `0xEE`, reads before the command answer `0x00`, and the reply is re-armed once the frame closes |
| `I2C_Slave.vhd`, `sync_2ff.vhd`, `start_stop_detect.vhd`, `scl_stretch.vhd`, `I2C_TX.vhd`, `I2C_RX.vhd`, `parallel_to_serial.vhd`, `serial_to_parallel.vhd` | byte-identical copies, so the DUT project builds on its own (the originals in this folder are untouched) |
| `sim_build/` | `slave_dut_idle_tb.vhd` + `slave_dut_sequence_tb.vhd` (simulation-only files, **not** registered in the DUT `.qsf`) |

Both DUT testbenches use the wrapper through its 4 pins only — no hierarchical
access to DUT internals — with the real `I2C_Master` (`../I2C_Master/`) as the
external controller on the shared bus.

---

## 3. Top-Level — `I2C_Slave`

### 3.1 External interface (as implemented)

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | System clock |
| `rst_n` | in | 1 | Reset, active-low (synchronous inside the block) |
| `data_to_transmit[7:0]` | in | 8 | Next byte the master will read — sampled per byte on the handover; update it on each `tx_done` pulse |
| `data_received[7:0]` | out | 8 | Last complete byte written by the master (registered; held until the next one) |
| `rx_valid` | out | 1 | 1-clk pulse: `data_received` was updated |
| `tx_done` | out | 1 | 1-clk pulse: a read byte was fully serialized (safe moment to present the next one) |
| `busy` | out | 1 | `'1'` while a frame **addressed to this slave** is running (foreign addresses keep it low) |
| `stretch_active` | out | 1 | `'1'` while the slave is holding SCL low (clock stretching in progress) |
| `sda` | inout | 1 | I2C data line (open-drain, external pull-up) |
| `scl` | inout | 1 | I2C clock line (open-drain, external pull-up) |

Generics:

| Generic | Default | Meaning |
|---|---|---|
| `G_SLAVE_ADDR` | `"0111100"` (0x3C) | 7-bit address the slave answers; anything else is NACKed |
| `G_CLK_FREQ` | 50_000_000 | System clock [Hz] |
| `G_I2C_FREQ` | 100_000 | SCL bus clock [Hz] — used only for the oversampling check |
| `G_STRETCH_CYCLES` | 500 | SCL low hold per ACK cell, in `clk` cycles (`0` = feature compiled out) |

Parameter constraints (asserted at elaboration): `G_I2C_FREQ > 0` and
`G_CLK_FREQ ≥ 16 × G_I2C_FREQ` — the FSM must observe every bus level between
two SCL edges (2-FF synchroniser + edge detector + registered output stage).

### 3.2 Host contract

- **Writes:** consume each byte on an `rx_valid` pulse. `data_received` is
  registered together with the pulse, so it always selects that byte. Bytes
  keep arriving until the frame ends; if the host is slower than the bus it
  must clock-stretch *upstream* (this block does not back-pressure the wire).
- **Reads:** present the first byte on `data_to_transmit` before the address
  ACK cell completes; each following byte on the corresponding `tx_done`
  pulse (one SCL bit cell of headroom). After a NACK the slave stops sending —
  update `data_to_transmit` only while `busy` is high.
- **Status:** `busy` gates the whole addressed frame (it stays high across a
  repeated START, because the bus never goes idle); `stretch_active` mirrors
  the internal SCL hold.
- `data_to_transmit` must be **synchronous to `clk`**. Nothing beyond the raw
  byte stream is interpreted, so a register file, FIFO or CPU-bus bridge can
  sit on top unchanged.

---

## 4. Transaction FSM — `I2C_Slave`

### 4.1 Transaction FSM (9 states)

```
                 START / Sr detected            byte_done (8 bits in)
        ┌──────────────────────────────────┐  ┌────────────────────────┐
        ▼                                  ▼  ▼                        │
IDLE ─► ADDR ─ falling edge ─► ACKA ─ SDA low + STRETCH ─┬─ ACK  ───────┤
 ▲       ▲                                            └─ NACK ─► IDLE   │
 │       └── start_det (Sr, from any state) ◄───────────────────────    │
 │                                                                       │
 │  W = '0': DATA_W ⇄ ACKW (write bytes, each ACK cell stretched) ──────┘
 │           STOP → IDLE
 └── R = '1': DATA_R → ACKR ─ ACK → DATA_R (next byte)
                           └─ NACK → IDLE (frame over)
```

| State | Role |
|---|---|
| `IDLE` | Both lines released; waits for a START (SDA falls while SCL high) |
| `ADDR` | `I2C_RX` de-serialises the address byte on SCL rising edges; a `start_det` here is a repeated START → restart the address phase; a `stop_det` goes back to `IDLE` |
| `ACKA_OPEN` | Waits for the SCL **falling** edge that opens the address ACK cell |
| `ACKA` | Address ACK cell: SDA pulled low (only if the address matched — otherwise released = NACK), SCL stretched for `G_STRETCH_CYCLES`; on the closing edge branches to `DATA_W` (`W`) or `DATA_R` (`R`) |
| `DATA_W` | `I2C_RX` de-serialises one written byte (paced on SCL rising edges); `start_det` → back to `ADDR` (Sr abort), `stop_det` → `IDLE` |
| `ACKW_OPEN` | Waits for the falling edge that opens the write-byte ACK cell |
| `ACKW` | Write-byte ACK cell: SDA low, SCL stretched; next `DATA_W` or `IDLE` on STOP |
| `DATA_R` | `I2C_TX` shifts the read byte out, one bit per SCL falling edge; `start_det` releases the line and re-enters `ADDR` (Sr mid-read) |
| `ACKR` | Master's ACK cell after a read byte: SDA released, SCL stretched, ACK/NACK **sampled while SCL is high**; ACK → next `DATA_R`, NACK → `IDLE` |

The `*_OPEN` companion states (see §1.3) are what guarantees the stretch pulse
is issued exactly once per cell, on the falling edge that opens it — never
mid-high-phase.

### 4.2 Where stretching happens

Every ACK cell the slave takes part in — `ACKA`, `ACKW` and `ACKR` — starts by
pulsing `stretch_req`, so SCL is held low for `G_STRETCH_CYCLES` `clk` cycles
*in the low phase*, before the master's next rising edge can arrive. Because
the FSM resumes only on **real bus edges**, a master that ignores stretching
simply waits (its own SCL generator cannot end the phase early — the slave
holds the wire down, and `scl_low` only ever pulls low, never fights up).

### 4.3 The repeated START path

`start_stop_detect` runs **concurrently** with the byte states, so a START
condition in the middle of a frame (SDA falls while SCL is high — impossible
during normal data traffic) is caught in `ADDR`, `DATA_W` or `DATA_R`. The FSM
releases SDA, re-arms `I2C_RX` and re-enters `ADDR` without ever passing
through `IDLE`: `busy` stays high, no STOP is generated, and the R/W bit of
the new address byte flips the direction — the *write-register-pointer, Sr,
read-back* idiom in a single frame.

---

## 5. Byte Paths — `I2C_TX` / `I2C_RX`

The byte paths are the same reusable blocks the master uses, copied verbatim
into this folder (see §2 reuse note): `I2C_RX` samples on SCL **rising** edges
(data valid while SCL is high), `I2C_TX` updates on SCL **falling** edges, both
MSB-first over 8 bits via `serial_to_parallel` / `parallel_to_serial`, and both
expose a single `byte_done` per byte. The FSM only arms them (`receive` /
`send`) and waits for the flag — it never counts bits itself. Full interface
details in the master document, §5.

---

## 6. Signal Integrity and the Open-Drain Discipline

- **Never drive `'1'`.** The output mux assigns only `'0'` (pull low) or `'1'`
  (which, on an `inout` open-drain pin with an external pull-up, is the
  release value the master also uses). Two agents can therefore never source
  current into each other — the electrical precondition for both clock
  stretching and multi-controller buses.
- **Registered mux, decoded from the current state** (same pattern as the
  master): every SDA transition is uniformly delayed one `clk`, bit cells keep
  their width, and no combinational glitch can reach the wire.
- **Input path discipline:** raw pin → `sync_2ff` (the only asynchronous
  elements) → `To_X01` normalisation (`'H'` becomes `'1'`) → registered level
  + one delayed copy. Every downstream comparison, shift and edge detect reads
  the normalised registered level; `scl_fall` is derived from registered
  levels only, so it is glitch-free by construction.

---

## 7. Design decisions

| # | Decision | Status |
|---|---|---|
| 1 | The FSM is timed on **real bus edges** (SCL falling opens cells, SCL rising is sampled/byte-paced), never on a local divider — this is what makes slave-side stretching legal by construction | ✅ |
| 2 | One FSM owns all bus framing (START/Sr/STOP, ACK cells, direction); `I2C_TX`/`I2C_RX` own only the bit pacing of one byte | ✅ |
| 3 | Open-drain discipline: `'0'` or release only, single registered SDA mux decoded from the current state | ✅ |
| 4 | Asynchronous inputs enter only through `sync_2ff` + `To_X01`; all edge logic works on registered levels | ✅ |
| 5 | START/Sr/STOP detection isolated in its own IP (`start_stop_detect`), fed with synchronised levels, so framing survives any state | ✅ |
| 6 | Stretching isolated in `scl_stretch`: one-clk request pulse, pull-down only, `G_STRETCH_CYCLES = 0` compiles the feature out | ✅ |
| 7 | `*_OPEN` states split "wait for the cell-opening falling edge" from the cell itself — exactly one stretch per cell, never mid-high-phase | ✅ |
| 8 | Address filtering with clean NACK + ignore-until-next-START (no partial-state confusion on foreign traffic) | ✅ |
| 9 | Master ACK/NACK in `ACKR` sampled **while SCL is high** (level-gated), so a slow master is caught; NACK terminates the frame in `IDLE` | ✅ |
| 10 | Byte-stream host interface (`rx_valid` / `tx_done` pulses, `busy` / `stretch_active` status) — no interpretation above the wire, bridges compose freely | ✅ |
| 11 | Reusable components **copied** into the subfolder (originals untouched) so the slave project is self-contained; new blocks promoted to their own IP folders like `Clock_Div` | ✅ |
| 12 | Language: VHDL (sim projects run with ModelSim `-2008`; the RTL itself is 93/2002-compatible style) | ✅ |

---

## 8. Verification

| TB | Folder | Scope | Status |
|---|---|---|---|
| `i2c_slave_tb` (`G_STRETCH_CYCLES = 500`) | `sim_i2c_slave/` | Scripted open-drain master BFM: write frame, read frame, foreign address (NACK + ignore), repeated-START write→read; exact clock-stretch accounting on every ACK cell | ✅ PASS |
| `i2c_slave_tb` (`G_STRETCH_CYCLES = 0`) | `sim_i2c_slave/` | Same suite with the feature compiled out — proves the `0` path and that no stretch logic interferes | ✅ PASS |
| `i2c_slave_master_tb` | `sim_i2c_slave/` | Integration with the **real `I2C_Master`** on one shared bus: write 2 bytes, write-pointer → Sr → read 2 bytes, foreign address; stretching enabled end-to-end | ✅ PASS |
| `slave_dut_sequence_tb` | `../I2C_Slave_DUT/sim_build/` | Board DUT (`I2C_Slave_DUT`, 4 pins) with the real `I2C_Master` as the **external** controller: read before the command → `0x00`, write `0xAA` → read `0xEE`, one-shot reply, `0xAA` + Sr + read 2 → `0xEE`,`0xEE`, foreign address ignored, dialogue repeats; per-frame stretch accounting measured from the bus (19 holds = every ACK cell the DUT took part in, 0 on the foreign frame) | ✅ PASS |
| `slave_dut_idle_tb` | `../I2C_Slave_DUT/sim_build/` | Power-up / idle guard: with nobody addressing it the DUT never drives `sda`/`scl` — also through reset and a mid-run reset pulse | ✅ PASS |

Run notes:

- Head-less flow from inside `sim_i2c_slave/`: `vsim -c -do sim_run.do` —
  compiles the RTL from the parent folder plus `../../I2C_Master/I2C_Master.vhd` for the
  integration TB, runs all three configurations, prints the PASS/FAIL verdict
  and exits with a proper code (`onerror {quit -code 1}`).
- All assertions are self-checking (frame contents, `rx_valid`/`tx_done`
  timing, measured stretch length in `clk` cycles, bus idle after STOP).
- **Re-verified live on 2026-09-22:** all three runs green — 0 errors,
  0 warnings each (`I2C slave frames and clock stretching verified` ×2,
  `I2C_Master + I2C_Slave link verified (stretching + Sr)`).
- The two component testbenches for the new IPs are green too:
  `Start_Stop_Detect/sim_start_stop_detect` and `Scl_Stretch/sim_scl_stretch`
  (`vsim -c -do sim_run.do` each).
- DUT suite from inside `../I2C_Slave_DUT/sim_build/`: `vsim -c -do sim_run.do`
  (both DUT TBs in one session), or `idle_run.do` / `sequence_run.do`
  individually. Those TBs reach the wrapper through its **4 pins only** and use
  the real `I2C_Master` (`../../I2C_Master/`) as the external controller, so they
  reproduce exactly what a bench controller puts on the bus. The stretch
  measurement there is made on SCL: a low phase longer than 400 `clk` is one ACK
  cell the DUT stretched (250 `clk` plain vs ~506 `clk` stretched; the ~500 `clk`
  START phase is detected separately and excluded).
- **Re-verified live on 2026-09-24:** DUT suite green — 0 errors, 0 warnings
  each (`4-pin I2C_Slave_DUT releases both lines and never drives an
  un-addressed bus`, `I2C_Slave_DUT dialogue verified on the bus (0xAA written,
  0xEE read back)`), with 19 stretch holds counted = every ACK cell the DUT took
  part in and none on the foreign frame.

**Quartus Analysis & Elaboration:** clean for `I2C_Slave.qsf` (all 8 files,
top-level `I2C_Slave`, device EP4CE6E22C8) — **0 errors, 0 warnings**. Same for
the DUT project (`../I2C_Slave_DUT/I2C_Slave_DUT.qsf`, 9 files, top-level
`I2C_Slave_DUT`, same device and pin-out as `I2C_DUT`) — **0 errors,
0 warnings**, re-run live on 2026-09-24.

---

## 9. Roadmap

- **Register-map / FIFO layer** above the byte-stream host interface (the
  intended consumer of the repeated-START register-pointer idiom).
- **SDC constraints**: `set_false_path` SDA/SCL → first sync FFs,
  `set_output_delay` on the open-drain pins; then Fitter + timing sign-off.
- **Board wrapper** (`I2C_DUT`-style) — **done**, see §2.3
  (`../I2C_Slave_DUT/`, 4-pin interface + `0xAA`/`0xEE` dialogue, DUT TBs green).
  Still open on that path: an **on-chip register file** (or small FIFO) in the
  wrapper, so the byte stream becomes an addressable register map — the intended
  consumer of the repeated-START register-pointer idiom — plus SDC constraints
  for the board-level build.
- **Fast-mode (400 kHz)**: relax the oversampling assert accordingly and
  re-check the ACK-cell stretch budget.
- **General call / 10-bit addressing** if a target device needs it.

---

## 10. Changelog

- **2026-09-24** — **Board DUT sub-project `../I2C_Slave_DUT/`**: 4-pin
  top-level wrapper (`I2C_Slave_DUT`) on top of the slave with an on-chip
  dialogue FSM — an external master writes the `0xAA` command and reads `0xEE`
  back (`0x00` before the command, the reply is re-armed after each frame); own
  Quartus project (`.qpf`/`.qsf`, same device and pin-out as `I2C_DUT`, all 8
  slave files copied in) and `sim_build/` with `slave_dut_idle_tb` +
  `slave_dut_sequence_tb` (the real `I2C_Master` as the **external** controller,
  black box through the 4 pins, per-frame clock-stretch accounting) — 2/2 green,
  0 errors / 0 warnings.
- **2026-09-22** — Initial release: `I2C_Slave` FSM (9 states) with address
  filtering, clock stretching (`scl_stretch`) and repeated START
  (`start_stop_detect`); copied reuse of `sync_2ff`/`I2C_TX`/`I2C_RX`/
  converters; two new IP folders with testbenches; 3/3 TB suite green;
  Quartus A&E 0 errors / 0 warnings.




