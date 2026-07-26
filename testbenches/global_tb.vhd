--------------------------------------------------------------------------------
-- File : global_tb.vhd
-- Project : SPI implementation in VHDL
-- Creation : 25-07-2026
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
-- This is a global testbench that serves as a top-level testbench for the SPI
-- implementation in VHDL. It instantiates both the SPI master and SPI slave
-- modules, allowing for comprehensive testing of the SPI communication between
-- the master and slave entities. The global testbench coordinates the simulation
-- of both modules, providing a complete environment for verifying the
-- functionality of the SPI system.
--------------------------------------------------------------------------------
-- Revision History
-- Date     |       Author      |    Comments
-- 27-07-26 | Roi López Barata  | First basic version of this testbench.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity global_tb is
end entity global_tb;

architecture rtl of global_tb is

    -- Constants.
    constant bits_per_message : integer := 8;
    constant clk_period       : time    := 6 fs;

    -- Master module ports.
    signal clk                           : std_logic                                       := '0';
    signal master_outbound_buffer_input  : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal master_outbound_buffer_output : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal master_outbound_buffer_load   : std_logic                                       := '0';
    signal master_inbound_buffer_input   : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal master_inbound_buffer_output  : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal master_inbound_buffer_load    : std_logic                                       := '0';
    signal start_transmission            : std_logic                                       := '0';
    signal mosi                          : std_logic                                       := '0';
    signal miso                          : std_logic                                       := '0';
    signal cs                            : std_logic                                       := '1';
    signal sclk                          : std_logic                                       := '0';
    signal cpol                          : std_logic                                       := '0';
    signal cpha                          : std_logic                                       := '0';
    signal rst                           : std_logic                                       := '0';

    -- Slave module ports.
    signal slave_outbound_buffer_input  : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal slave_outbound_buffer_output : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal slave_outbound_buffer_load   : std_logic                                       := '0';
    signal slave_inbound_buffer_input   : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal slave_inbound_buffer_output  : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');
    signal slave_inbound_buffer_load    : std_logic                                       := '0';
    signal slave_rx_shift_reg           : std_logic_vector(bits_per_message - 1 downto 0);
    signal bit_count                    : natural := 0;
begin

    dut_spi_master : entity work.spi_master
        port map
        (
            clk                    => clk,
            outbound_buffer_input  => master_outbound_buffer_input,
            outbound_buffer_output => master_outbound_buffer_output,
            outbound_buffer_load   => master_outbound_buffer_load,
            inbound_buffer_input   => master_inbound_buffer_input,
            inbound_buffer_output  => master_inbound_buffer_output,
            inbound_buffer_load    => master_inbound_buffer_load,
            start_transmission     => start_transmission,
            mosi                   => mosi,
            miso                   => miso,
            cs                     => cs,
            sclk                   => sclk,
            cpol                   => cpol,
            cpha                   => cpha,
            rst                    => rst,
            sclk_rising_edge_port  => open,
            sclk_falling_edge_port => open,
            last_shift_bit         => open,
            temporary_miso_port    => open,
            temporary_mosi_port    => open
        );

    dut_spi_slave : entity work.spi_slave
        port map
        (
            clk                    => clk,
            outbound_buffer_input  => slave_outbound_buffer_input,
            outbound_buffer_output => slave_outbound_buffer_output,
            outbound_buffer_load   => slave_outbound_buffer_load,
            inbound_buffer_input   => slave_inbound_buffer_input,
            inbound_buffer_output  => slave_inbound_buffer_output,
            inbound_buffer_load    => slave_inbound_buffer_load,
            rx_shift_reg           => slave_rx_shift_reg,
            mosi                   => mosi,
            miso                   => miso,
            cs                     => cs,
            rst                    => rst,
            sclk                   => sclk,
            cpol                   => cpol,
            cpha                   => cpha,
            temporary_miso_port    => open,
            temporary_mosi_port    => open,
            tx_buffer_sync_port    => open,
            rx_buffer_sync_port    => open,
            bit_count_port         => bit_count
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

    stim_proc : process
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst                          <= '0';
        master_outbound_buffer_input <= "11011110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11001111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11000010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until rising_edge(clk);
        wait until cs = '1';
        wait until rising_edge(clk); -- asdf asdf asfda sdf
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst                          <= '0';
        master_outbound_buffer_input <= "11001000";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11001111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11000010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until rising_edge(clk);
        wait;
    end process stim_proc;
end architecture;
