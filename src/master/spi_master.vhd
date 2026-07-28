--------------------------------------------------------------------------------
--! @title SPI master implementation in VHDL
--! @file spi_master.vhd
--! @author Roi (r.lopezbarata@gmail.com)
--! @version 1.0
--! @date 28-07-2026
--! @copyright This work is licensed under the MIT License.
--! @brief Implementation of an SPI master module in VHDL.
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

--! This is an implementation of an SPI master module. It handles the transmission
--! and reception of data through the SPI interface, managing the clock signal,
--! chip select, and data lines (MOSI and MISO). The module supports different SPI
--! modes based on the clock polarity (CPOL) and clock phase (CPHA) settings. It
--! also provides the ability to load data into tx and rx buffers, allowing for
--! flexible data handling during SPI communication.
entity spi_master is

    generic (
        bits_per_message   : integer := 8; --! Bits exchanged in each SPI transmission.
        sclk_divider_value : integer := 4 --! Clock divider value to generate the SPI clock (sclk) from the module's clock (clk).
    );

    port (

        -- Main ports.
        rst                : in std_logic; --! Synchronous reset to initialize the SPI master module.
        clk                : in std_logic; --! Internal clock signal for the SPI master module.
        sclk               : out std_logic := '0'; --! SPI clock output signal, generated based on the clk input and sclk_divider_value.
        cpol               : in std_logic; --! Clock polarity setting for the SPI communication (0 or 1).
        cpha               : in std_logic; --! Clock phase setting for the SPI communication (0 or 1).
        start_transmission : in std_logic; --! Signal to initiate an SPI transmission.
        cs                 : out std_logic := '1'; --! Chip select signal.
        mosi               : out std_logic := '0'; --! Master Out Slave In signal.
        miso               : in std_logic; --! Master In Slave Out signal.

        -- Transmit buffer ports.
        tx_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0); --! Transmission buffer input.
        tx_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0); --! Transmission buffer output.
        tx_buffer_load   : in std_logic; --! Signal to load data into the transmission buffer.

        -- Receive buffer ports.
        rx_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0); --! Reception buffer input.
        rx_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0); --! Reception buffer output.
        rx_buffer_load   : in std_logic --! Signal to load data into the reception buffer.
    );

end entity spi_master;

architecture beh of spi_master is
    type state_t is (
        IDLE, --! Idle state (no active transmission -> CS = 1).
        TRANSMIT, --! Transmission state (active transmission -> CS = 0).
        FINISH_TRANSMISSION --! Finish transmission state (finished the transmission -> CS = 1).
    );
    signal state                 : state_t; --! Current state of the SPI master state machine.
    signal last_shift_bit        : std_logic                                       := '0'; --! Flag to indicate if the last bit of the current transmission has been processed.
    signal sclk_rising_edge      : std_logic                                       := '0'; --! Rising edge of SPI clock (sclk).
    signal sclk_falling_edge     : std_logic                                       := '0'; --! Falling edge of SPI clock (sclk).
    signal tx_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0'); --! Data output from the transmission buffer.
    signal rx_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0'); --! Data output from the reception buffer.
