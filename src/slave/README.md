
# Entity: spi_slave
- **File**: spi_slave.vhd
- **Title:**  SPI slave implementation in VHDL
- **File:**  spi_slave.vhd
- **Author:**  Roi (r.lopezbarata@gmail.com)
- **Version:**  1.0
- **Date:**  28-07-2026
- **Copyright:**  This work is licensed under the MIT License.
- **Brief:**  Implementation of an SPI slave module in VHDL.

## Diagram
![Diagram](spi_slave.svg "Diagram")
## Description

This is an implementation of an SPI slave module in VHDL. It supports
configurable bits per message and handles SPI communication based on clock
polarity (CPOL) and phase (CPHA) settings. The module includes transmit and
receive buffers for data exchange with the master device.

## Generics

| Generic name     | Type    | Value | Description                              |
| ---------------- | ------- | ----- | ---------------------------------------- |
| bits_per_message | integer | 8     | Bits exchanged in each SPI transmission. |

## Ports

| Port name        | Direction | Type                                            | Description                                                |
| ---------------- | --------- | ----------------------------------------------- | ---------------------------------------------------------- |
| rst              | in        | std_logic                                       | Synchronous reset to initialize the SPI slave module.      |
| clk              | in        | std_logic                                       | Internal clock signal for the SPI slave module.            |
| sclk             | in        | std_logic                                       | SPI clock signal.                                          |
| cpol             | in        | std_logic                                       | Clock polarity setting for the SPI communication (0 or 1). |
| cpha             | in        | std_logic                                       | Clock phase setting for the SPI communication (0 or 1).    |
| cs               | in        | std_logic                                       | Chip select signal.                                        |
| mosi             | in        | std_logic                                       | Master Out Slave In signal.                                |
| miso             | out       | std_logic                                       | Master In Slave Out signal.                                |
| tx_buffer_input  | in        | std_logic_vector(bits_per_message - 1 downto 0) | Transmit buffer input.                                     |
| tx_buffer_output | out       | std_logic_vector(bits_per_message - 1 downto 0) | Transmit buffer output.                                    |
| tx_buffer_load   | in        | std_logic                                       | Signal to load data into the transmit buffer.              |
| rx_buffer_input  | in        | std_logic_vector(bits_per_message - 1 downto 0) | Receive buffer input.                                      |
| rx_buffer_output | out       | std_logic_vector(bits_per_message - 1 downto 0) | Receive buffer output.                                     |
| rx_buffer_load   | in        | std_logic                                       | Signal to load data into the receive buffer.               |

## Signals

| Name                  | Type                                            | Description                                                    |
| --------------------- | ----------------------------------------------- | -------------------------------------------------------------- |
| entered_idle_flag     | std_logic                                       | Flag to indicate whether the slave has entered the idle state. |
| aux_rx_shift_reg      | std_logic_vector(bits_per_message - 1 downto 0) | Auxiliary shift register for receiving data.                   |
| tx_buffer_output_data | std_logic_vector(bits_per_message - 1 downto 0) | Data output from the transmit buffer.                          |
| rx_buffer_output_data | std_logic_vector(bits_per_message - 1 downto 0) | Data output from the receive buffer.                           |

## Processes
- internal_proc: ( clk )
  - **Description**
  Handles buffer load control and end-of-transfer behavior. It runs on the local clock and updates the transmit/receive outputs when the slave is idle and when buffer load signals are asserted. It also handles the buffer and idle flag updates on reset.
- communication_proc: ( sclk, cs )
  - **Description**
  Implements SPI data sampling and shifting based on clock polarity (CPOL) and phase (CPHA). It updates the MISO output and the receive shift register on the appropriate SCLK edge.
