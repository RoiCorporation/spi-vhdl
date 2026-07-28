
# Entity: main_tb
- **File**: main_tb.vhd
- **Title:**  VHDL testbench for SPI master and slave modules
- **File:**  main_tb.vhd
- **Author:**  Roi (r.lopezbarata@gmail.com)
- **Version:**  1.0
- **Date:**  28-07-2026
- **Copyright:**  This work is licensed under the MIT License.
- **Brief:**  Testbench for the SPI master and slave modules developed in this project.

## Description

This is a testbench for the SPI master and slave modules developed in this
project. It tests the functionality of the SPI communication between the
master and slave devices, verifying that data is correctly transmitted and
received according to the specified SPI modes (CPOL and CPHA settings).

## Signals

| Name                    | Type                                            | Description                                                |
| ----------------------- | ----------------------------------------------- | ---------------------------------------------------------- |
| rst                     | std_logic                                       | Synchronous reset to initialize both modules.              |
| clk                     | std_logic                                       | Internal clock signal for both modules.                    |
| sclk                    | std_logic                                       | SPI clock signal.                                          |
| cpol                    | std_logic                                       | Clock polarity setting for the SPI communication (0 or 1). |
| cpha                    | std_logic                                       | Clock phase setting for the SPI communication (0 or 1).    |
| start_transmission      | std_logic                                       | Signal to initiate an SPI transmission.                    |
| cs                      | std_logic                                       | Chip select signal.                                        |
| mosi                    | std_logic                                       | Master Out Slave In signal.                                |
| miso                    | std_logic                                       | Master In Slave Out signal.                                |
| master_tx_buffer_input  | std_logic_vector(bits_per_message - 1 downto 0) | Transmission buffer input for the SPI master module.       |
| master_tx_buffer_output | std_logic_vector(bits_per_message - 1 downto 0) | Transmission buffer output for the SPI master module.      |
| master_tx_buffer_load   | std_logic                                       | Load signal for the SPI master's transmission buffer.      |
| master_rx_buffer_input  | std_logic_vector(bits_per_message - 1 downto 0) | Reception buffer input for the SPI master module.          |
| master_rx_buffer_output | std_logic_vector(bits_per_message - 1 downto 0) | Reception buffer output for the SPI master module.         |
| master_rx_buffer_load   | std_logic                                       | Load signal for the SPI master's reception buffer.         |
| slave_tx_buffer_input   | std_logic_vector(bits_per_message - 1 downto 0) | Transmission buffer input for the SPI slave module.        |
| slave_tx_buffer_output  | std_logic_vector(bits_per_message - 1 downto 0) | Transmission buffer output for the SPI slave module.       |
| slave_tx_buffer_load    | std_logic                                       | Load signal for the SPI slave's transmission buffer.       |
| slave_rx_buffer_input   | std_logic_vector(bits_per_message - 1 downto 0) | Reception buffer input for the SPI slave module.           |
| slave_rx_buffer_output  | std_logic_vector(bits_per_message - 1 downto 0) | Reception buffer output for the SPI slave module.          |
| slave_rx_buffer_load    | std_logic                                       | Load signal for the SPI slave's reception buffer.          |
| slave_rx_shift_reg      | std_logic_vector(bits_per_message - 1 downto 0) |                                                            |

## Constants

| Name             | Type    | Value | Description                                  |
| ---------------- | ------- | ----- | -------------------------------------------- |
| bits_per_message | integer | 8     | Bits exchanged in each SPI transmission.     |
| clk_period       | time    | 6 ns  | Clock period for the testbench clock signal. |

## Processes
- p_clk: (  )
  - **Description**
  Process to generate the clock signal for the testbench. It toggles the clock every half period for a total of 30,000 cycles.
- stim_proc: (  )
  - **Description**
  Process to generate stimulus signals for the testbench and verify the expected behavior of the SPI master and slave modules. It tests various SPI modes and checks that data is correctly transmitted and received.

## Instantiations

- dut_spi_master: work.spi_master
  -  Instance of the SPI master module. It connects the testbench signals to the corresponding ports of the SPI master entity.
- dut_spi_slave: work.spi_slave
  -  Instance of the SPI slave module. It connects the testbench signals to the corresponding ports of the SPI slave entity.
