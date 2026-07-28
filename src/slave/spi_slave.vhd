--------------------------------------------------------------------------------
--! @title SPI slave implementation in VHDL
--! @file spi_slave.vhd
--! @author Roi (r.lopezbarata@gmail.com)
--! @version 1.0
--! @date 28-07-2026
--! @copyright This work is licensed under the MIT License.
--! @brief Implementation of an SPI slave module in VHDL.
--------------------------------------------------------------------------------

-- MIT License

-- Copyright (c) 2026 Roi Lopez Barata

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! This is an implementation of an SPI slave module in VHDL. It supports
--! configurable bits per message and handles SPI communication based on clock
--! polarity (CPOL) and phase (CPHA) settings. The module includes transmit and
--! receive buffers for data exchange with the master device.
entity spi_slave is

    generic (
        bits_per_message : integer := 8 --! Bits exchanged in each SPI transmission.
    );

    port (

        -- Main ports.
        rst  : in std_logic; --! Synchronous reset to initialize the SPI slave module.
        clk  : in std_logic; --! Internal clock signal for the SPI slave module.
        sclk : in std_logic; --! SPI clock signal.
        cpol : in std_logic; --! Clock polarity setting for the SPI communication (0 or 1).
        cpha : in std_logic; --! Clock phase setting for the SPI communication (0 or 1).
        cs   : in std_logic; --! Chip select signal.
        mosi : in std_logic; --! Master Out Slave In signal.
        miso : out std_logic := '0'; --! Master In Slave Out signal.

        -- Transmit buffer ports.
        tx_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0); --! Transmission buffer input.
        tx_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0); --! Transmission buffer output.
        tx_buffer_load   : in std_logic; --! Signal to load data into the transmission buffer.

        -- Receive buffer ports.
        rx_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0); --! Reception buffer input.
        rx_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0); --! Reception buffer output.
        rx_buffer_load   : in std_logic --! Signal to load data into the reception buffer.
    );

end entity spi_slave;

architecture beh of spi_slave is
    signal entered_idle_flag     : std_logic                                       := '1'; --! Flag to indicate whether the slave has entered the idle state.
    signal aux_rx_shift_reg      : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0'); --! Auxiliary shift register for receiving data.
    signal tx_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0'); --! Data output from the transmission buffer.
    signal rx_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0'); --! Data output from the reception buffer.
begin

    tx_buffer_output <= tx_buffer_output_data;
    rx_buffer_output <= rx_buffer_output_data;

    --! Handles buffer load control and end-of-transfer behavior. It runs on the
    --! local clock and updates the transmit/receive outputs when the slave is
    --! idle and when buffer load signals are asserted. It also handles the buffer
    --! and idle flag updates on reset.
    internal_proc : process (clk)
    begin

        if rising_edge(clk) then
            if rst = '1' then
                -- Reset all output buffers and return the slave to idle state.
                rx_buffer_output_data <= (others => '0');
                tx_buffer_output_data <= (others => '0');
                entered_idle_flag     <= '1';

            elsif cs = '1' then
                -- Slave is deselected: transfer has ended. Capture the received
                -- word once per transfer and allow buffer updates.
                if entered_idle_flag = '0' then
                    rx_buffer_output_data <= aux_rx_shift_reg;
                    entered_idle_flag     <= '1';
                end if;
                if rx_buffer_load = '1' then
                    rx_buffer_output_data <= rx_buffer_input;
                end if;
                if tx_buffer_load = '1' then
                    tx_buffer_output_data <= tx_buffer_input;
                end if;

            elsif cs = '0' then
                -- Slave is selected and active: mark that a transfer is in progress.
                entered_idle_flag <= '0';
            end if;

        end if;
    end process internal_proc;

    --! Implements SPI data sampling and shifting based on clock polarity (CPOL)
    --! and phase (CPHA). It updates the MISO output and the receive shift register
    --! on the appropriate SCLK edge.
    communication_proc : process (sclk, cs)
        variable bit_count : natural := 0;

    begin

        if cs = '0' and bit_count = 0 then
            -- Drive the first bit as soon as the transfer starts.
            miso <= tx_buffer_output_data(0);
        end if;

        if cs = '1' then
            -- Deselected slave: put MISO in high-impedance state and keep the
            -- next transfer ready by resetting the bit counter.
            miso <= 'Z';
            bit_count := 0;
        end if;

        if rising_edge(sclk) then
            if cs = '0' then
                -- Data is shifted and sampled on the active clock edge
                -- depending on CPOL/CPHA mode selection.
                if cpol = '0' then
                    if cpha = '0' then -- SPI mode 0
                        -- Sample MOSI on the rising edge and shift into the
                        -- receive register immediately.
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;

                    elsif cpha = '1' then -- SPI mode 1
                        -- Output the next transmit bit on the first rising edge.
                        miso <= tx_buffer_output_data(bit_count);
                    end if;

                elsif cpol = '1' then
                    if cpha = '0' then -- SPI mode 2
                        -- Inverted clock mode: output the transmit bit while
                        -- sampling still occurs on the opposite edge.
                        if bit_count < bits_per_message then
                            miso <= tx_buffer_output_data(bit_count);
                        end if;

                    elsif cpha = '1' then -- SPI mode 3
                        -- Sample MOSI on the rising edge when CPOL=1, CPHA=1.
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;
                    end if;
                end if;
            end if;

        elsif falling_edge(sclk) then
            if cs = '0' then
                -- The complementary edge for the remaining SPI modes.
                if cpol = '0' then
                    if cpha = '0' then -- SPI mode 0
                        -- Drive the next miso bit after sampling on rising edge.
                        if bit_count < bits_per_message then
                            miso <= tx_buffer_output_data(bit_count);
                        end if;

                    elsif cpha = '1' then -- SPI mode 1
                        -- Sample MOSI on the falling edge in mode 1.
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;
                    end if;

                elsif cpol = '1' then
                    if cpha = '0' then -- SPI mode 2
                        -- Sample MOSI on the falling edge when CPOL=1, CPHA=0.
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;

                    elsif cpha = '1' then -- SPI mode 3
                        -- Output the next transmit bit on the falling edge.
                        miso <= tx_buffer_output_data(bit_count);
                    end if;
                end if;
            end if;
        end if;

    end process communication_proc;

end architecture beh;
