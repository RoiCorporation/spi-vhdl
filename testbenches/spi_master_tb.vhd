--------------------------------------------------------------------------------
-- File : spi_master_tb.vhd
-- Project : SPI implementation in VHDL
-- Creation : 21-07-2026
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
-- This is a testbench for the SPI master module. It simulates the behavior of
-- the SPI master by providing stimulus to the inputs and observing the outputs.
-- The testbench includes clock generation, reset handling, and various test
-- scenarios to verify the functionality of the SPI master module under different
-- conditions.
--------------------------------------------------------------------------------
-- Revision History
-- Date     |       Author      |    Comments
-- 21-07-26 | Roi López Barata  | First basic version of this testbench.
-- 23-07-26 | Roi López Barata  | Improved testbench functionality.
-- 25-07-26 | Roi López Barata  | Added separation newline.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_tb is
end entity spi_master_tb;

architecture rtl of spi_master_tb is

    -- Constants.
    constant bits_per_message : integer := 8;
    constant clk_period       : time    := 6 fs;

    -- Outbound data buffer ports.
    signal outbound_buffer_input  : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal outbound_buffer_output : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal outbound_buffer_load   : std_logic                                       := '0';

    -- Inbound data buffer ports.
    signal inbound_buffer_input  : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal inbound_buffer_output : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal inbound_buffer_load   : std_logic                                       := '0';

    -- Rest of the ports.
    signal start_transmission  : std_logic := '0';
    signal mosi                : std_logic := '0';
    signal miso                : std_logic := '0';
    signal cs                  : std_logic := '0';
    signal clk                 : std_logic := '0';
    signal sclk                : std_logic;
    signal cpol                : std_logic := '0';
    signal cpha                : std_logic := '0';
    signal rst                 : std_logic := '0';
    signal sclk_rising_edge    : std_logic;
    signal sclk_falling_edge   : std_logic;
    signal last_shift_bit      : std_logic;
    signal temporary_miso_port : std_logic;
    signal temporary_mosi_port : std_logic;

begin

    dut : entity work.spi_master
        port map
        (
            outbound_buffer_input  => outbound_buffer_input,
            outbound_buffer_output => outbound_buffer_output,
            outbound_buffer_load   => outbound_buffer_load,
            inbound_buffer_input   => inbound_buffer_input,
            inbound_buffer_output  => inbound_buffer_output,
            inbound_buffer_load    => inbound_buffer_load,
            start_transmission     => start_transmission,
            mosi                   => mosi,
            miso                   => miso,
            cs                     => cs,
            clk                    => clk,
            sclk                   => sclk,
            cpol                   => cpol,
            cpha                   => cpha,
            rst                    => rst,
            sclk_rising_edge_port  => sclk_rising_edge,
            sclk_falling_edge_port => sclk_falling_edge,
            last_shift_bit         => last_shift_bit,
            temporary_miso_port    => temporary_miso_port,
            temporary_mosi_port    => temporary_mosi_port
        );

    -- Clock process.
    p_clk : process
    begin
        for i in 1 to 3000 loop
            wait for clk_period / 2;
            clk <= not clk;
        end loop;
        wait;
    end process p_clk;

    -- Stimulus process.
    stim_proc : process
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        cpol <= '1';
        cpha <= '1';
        rst  <= '1';
        miso <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        outbound_buffer_input <= "11011111";
        outbound_buffer_load  <= '1';
        inbound_buffer_input  <= "11111111";
        inbound_buffer_load   <= '1';
        wait until falling_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        outbound_buffer_load <= '0';
        inbound_buffer_load  <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        start_transmission <= '1';
        wait until falling_edge(clk);
        wait for 1 fs;
        miso               <= '0';
        start_transmission <= '0';
        wait until rising_edge(clk);

        wait for 1 fs;
        wait until rising_edge(sclk);
        wait for 1 fs;
        wait until falling_edge(sclk);
        wait for 1 fs;
        miso <= '0';
        wait until falling_edge(sclk);
        wait for 1 fs;
        miso <= '1';
        wait until falling_edge(sclk);
        wait until rising_edge(sclk);

        for i in 1 to 250 loop
            wait until rising_edge(clk);
        end loop;

        cpol <= '0';
        cpha <= '0';
        rst  <= '1';
        miso <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        outbound_buffer_input <= "11011111";
        outbound_buffer_load  <= '1';
        inbound_buffer_input  <= "00000000";
        inbound_buffer_load   <= '1';
        wait until falling_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        outbound_buffer_load <= '0';
        inbound_buffer_load  <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        start_transmission <= '1';
        wait until falling_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        miso               <= '1';
        start_transmission <= '0';
        wait until rising_edge(clk);

        wait for 1 fs;
        wait until rising_edge(sclk);
        wait for 1 fs;
        wait until falling_edge(sclk);
        wait for 1 fs;
        miso <= '1';
        wait until falling_edge(sclk);
        wait for 1 fs;
        miso <= '0';
        wait until falling_edge(sclk);
        wait until rising_edge(sclk);
        -- wait for 1 fs;
        -- miso <= '0';
        for i in 1 to 250 loop
            wait until rising_edge(clk);
        end loop;

        cpol <= '1';
        cpha <= '0';
        rst  <= '1';
        miso <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        outbound_buffer_input <= "11011111";
        outbound_buffer_load  <= '1';
        inbound_buffer_input  <= "00000000";
        inbound_buffer_load   <= '1';
        wait until falling_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        outbound_buffer_load <= '0';
        inbound_buffer_load  <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        start_transmission <= '1';
        wait until falling_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        miso               <= '1';
        start_transmission <= '0';
        wait until rising_edge(clk);

        wait for 1 fs;
        wait until rising_edge(sclk);
        wait for 1 fs;
        wait until falling_edge(sclk);
        wait for 1 fs;
        miso <= '1';
        wait until falling_edge(sclk);
        wait for 1 fs;
        miso <= '0';
        wait until falling_edge(sclk);
        wait until rising_edge(sclk);
        wait;
    end process stim_proc;

end architecture rtl;
