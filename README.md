# AF-FPGA-OpenIP
An open library of modular FPGA IP blocks for fast, reliable and scalable hardware design.

## Repository Structure

```
AF-FPGA-OpenIP/
├── README.md                    ← you are here
├── UART/                        — Full-duplex UART (8N1), structural wrapper
│   ├── UART.vhd
│   ├── UART_TX.vhd
│   ├── UART_RX.vhd
│   ├── ARCHITECTURE.md          — detailed design document
│   ├── sim_uart/                — top-level testbench
│   ├── sim_uart_tx/             — TX-only testbench
│   ├── sim_uart_rx/             — RX-only testbench
│   └── ...
├── baudrate_gen/                — Reusable Baud Rate Generator
│   ├── baudrate_gen.vhd
│   ├── baudrate_gen_tb.vhd
│   └── README.md
├── parallel_to_serial/          — Reusable Parallel-to-Serial Converter
│   ├── parallel_to_serial.vhd
│   ├── parallel_to_serial_tb.vhd
│   └── README.md
└── serial_to_parallel/          — Reusable Serial-to-Parallel Converter
    ├── serial_to_parallel.vhd
    ├── serial_to_parallel_tb.vhd
    └── README.md
```

## IP Modules

### Standalone Reusable Modules

These modules are project-independent and can be used in any FPGA design:

| Module | Folder | Description |
|--------|--------|-------------|
| Baudrate Generator | [`baudrate_gen/`](baudrate_gen/) | Clock divider producing single-cycle baud ticks. Supports phase offset for mid-bit sampling. |
| Parallel-to-Serial | [`parallel_to_serial/`](parallel_to_serial/) | 8-bit load/shift register, LSB-first serial output. |
| Serial-to-Parallel | [`serial_to_parallel/`](serial_to_parallel/) | 8-bit shift register, LSB-first parallel output. |

### Integrated IP Blocks

These are higher-level designs that instantiate the reusable modules:

| Block | Folder | Description |
|-------|--------|-------------|
| UART | [`UART/`](UART/) | Full-duplex UART (8N1) with TX and RX channels. Uses `baudrate_gen`, `parallel_to_serial`, and `serial_to_parallel` internally. |

## Getting Started

Each module folder contains its own README with:
- Architecture overview
- Interface description (generics and ports)
- Usage example
- Testbench documentation
- File listing

Navigate to any module folder and open its README for details.

## Target Device

- **FPGA**: Intel Cyclone IV E EP4CE6E22C8
- **Tool**: Quartus Prime 20.1.0 Lite
- **Simulator**: ModelSim (VHDL-93/2002 compatible)

## License

Open source — use freely in your projects.
