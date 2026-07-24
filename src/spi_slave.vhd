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
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is

    generic (
        bits_per_message : integer := 8;
        clk_period       : time    := 6 fs
    );

    port (
        -- Outbound data buffer ports.
        outbound_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0);
        outbound_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0);
        outbound_buffer_load   : in std_logic;
        tx_shift_reg           : out std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');

        -- Inbound data buffer ports.
        inbound_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0);
        inbound_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0);
        inbound_buffer_load   : in std_logic;
        rx_shift_reg          : out std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');

        -- Rest of the ports.
        mosi                : in std_logic;
        miso                : out std_logic := '0';
        cs                  : in std_logic;
        clk                 : in std_logic;
        sclk                : in std_logic;
        cpol                : in std_logic;
        cpha                : in std_logic;
        temporary_mosi_port : out std_logic;
        temporary_miso_port : out std_logic;
        tx_buffer_sync_port : out std_logic;
        rx_buffer_sync_port : out std_logic;
        ack_syncs_port      : out std_logic
    );

end entity spi_slave;

architecture beh of spi_slave is
    signal tx_buffer_sync              : std_logic                                       := '0';
    signal rx_buffer_sync              : std_logic                                       := '0';
    signal ack_syncs                   : std_logic                                       := '0';
    signal temporary_mosi              : std_logic                                       := '0';
    signal temporary_miso              : std_logic                                       := '0';
    signal outbound_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0) := "10101010";
    signal inbound_buffer_output_data  : std_logic_vector(bits_per_message - 1 downto 0);
begin

    outbound_buffer_output <= outbound_buffer_output_data;
    inbound_buffer_output  <= inbound_buffer_output_data;
    temporary_miso_port    <= temporary_miso;
    temporary_mosi_port    <= temporary_mosi;
    tx_buffer_sync_port    <= tx_buffer_sync;
    rx_buffer_sync_port    <= rx_buffer_sync;
    ack_syncs_port         <= ack_syncs;

    internal_proc : process (clk)
    begin
        if rising_edge(clk) then

            if cs = '1' then
                if inbound_buffer_load = '1' then
                    rx_buffer_sync <= '1';
                end if;
                if outbound_buffer_load = '1' then
                    tx_buffer_sync <= '1';
                end if;

            elsif cs = '0' and ack_syncs = '1' then
                -- Lower both buffer sync flags if they were raised before and only
                -- after the communication process running in parallel acknowledges
                -- them.
                tx_buffer_sync <= '0';
                rx_buffer_sync <= '0';
            end if;
        end if;
    end process internal_proc;

    communication_proc : process (cs, sclk)
    begin

        if cs = '1' then
            -- Reset communication ports and variables when the SPI transmission
            -- is finished, i.e. when the CS line is pulled high by the master device.
            -- Also load into the corresponding buffers the values of the RX and TX
            -- shift registers.
            miso                        <= '0';
            temporary_mosi              <= '0';
            temporary_miso              <= '0';
            temporary_mosi              <= tx_shift_reg(0);
            outbound_buffer_output_data <= tx_shift_reg;
            inbound_buffer_output_data  <= rx_shift_reg;

        elsif rising_edge(sclk) then

            -- If the SPI transmission is ongoing (i.e. the CS line is at the logic low
            -- level), shift or sample data according to the SPI mode selected.

            if rx_buffer_sync = '1' then
                -- Load into the RX register the given input value if a load operation
                -- was queued.
                rx_shift_reg <= inbound_buffer_input;
                ack_syncs    <= '1';

            elsif tx_buffer_sync = '1' then
                -- Load into the TX register the given input value if a load operation
                -- was queued.
                tx_shift_reg <= outbound_buffer_input;
                ack_syncs    <= '1';
            else
                if cpol = '0' then
                    if cpha = '0' then -- SPI mode 0
                        temporary_miso <= tx_shift_reg(0);
                        tx_shift_reg   <= '0' & tx_shift_reg(bits_per_message - 1 downto 1);
                        rx_shift_reg   <= rx_shift_reg(bits_per_message - 2 downto 0) & mosi;

                    elsif cpha = '1' then -- SPI mode 1
                        miso           <= tx_shift_reg(0);
                        temporary_mosi <= mosi;
                    end if;

                elsif cpol = '1' then
                    if cpha = '0' then -- SPI mode 2
                        miso           <= temporary_miso;
                        temporary_mosi <= mosi;

                    elsif cpha = '1' then -- SPI mode 3
                        tx_shift_reg <= '0' & tx_shift_reg(bits_per_message - 1 downto 1);
                        rx_shift_reg <= rx_shift_reg(bits_per_message - 2 downto 0) & mosi;
                    end if;

                end if;
            end if;

        elsif falling_edge(clk) then

            if cpol = '0' then
                if cpha = '0' then -- SPI mode 0
                    miso           <= temporary_miso;
                    temporary_mosi <= mosi;

                elsif cpha = '1' then -- SPI mode 1
                    temporary_miso <= tx_shift_reg(0);
                    tx_shift_reg   <= '0' & tx_shift_reg(bits_per_message - 1 downto 1);
                    rx_shift_reg   <= rx_shift_reg(bits_per_message - 2 downto 0) & mosi;
                end if;

            elsif cpol = '1' then
                if cpha = '0' then -- SPI mode 2
                    temporary_miso <= tx_shift_reg(0);
                    tx_shift_reg   <= '0' & tx_shift_reg(bits_per_message - 1 downto 1);
                    rx_shift_reg   <= rx_shift_reg(bits_per_message - 2 downto 0) & mosi;

                elsif cpha = '1' then -- SPI mode 3
                    miso           <= tx_shift_reg(0);
                    temporary_mosi <= mosi;
                end if;

            end if;
        end if;

    end process communication_proc;

end architecture beh;