begin

    tx_buffer_output <= tx_buffer_output_data;
    rx_buffer_output <= rx_buffer_output_data;

    --! Implements the SPI master state machine, generating SCLK, controlling CS
    --! and shifting data between the tx/rx buffers and the SPI data lines according
    --! to the selected CPOL/CPHA configuration.
    fsm_proc : process (clk)
        variable divider                : integer := 0;
        variable current_bits_processed : integer := 0;

    begin

        if rising_edge(clk) then

            -- Reset all output buffers and signals/variables and return the
            -- master to idle state.
            if rst = '1' then
                rx_buffer_output_data <= (others => '0');
                tx_buffer_output_data <= (others => '0');
                state                 <= IDLE;
                divider                := sclk_divider_value;
                current_bits_processed := 0;
                mosi <= '0';

            else
                case state is

                    when IDLE =>
                        -- Idle state: deselect the slave, hold SCLK at the idle
                        -- polarity, and allow new buffer data to be loaded.
                        cs                <= '1';
                        sclk              <= cpol;
                        mosi              <= '0';
                        sclk_rising_edge  <= '0';
                        sclk_falling_edge <= '0';
                        current_bits_processed := 0;
                        last_shift_bit <= '0';

                        if cpol = '0' then
                            divider := 2;
                        elsif cpol = '1' then
                            divider := 0;
                        end if;

                        -- Allow loading values into the rx and tx registers while in the
                        -- Idle state.
                        if rx_buffer_load = '1' then
                            rx_buffer_output_data <= rx_buffer_input;
                        end if;
                        if tx_buffer_load = '1' then
                            tx_buffer_output_data <= tx_buffer_input;
                        end if;

                        if start_transmission = '1' then
                            state <= TRANSMIT;
                        end if;

                    when TRANSMIT =>
                        -- Transmit state: assert CS low and generate the SPI clock
                        -- edges while shifting data in and out.
                        cs <= '0';

                        -- Generate rising and falling edges of the SCLK.
                        if divider = sclk_divider_value - 1 then
                            divider := 0;
                            sclk_rising_edge <= '1';
                        else
                            divider := divider + 1;
                            if divider = (sclk_divider_value / 2) then
                                sclk_falling_edge <= '1';
                            else
                                sclk_rising_edge  <= '0';
                                sclk_falling_edge <= '0';
                            end if;
                        end if;

                        if sclk_rising_edge = '1' and last_shift_bit = '0' then
                            sclk <= '1';
                            mosi <= tx_buffer_output_data(0);

                            if cpol = '0' then
                                if cpha = '0' then -- SPI mode 0
                                    -- In mode 0, capture MISO on the rising edge and shift
                                    -- the transmit register at the same time.
                                    tx_buffer_output_data <= '0' & tx_buffer_output_data(bits_per_message - 1 downto 1);
                                    rx_buffer_output_data <= miso & rx_buffer_output_data(bits_per_message - 1 downto 1);

                                elsif cpha = '1' then -- SPI mode 1
                                    -- In mode 1, output the first transmit bit on the rising edge
                                    -- and defer sampling until the falling edge.
                                    mosi <= tx_buffer_output_data(0);
                                end if;

                            elsif cpol = '1' then
                                if cpha = '0' then -- SPI mode 2
                                    -- Mode 2 uses an inverted idle clock polarity; rising edge
                                    -- only advances the bit counter here.
                                    current_bits_processed := current_bits_processed + 1;

                                elsif cpha = '1' then -- SPI mode 3
                                    -- In mode 3, sample MISO and shift transmit data on the
                                    -- rising edge while also counting the bit.
                                    tx_buffer_output_data <= '0' & tx_buffer_output_data(bits_per_message - 1 downto 1);
                                    rx_buffer_output_data <= miso & rx_buffer_output_data(bits_per_message - 1 downto 1);
                                    current_bits_processed := current_bits_processed + 1;
                                end if;

                            end if;

                        elsif sclk_falling_edge = '1' and last_shift_bit = '0' then
                            sclk <= '0';
                            mosi <= tx_buffer_output_data(0);

                            if cpol = '0' then
                                if cpha = '0' then -- SPI mode 0
                                    -- In mode 0, shift the next transmit bit on the falling edge.
                                    mosi <= tx_buffer_output_data(0);
                                    current_bits_processed := current_bits_processed + 1;

                                elsif cpha = '1' then -- SPI mode 1
                                    -- In mode 1, sample MISO on the falling edge and advance the
                                    -- bit counter after the initial output.
                                    tx_buffer_output_data <= '0' & tx_buffer_output_data(bits_per_message - 1 downto 1);
                                    rx_buffer_output_data <= miso & rx_buffer_output_data(bits_per_message - 1 downto 1);
                                    current_bits_processed := current_bits_processed + 1;
                                end if;

                            elsif cpol = '1' then
                                if cpha = '0' then -- SPI mode 2
                                    -- For mode 2, sample MISO on the falling edge after the
                                    -- active high clock transition.
                                    tx_buffer_output_data <= '0' & tx_buffer_output_data(bits_per_message - 1 downto 1);
                                    rx_buffer_output_data <= miso & rx_buffer_output_data(bits_per_message - 1 downto 1);

                                elsif cpha = '1' then -- SPI mode 3
                                    -- In mode 3, prepare the next MOSI bit on the falling edge.
                                    mosi <= tx_buffer_output_data(0);
                                end if;
                            end if;

                        end if;

                        if current_bits_processed = bits_per_message then
                            last_shift_bit <= '1';
                        end if;

                        -- Move to the finish transmission state when the last bit is sent/received.
                        if last_shift_bit = '1' and (sclk_rising_edge = '1' or sclk_falling_edge = '1') then
                            state <= FINISH_TRANSMISSION;
                        end if;

                    when FINISH_TRANSMISSION =>
                        -- Finish state: release CS, restore idle clock polarity, and
                        -- return to the IDLE state so the next transfer can begin.
                        cs                <= '1';
                        sclk              <= cpol;
                        sclk_rising_edge  <= '0';
                        sclk_falling_edge <= '0';
                        state             <= IDLE;
                end case;

            end if;
        end if;

    end process fsm_proc;

end architecture beh;
