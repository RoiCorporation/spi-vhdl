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
            clk                    => clk,
            sclk                   => sclk,
            rst                    => rst,
            cpol                   => cpol,
            cpha                   => cpha,
            sclk_rising_edge_port  => open,
            sclk_falling_edge_port => open,
            last_shift_bit         => open
        );

    dut_spi_slave : entity work.spi_slave
        port map
        (
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
            clk                    => clk,
            sclk                   => sclk,
            rst                    => rst,
            cpol                   => cpol,
            cpha                   => cpha,
            bit_count_port         => bit_count
        );

    -- Clock process.
    p_clk : process
    begin
        for i in 1 to 30000 loop
            wait for clk_period / 2;
            clk <= not clk;
        end loop;
        wait;
    end process p_clk;

    stim_proc : process
    begin

        -- ---------------------------------------------------------------------
        -- Test suite 1: testing that the master and slave exchange the information
        -- stored in their transmission buffers after an SPI transmission for each
        -- of the 4 modes.

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 0 (CPOL = 0, CPHA = 0)
        cpol <= '0';
        cpha <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11011110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00011000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11001111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11000010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "11011110"
        report (
            "Expected master_outbound_buffer_output = 11011110, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00011000"
        report (
            "Expected master_inbound_buffer_output = 00011000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11001111"
        report (
            "Expected slave_outbound_buffer_output = 11001111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11000010"
        report (
            "Expected slave_inbound_buffer_output = 11000010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11001111"
        report (
            "Expected master_inbound_buffer_output = 11001111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11001111"
        report (
            "Expected slave_outbound_buffer_output = 11001111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11011110"
        report (
            "Expected slave_inbound_buffer_output = 11011110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11001111"
        report (
            "Expected master_inbound_buffer_output = 11001111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11001111"
        report (
            "Expected slave_outbound_buffer_output = 11001111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11011110"
        report (
            "Expected slave_inbound_buffer_output = 11011110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 1 (CPOL = 0, CPHA = 1)
        cpol <= '0';
        cpha <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10101100";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00100001";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00001101";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00110111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "10101100"
        report (
            "Expected master_outbound_buffer_output = 10101100, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100001"
        report (
            "Expected master_inbound_buffer_output = 00100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00001101"
        report (
            "Expected slave_outbound_buffer_output = 00001101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00110111"
        report (
            "Expected slave_inbound_buffer_output = 00110111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001101"
        report (
            "Expected master_inbound_buffer_output = 00001101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00001101"
        report (
            "Expected slave_outbound_buffer_output = 00001101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10101100"
        report (
            "Expected slave_inbound_buffer_output = 10101100, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001101"
        report (
            "Expected master_inbound_buffer_output = 00001101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00001101"
        report (
            "Expected slave_outbound_buffer_output = 00001101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10101100"
        report (
            "Expected slave_inbound_buffer_output = 10101100, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 2 (CPOL = 1, CPHA = 0)
        cpol <= '1';
        cpha <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10101010";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000001";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11100001";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10000010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "10101010"
        report (
            "Expected master_outbound_buffer_output = 10101010, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000001"
        report (
            "Expected master_inbound_buffer_output = 00000001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11100001"
        report (
            "Expected slave_outbound_buffer_output = 11100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10000010"
        report (
            "Expected slave_inbound_buffer_output = 10000010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11100001"
        report (
            "Expected master_inbound_buffer_output = 11100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11100001"
        report (
            "Expected slave_outbound_buffer_output = 11100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10101010"
        report (
            "Expected slave_inbound_buffer_output = 10101010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11100001"
        report (
            "Expected master_inbound_buffer_output = 11100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11100001"
        report (
            "Expected slave_outbound_buffer_output = 11100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10101010"
        report (
            "Expected slave_inbound_buffer_output = 10101010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 3 (CPOL = 1, CPHA = 1)
        cpol <= '1';
        cpha <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00001111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10111101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10100110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10010110";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "00001111"
        report (
            "Expected master_outbound_buffer_output = 00001111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10111101"
        report (
            "Expected master_inbound_buffer_output = 10111101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100110"
        report (
            "Expected slave_outbound_buffer_output = 10100110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10010110"
        report (
            "Expected slave_inbound_buffer_output = 10010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10100110"
        report (
            "Expected master_inbound_buffer_output = 10100110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100110"
        report (
            "Expected slave_outbound_buffer_output = 10100110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001111"
        report (
            "Expected slave_inbound_buffer_output = 00001111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10100110"
        report (
            "Expected master_inbound_buffer_output = 10100110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100110"
        report (
            "Expected slave_outbound_buffer_output = 10100110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001111"
        report (
            "Expected slave_inbound_buffer_output = 00001111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Test suite 2: testing that the registers are shifted in/out correctly
        -- and MISO and MOSI lines are fed the corresponding bit for every SCLK
        -- edge occurred during an SPI transmission. This test suite integrates
        -- the previous test suite assertions, to further validate the correct
        -- operation of the SPI master and slave modules.

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 0 (CPOL = 0, CPHA = 0)
        cpol <= '0';
        cpha <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01100101";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10111111";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10011101";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01010000";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "01100101"
        report (
            "Expected master_outbound_buffer_output = 01100101, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10111111"
        report (
            "Expected master_inbound_buffer_output = 10111111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00110010"
        report (
            "Expected master_outbound_buffer_output = 00110010, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11011111"
        report (
            "Expected master_inbound_buffer_output = 11011111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 1
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00011001"
        report (
            "Expected master_outbound_buffer_output = 00011001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01101111"
        report (
            "Expected master_inbound_buffer_output = 01101111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 2
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001100"
        report (
            "Expected master_outbound_buffer_output = 00001100, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10110111"
        report (
            "Expected master_inbound_buffer_output = 10110111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 3
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000110"
        report (
            "Expected master_outbound_buffer_output = 00000110, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11011011"
        report (
            "Expected master_inbound_buffer_output = 11011011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 4
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000011"
        report (
            "Expected master_outbound_buffer_output = 00000011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11101101"
        report (
            "Expected master_inbound_buffer_output = 11101101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 5
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01110110"
        report (
            "Expected master_inbound_buffer_output = 01110110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 6
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00111011"
        report (
            "Expected master_inbound_buffer_output = 00111011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 7
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10011101"
        report (
            "Expected master_inbound_buffer_output = 10011101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01010000"
        report (
            "Expected slave_inbound_buffer_output = 01010000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10011101"
        report (
            "Expected master_inbound_buffer_output = 10011101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01100101"
        report (
            "Expected slave_inbound_buffer_output = 01100101, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10011101"
        report (
            "Expected master_inbound_buffer_output = 10011101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10011101"
        report (
            "Expected slave_outbound_buffer_output = 10011101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01100101"
        report (
            "Expected slave_inbound_buffer_output = 01100101, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Second consecutive transmission with SPI mode 0.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11100000";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01001011";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01000011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00001010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "11100000"
        report (
            "Expected master_outbound_buffer_output = 11100000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001011"
        report (
            "Expected master_inbound_buffer_output = 01001011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "01110000"
        report (
            "Expected master_outbound_buffer_output = 01110000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10100101"
        report (
            "Expected master_inbound_buffer_output = 10100101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 1
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00111000"
        report (
            "Expected master_outbound_buffer_output = 00111000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11010010"
        report (
            "Expected master_inbound_buffer_output = 11010010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 2
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00011100"
        report (
            "Expected master_outbound_buffer_output = 00011100, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01101001"
        report (
            "Expected master_inbound_buffer_output = 01101001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 3
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001110"
        report (
            "Expected master_outbound_buffer_output = 00001110, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00110100"
        report (
            "Expected master_inbound_buffer_output = 00110100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 4
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000111"
        report (
            "Expected master_outbound_buffer_output = 00000111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00011010"
        report (
            "Expected master_inbound_buffer_output = 00011010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 5
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000011"
        report (
            "Expected master_outbound_buffer_output = 00000011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001101"
        report (
            "Expected master_inbound_buffer_output = 00001101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 6
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000110"
        report (
            "Expected master_inbound_buffer_output = 10000110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 7
        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01000011"
        report (
            "Expected master_inbound_buffer_output = 01000011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001010"
        report (
            "Expected slave_inbound_buffer_output = 00001010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01000011"
        report (
            "Expected master_inbound_buffer_output = 01000011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11100000"
        report (
            "Expected slave_inbound_buffer_output = 11100000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01000011"
        report (
            "Expected master_inbound_buffer_output = 01000011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01000011"
        report (
            "Expected slave_outbound_buffer_output = 01000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11100000"
        report (
            "Expected slave_inbound_buffer_output = 11100000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 1 (CPOL = 0, CPHA = 1)
        cpol <= '0';
        cpha <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10000000";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01001100";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11111010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "10000000"
        report (
            "Expected master_outbound_buffer_output = 10000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "01000000"
        report (
            "Expected master_outbound_buffer_output = 01000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 1
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00100000"
        report (
            "Expected master_outbound_buffer_output = 00100000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 2
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00010000"
        report (
            "Expected master_outbound_buffer_output = 00010000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000000"
        report (
            "Expected master_inbound_buffer_output = 10000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 3
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001000"
        report (
            "Expected master_outbound_buffer_output = 00001000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11000000"
        report (
            "Expected master_inbound_buffer_output = 11000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 4
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000100"
        report (
            "Expected master_outbound_buffer_output = 00000100, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01100000"
        report (
            "Expected master_inbound_buffer_output = 01100000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 5
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000010"
        report (
            "Expected master_outbound_buffer_output = 00000010, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00110000"
        report (
            "Expected master_inbound_buffer_output = 00110000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 6
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10011000"
        report (
            "Expected master_inbound_buffer_output = 10011000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 7
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001100"
        report (
            "Expected master_inbound_buffer_output = 01001100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111010"
        report (
            "Expected slave_inbound_buffer_output = 11111010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001100"
        report (
            "Expected master_inbound_buffer_output = 01001100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10000000"
        report (
            "Expected slave_inbound_buffer_output = 10000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001100"
        report (
            "Expected master_inbound_buffer_output = 01001100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001100"
        report (
            "Expected slave_outbound_buffer_output = 01001100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10000000"
        report (
            "Expected slave_inbound_buffer_output = 10000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Second consecutive transmission with SPI mode 1.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00000011";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10101110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00100100";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00010110";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "00000011"
        report (
            "Expected master_outbound_buffer_output = 00000011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10101110"
        report (
            "Expected master_inbound_buffer_output = 10101110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01010111"
        report (
            "Expected master_inbound_buffer_output = 01010111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 1
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00101011"
        report (
            "Expected master_inbound_buffer_output = 00101011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 2
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010101"
        report (
            "Expected master_inbound_buffer_output = 10010101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 3
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001010"
        report (
            "Expected master_inbound_buffer_output = 01001010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 4
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100101"
        report (
            "Expected master_inbound_buffer_output = 00100101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 5
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010010"
        report (
            "Expected master_inbound_buffer_output = 10010010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 6
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001001"
        report (
            "Expected master_inbound_buffer_output = 01001001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 7
        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100100"
        report (
            "Expected master_inbound_buffer_output = 00100100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00010110"
        report (
            "Expected slave_inbound_buffer_output = 00010110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100100"
        report (
            "Expected master_inbound_buffer_output = 00100100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000011"
        report (
            "Expected slave_inbound_buffer_output = 00000011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100100"
        report (
            "Expected master_inbound_buffer_output = 00100100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100100"
        report (
            "Expected slave_outbound_buffer_output = 00100100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000011"
        report (
            "Expected slave_inbound_buffer_output = 00000011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 2 (CPOL = 1, CPHA = 0)
        cpol <= '1';
        cpha <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11011011";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00100001";
        master_inbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01011000";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "11011011"
        report (
            "Expected master_outbound_buffer_output = 11011011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100001"
        report (
            "Expected master_inbound_buffer_output = 00100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "01101101"
        report (
            "Expected master_outbound_buffer_output = 01101101, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00010000"
        report (
            "Expected master_inbound_buffer_output = 00010000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 1
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00110110"
        report (
            "Expected master_outbound_buffer_output = 00110110, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001000"
        report (
            "Expected master_inbound_buffer_output = 00001000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 2
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00011011"
        report (
            "Expected master_outbound_buffer_output = 00011011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000100"
        report (
            "Expected master_inbound_buffer_output = 00000100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 3
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001101"
        report (
            "Expected master_outbound_buffer_output = 00001101, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000010"
        report (
            "Expected master_inbound_buffer_output = 00000010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 4
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000110"
        report (
            "Expected master_outbound_buffer_output = 00000110, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000001"
        report (
            "Expected master_inbound_buffer_output = 00000001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 5
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000011"
        report (
            "Expected master_outbound_buffer_output = 00000011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 6
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 7
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011000"
        report (
            "Expected slave_inbound_buffer_output = 01011000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11011011"
        report (
            "Expected slave_inbound_buffer_output = 11011011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11011011"
        report (
            "Expected slave_inbound_buffer_output = 11011011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Second consecutive transmission with SPI mode 2.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01011111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11110000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10010000";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00111110";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "01011111"
        report (
            "Expected master_outbound_buffer_output = 01011111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11110000"
        report (
            "Expected master_inbound_buffer_output = 11110000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00101111"
        report (
            "Expected master_outbound_buffer_output = 00101111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01111000"
        report (
            "Expected master_inbound_buffer_output = 01111000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 1
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00010111"
        report (
            "Expected master_outbound_buffer_output = 00010111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00111100"
        report (
            "Expected master_inbound_buffer_output = 00111100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 2
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001011"
        report (
            "Expected master_outbound_buffer_output = 00001011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00011110"
        report (
            "Expected master_inbound_buffer_output = 00011110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 3
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000101"
        report (
            "Expected master_outbound_buffer_output = 00000101, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001111"
        report (
            "Expected master_inbound_buffer_output = 00001111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 4
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000010"
        report (
            "Expected master_outbound_buffer_output = 00000010, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000111"
        report (
            "Expected master_inbound_buffer_output = 10000111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 5
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01000011"
        report (
            "Expected master_inbound_buffer_output = 01000011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 6
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100001"
        report (
            "Expected master_inbound_buffer_output = 00100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Bit 7
        -- Buffer updates and shift registers behavior tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010000"
        report (
            "Expected master_inbound_buffer_output = 10010000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00111110"
        report (
            "Expected slave_inbound_buffer_output = 00111110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- MOSI/MISO lines feed tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010000"
        report (
            "Expected master_inbound_buffer_output = 10010000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011111"
        report (
            "Expected slave_inbound_buffer_output = 01011111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010000"
        report (
            "Expected master_inbound_buffer_output = 10010000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01011111"
        report (
            "Expected slave_inbound_buffer_output = 01011111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Testing SPI mode 3 (CPOL = 1, CPHA = 1)
        cpol <= '1';
        cpha <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert buffer values after reset.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00101101";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01110000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10101111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11110011";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "00101101"
        report (
            "Expected master_outbound_buffer_output = 00101101, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01110000"
        report (
            "Expected master_inbound_buffer_output = 01110000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00010110"
        report (
            "Expected master_outbound_buffer_output = 00010110, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10111000"
        report (
            "Expected master_inbound_buffer_output = 10111000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 1
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001011"
        report (
            "Expected master_outbound_buffer_output = 00001011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11011100"
        report (
            "Expected master_inbound_buffer_output = 11011100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 2
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000101"
        report (
            "Expected master_outbound_buffer_output = 00000101, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11101110"
        report (
            "Expected master_inbound_buffer_output = 11101110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 3
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000010"
        report (
            "Expected master_outbound_buffer_output = 00000010, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11110111"
        report (
            "Expected master_inbound_buffer_output = 11110111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 4
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01111011"
        report (
            "Expected master_inbound_buffer_output = 01111011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 5
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10111101"
        report (
            "Expected master_inbound_buffer_output = 10111101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 6
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01011110"
        report (
            "Expected master_inbound_buffer_output = 01011110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 7
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10101111"
        report (
            "Expected master_inbound_buffer_output = 10101111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110011"
        report (
            "Expected slave_inbound_buffer_output = 11110011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10101111"
        report (
            "Expected master_inbound_buffer_output = 10101111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00101101"
        report (
            "Expected slave_inbound_buffer_output = 00101101, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10101111"
        report (
            "Expected master_inbound_buffer_output = 10101111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10101111"
        report (
            "Expected slave_outbound_buffer_output = 10101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00101101"
        report (
            "Expected slave_inbound_buffer_output = 00101101, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Second consecutive transmission with SPI mode 3.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10001111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01111110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10100001";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01101001";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffer values after loading new values.
        assert master_outbound_buffer_output = "10001111"
        report (
            "Expected master_outbound_buffer_output = 10001111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01111110"
        report (
            "Expected master_inbound_buffer_output = 01111110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';

        -- Bit 0
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "01000111"
        report (
            "Expected master_outbound_buffer_output = 01000111, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10111111"
        report (
            "Expected master_inbound_buffer_output = 10111111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 1
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00100011"
        report (
            "Expected master_outbound_buffer_output = 00100011, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01011111"
        report (
            "Expected master_inbound_buffer_output = 01011111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 2
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00010001"
        report (
            "Expected master_outbound_buffer_output = 00010001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00101111"
        report (
            "Expected master_inbound_buffer_output = 00101111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 3
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00001000"
        report (
            "Expected master_outbound_buffer_output = 00001000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00010111"
        report (
            "Expected master_inbound_buffer_output = 00010111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 4
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000100"
        report (
            "Expected master_outbound_buffer_output = 00000100, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001011"
        report (
            "Expected master_inbound_buffer_output = 00001011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 5
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000010"
        report (
            "Expected master_outbound_buffer_output = 00000010, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000101"
        report (
            "Expected master_inbound_buffer_output = 10000101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 6
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '0'
        report (
            "Expected MOSI = 0, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '0'
        report (
            "Expected MISO = 0, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000001"
        report (
            "Expected master_outbound_buffer_output = 00000001, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01000010"
        report (
            "Expected master_inbound_buffer_output = 01000010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- Bit 7
        -- MOSI/MISO lines feed tests.
        wait until falling_edge(sclk);
        wait for 1 fs;
        assert mosi = '1'
        report (
            "Expected MOSI = 1, got " &
            to_string(MOSI)
            )
            severity error;
        assert miso = '1'
        report (
            "Expected MISO = 1, got " &
            to_string(MISO)
            )
            severity error;

        -- Buffer updates and shift registers behavior tests.
        wait until rising_edge(sclk);
        wait for 1 fs;
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10100001"
        report (
            "Expected master_inbound_buffer_output = 10100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101001"
        report (
            "Expected slave_inbound_buffer_output = 01101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- End of the transmission
        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10100001"
        report (
            "Expected master_inbound_buffer_output = 10100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10001111"
        report (
            "Expected slave_inbound_buffer_output = 10001111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Check that the buffers maintain their values when no input is applied.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10100001"
        report (
            "Expected master_inbound_buffer_output = 10100001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10100001"
        report (
            "Expected slave_outbound_buffer_output = 10100001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10001111"
        report (
            "Expected slave_inbound_buffer_output = 10001111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- ---------------------------------------------------------------------
        -- Test suite 3: integral testing of the implementation through multiple
        -- consecutive SPI transmissions in all 4 modes.

        -- ---------------------------------------------------------------------
        -- Transmission 1
        cpol <= '0';
        cpha <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10101011";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01010001";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00011100";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11010100";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00011100"
        report (
            "Expected master_inbound_buffer_output = 00011100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00011100"
        report (
            "Expected slave_outbound_buffer_output = 00011100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10101011"
        report (
            "Expected slave_inbound_buffer_output = 10101011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 2
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10110110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10111111";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10000011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00100111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000011"
        report (
            "Expected master_inbound_buffer_output = 10000011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10000011"
        report (
            "Expected slave_outbound_buffer_output = 10000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10110110"
        report (
            "Expected slave_inbound_buffer_output = 10110110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 3
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00110001";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11111111";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01011001";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11010110";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01011001"
        report (
            "Expected master_inbound_buffer_output = 01011001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01011001"
        report (
            "Expected slave_outbound_buffer_output = 01011001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00110001"
        report (
            "Expected slave_inbound_buffer_output = 00110001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 4
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00110001";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11111111";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01011001";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11010110";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01011001"
        report (
            "Expected master_inbound_buffer_output = 01011001, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01011001"
        report (
            "Expected slave_outbound_buffer_output = 01011001, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00110001"
        report (
            "Expected slave_inbound_buffer_output = 00110001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 5
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '1';
        cpha <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11100110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00010111";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11111110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10001111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11111110"
        report (
            "Expected master_inbound_buffer_output = 11111110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11111110"
        report (
            "Expected slave_outbound_buffer_output = 11111110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11100110"
        report (
            "Expected slave_inbound_buffer_output = 11100110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 6
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00000110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11110110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11110110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01011101";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11110110"
        report (
            "Expected master_inbound_buffer_output = 11110110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11110110"
        report (
            "Expected slave_outbound_buffer_output = 11110110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000110"
        report (
            "Expected slave_inbound_buffer_output = 00000110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 7
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '1';
        cpha <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11101010";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00011110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01001010";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00110111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01001010"
        report (
            "Expected master_inbound_buffer_output = 01001010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01001010"
        report (
            "Expected slave_outbound_buffer_output = 01001010, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11101010"
        report (
            "Expected slave_inbound_buffer_output = 11101010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 8
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '0';
        cpha <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10110010";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11101101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00000000";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01000010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00000000"
        report (
            "Expected slave_outbound_buffer_output = 00000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10110010"
        report (
            "Expected slave_inbound_buffer_output = 10110010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 9
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01001110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000011";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01011100";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11110111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01011100"
        report (
            "Expected master_inbound_buffer_output = 01011100, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01011100"
        report (
            "Expected slave_outbound_buffer_output = 01011100, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01001110"
        report (
            "Expected slave_inbound_buffer_output = 01001110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 10
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00001101";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11011101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00101111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11111111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00101111"
        report (
            "Expected master_inbound_buffer_output = 00101111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00101111"
        report (
            "Expected slave_outbound_buffer_output = 00101111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00001101"
        report (
            "Expected slave_inbound_buffer_output = 00001101, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 11
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00000100";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10010110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11011011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00000000";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11011011"
        report (
            "Expected master_inbound_buffer_output = 11011011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11011011"
        report (
            "Expected slave_outbound_buffer_output = 11011011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000100"
        report (
            "Expected slave_inbound_buffer_output = 00000100, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 12
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert CPOL and CPHA remain untouched despite the reset.
        assert cpol = '0'
        report (
            "Expected cpol = 0, got " &
            to_string(cpol)
            )
            severity error;
        assert cpha = '1'
        report (
            "Expected cpha = 1, got " &
            to_string(cpha)
            )
            severity error;

        -- Assert both master's buffers are reset to 0 with the reset pulse.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11010100";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11000000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01111011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01000111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01111011"
        report (
            "Expected master_inbound_buffer_output = 01111011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01111011"
        report (
            "Expected slave_outbound_buffer_output = 01111011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11010100"
        report (
            "Expected slave_inbound_buffer_output = 11010100, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 13
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10001011";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01010101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10000011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00010100";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000011"
        report (
            "Expected master_inbound_buffer_output = 10000011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10000011"
        report (
            "Expected slave_outbound_buffer_output = 10000011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10001011"
        report (
            "Expected slave_inbound_buffer_output = 10001011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 14
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '0';
        cpha <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01101011";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10110001";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10010000";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01110001";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010000"
        report (
            "Expected master_inbound_buffer_output = 10010000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010000"
        report (
            "Expected slave_outbound_buffer_output = 10010000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01101011"
        report (
            "Expected slave_inbound_buffer_output = 01101011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 15
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01111111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11111000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10000000";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01100101";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000000"
        report (
            "Expected master_inbound_buffer_output = 10000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10000000"
        report (
            "Expected slave_outbound_buffer_output = 10000000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01111111"
        report (
            "Expected slave_inbound_buffer_output = 01111111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 16
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11110101";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11011010";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10010011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01100101";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10010011"
        report (
            "Expected master_inbound_buffer_output = 10010011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10010011"
        report (
            "Expected slave_outbound_buffer_output = 10010011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11110101"
        report (
            "Expected slave_inbound_buffer_output = 11110101, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 17
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '1';
        cpha <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11111111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11001011";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11111111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00101100";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11111111"
        report (
            "Expected master_inbound_buffer_output = 11111111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11111111"
        report (
            "Expected slave_outbound_buffer_output = 11111111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111111"
        report (
            "Expected slave_inbound_buffer_output = 11111111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 18
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10000010";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00011100";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01100010";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11110001";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01100010"
        report (
            "Expected master_inbound_buffer_output = 01100010, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01100010"
        report (
            "Expected slave_outbound_buffer_output = 01100010, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10000010"
        report (
            "Expected slave_inbound_buffer_output = 10000010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 19
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10000010";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01111011";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11111110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01000000";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11111110"
        report (
            "Expected master_inbound_buffer_output = 11111110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11111110"
        report (
            "Expected slave_outbound_buffer_output = 11111110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10000010"
        report (
            "Expected slave_inbound_buffer_output = 10000010, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 20
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '0';
        cpha <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00101001";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000100";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00011000";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10101101";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00011000"
        report (
            "Expected master_inbound_buffer_output = 00011000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00011000"
        report (
            "Expected slave_outbound_buffer_output = 00011000, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00101001"
        report (
            "Expected slave_inbound_buffer_output = 00101001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 21
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11011001";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "01111110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11110101";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10111001";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11110101"
        report (
            "Expected master_inbound_buffer_output = 11110101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11110101"
        report (
            "Expected slave_outbound_buffer_output = 11110101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11011001"
        report (
            "Expected slave_inbound_buffer_output = 11011001, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 22
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '0';
        cpha <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01110000";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00000101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11011110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10101101";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11011110"
        report (
            "Expected master_inbound_buffer_output = 11011110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11011110"
        report (
            "Expected slave_outbound_buffer_output = 11011110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01110000"
        report (
            "Expected slave_inbound_buffer_output = 01110000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 23
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        rst <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert CPOL and CPHA remain untouched despite the reset.
        assert cpol = '0'
        report (
            "Expected cpol = 0, got " &
            to_string(cpol)
            )
            severity error;
        assert cpha = '0'
        report (
            "Expected cpha = 0, got " &
            to_string(cpha)
            )
            severity error;

        -- Assert both master's buffers are reset to 0 with the reset pulse.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00000000"
        report (
            "Expected master_inbound_buffer_output = 00000000, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11111111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00001011";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11110111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "10100100";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11110111"
        report (
            "Expected master_inbound_buffer_output = 11110111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11110111"
        report (
            "Expected slave_outbound_buffer_output = 11110111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11111111"
        report (
            "Expected slave_inbound_buffer_output = 11111111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 24
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '1';
        cpha <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "01001000";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "10001010";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00100111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11001111";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00100111"
        report (
            "Expected master_inbound_buffer_output = 00100111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00100111"
        report (
            "Expected slave_outbound_buffer_output = 00100111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "01001000"
        report (
            "Expected slave_inbound_buffer_output = 01001000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 25
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '1';
        cpha <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "11011110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11110000";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10000110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00000010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10000110"
        report (
            "Expected master_inbound_buffer_output = 10000110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10000110"
        report (
            "Expected slave_outbound_buffer_output = 10000110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "11011110"
        report (
            "Expected slave_inbound_buffer_output = 11011110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 26
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '1';
        cpha <= '0';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10011110";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11100110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "11111111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "11001100";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "11111111"
        report (
            "Expected master_inbound_buffer_output = 11111111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "11111111"
        report (
            "Expected slave_outbound_buffer_output = 11111111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10011110"
        report (
            "Expected slave_inbound_buffer_output = 10011110, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 27
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00100100";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11100110";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "00001110";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00111110";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001110"
        report (
            "Expected master_inbound_buffer_output = 00001110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00001110"
        report (
            "Expected slave_outbound_buffer_output = 00001110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00100100"
        report (
            "Expected slave_inbound_buffer_output = 00100100, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 28
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "00001110"
        report (
            "Expected master_inbound_buffer_output = 00001110, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "00001110"
        report (
            "Expected slave_outbound_buffer_output = 00001110, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000000"
        report (
            "Expected slave_inbound_buffer_output = 00000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 29
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10100011";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11011101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01010101";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "00001000";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01010101"
        report (
            "Expected master_inbound_buffer_output = 01010101, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01010101"
        report (
            "Expected slave_outbound_buffer_output = 01010101, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10100011"
        report (
            "Expected slave_inbound_buffer_output = 10100011, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 30
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "10000000";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "11011101";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "01100011";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01110010";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "01100011"
        report (
            "Expected master_inbound_buffer_output = 01100011, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "01100011"
        report (
            "Expected slave_outbound_buffer_output = 01100011, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "10000000"
        report (
            "Expected slave_inbound_buffer_output = 10000000, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        -- ---------------------------------------------------------------------
        -- Transmission 31
        wait until rising_edge(clk);
        wait for 1 fs;
        cpol <= '0';
        cpha <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_input <= "00000111";
        master_outbound_buffer_load  <= '1';
        master_inbound_buffer_input  <= "00111111";
        master_inbound_buffer_load   <= '1';
        slave_outbound_buffer_input  <= "10001111";
        slave_outbound_buffer_load   <= '1';
        slave_inbound_buffer_input   <= "01111101";
        slave_inbound_buffer_load    <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        master_outbound_buffer_load <= '0';
        master_inbound_buffer_load  <= '0';
        slave_outbound_buffer_load  <= '0';
        slave_inbound_buffer_load   <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
        start_transmission <= '0';
        wait until cs = '0';
        wait until cs = '1';
        wait until rising_edge(clk);
        wait for 1 fs;

        -- Assert master and slave buffers' values after the transmission.
        assert master_outbound_buffer_output = "00000000"
        report (
            "Expected master_outbound_buffer_output = 00000000, got " &
            to_string(master_outbound_buffer_output)
            )
            severity error;
        assert master_inbound_buffer_output = "10001111"
        report (
            "Expected master_inbound_buffer_output = 10001111, got " &
            to_string(master_inbound_buffer_output)
            )
            severity error;
        assert slave_outbound_buffer_output = "10001111"
        report (
            "Expected slave_outbound_buffer_output = 10001111, got " &
            to_string(slave_outbound_buffer_output)
            )
            severity error;
        assert slave_inbound_buffer_output = "00000111"
        report (
            "Expected slave_inbound_buffer_output = 00000111, got " &
            to_string(slave_inbound_buffer_output)
            )
            severity error;

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        wait;
    end process stim_proc;
end architecture;
