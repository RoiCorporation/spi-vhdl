--------------------------------------------------------------------------------
-- File : spi_slave.vhd
-- Project : SPI implementation in VHDL
-- Creation : 24-07-2026
-- Limitations : none
-- Errors : none known
-- Simulator : NVC
-- Synthesizer : -
-- Platform : MacOS
-- Targets : Simulation
---------------------------------------
-- Authors : Roi López Barata
-- Organization : -
-- Email : r.lopezbarata@gmail.com
--------------------------------------------------------------------------------
-- Copyright Notice
-- This work is licensed under the MIT License.
--------------------------------------------------------------------------------
-- Function description
--
--------------------------------------------------------------------------------
-- Revision History
-- Date     |       Author      |    Comments
-- 25-07-26 | Roi López Barata  | First unfinished version of the SPI slave module.
-- 27-07-26 | Roi López Barata  | Finished the first complete version of the SPI slave.
-- 28-07-26 | Roi López Barata  | Renamed "outbound_" and "inbound_" signals to
--          |                   | "tx_" and "rx_" respectively.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is

    generic (
        bits_per_message : integer := 8
    );

    port (

        -- Main ports.
        rst            : in std_logic;
        clk            : in std_logic;
        sclk           : in std_logic;
        cpol           : in std_logic;
        cpha           : in std_logic;
        cs             : in std_logic;
        mosi           : in std_logic;
        miso           : out std_logic := '0';
        bit_count_port : out natural;

        -- Transmit buffer ports.
        tx_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0);
        tx_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0);
        tx_buffer_load   : in std_logic;

        -- Receive buffer ports.
        rx_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0);
        rx_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0);
        rx_buffer_load   : in std_logic;
        aux_rx_shift_reg : out std_logic_vector(bits_per_message - 1 downto 0) := (others => '0')
    );

end entity spi_slave;

architecture beh of spi_slave is
    signal entered_idle_flag     : std_logic                                       := '1';
    signal tx_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0) := "10101010";
    signal rx_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0);
begin

    tx_buffer_output <= tx_buffer_output_data;
    rx_buffer_output <= rx_buffer_output_data;

    internal_proc : process (clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then
                rx_buffer_output_data <= (others => '0');
                tx_buffer_output_data <= (others => '0');
                entered_idle_flag     <= '1';

            elsif cs = '1' then
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
                entered_idle_flag <= '0';
            end if;
        end if;
    end process internal_proc;

    communication_proc : process (sclk, cs)
        variable bit_count : natural := 0;
    begin
        bit_count_port <= bit_count;

        if cs = '0' and bit_count = 0 then
            miso <= tx_buffer_output_data(0);
        end if;

        if cs = '1' then
            miso <= '0';
            bit_count := 0;
        end if;

        if rising_edge(sclk) then
            if cs = '0' then
                if cpol = '0' then
                    if cpha = '0' then -- SPI mode 0
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;

                    elsif cpha = '1' then -- SPI mode 1
                        miso <= tx_buffer_output_data(bit_count);
                    end if;

                elsif cpol = '1' then
                    if cpha = '0' then -- SPI mode 2
                        if bit_count < bits_per_message then
                            miso <= tx_buffer_output_data(bit_count);
                        end if;

                    elsif cpha = '1' then -- SPI mode 3
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;
                    end if;
                end if;
            end if;

        elsif falling_edge(sclk) then
            if cs = '0' then
                if cpol = '0' then
                    if cpha = '0' then -- SPI mode 0
                        if bit_count < bits_per_message then
                            miso <= tx_buffer_output_data(bit_count);
                        end if;

                    elsif cpha = '1' then -- SPI mode 1
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;
                    end if;

                elsif cpol = '1' then
                    if cpha = '0' then -- SPI mode 2
                        aux_rx_shift_reg <= mosi & aux_rx_shift_reg(bits_per_message - 1 downto 1);
                        bit_count := bit_count + 1;

                    elsif cpha = '1' then -- SPI mode 3
                        miso <= tx_buffer_output_data(bit_count);
                    end if;
                end if;
            end if;
        end if;

    end process communication_proc;

end architecture beh;
