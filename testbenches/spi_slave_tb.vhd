--------------------------------------------------------------------------------
-- File : spi_slave_tb.vhd
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
-- This is a testbench for the SPI slave module. It simulates the behavior of
-- the SPI slave by providing stimulus to the inputs and observing the outputs.
-- The testbench includes clock generation, reset handling, and various test
-- scenarios to verify the functionality of the SPI slave module under different
-- conditions.
--------------------------------------------------------------------------------
-- Revision History
-- Date     |       Author      |    Comments
-- 25-07-26 | Roi López Barata  | First basic version of this testbench.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave_tb is
end entity spi_slave_tb;

architecture rtl of spi_slave_tb is

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
    signal rx_shift_reg          : std_logic_vector(bits_per_message - 1 downto 0) := (others => '0');

    -- Rest of the ports.
    signal mosi : std_logic := '0';
    signal miso : std_logic := '0';
    signal cs   : std_logic := '1';
    signal clk  : std_logic := '0';
    signal sclk : std_logic := '0';
    signal rst  : std_logic := '0';
    signal cpol : std_logic := '0';
    signal cpha : std_logic := '0';

begin

    dut : entity work.spi_slave
        port map
        (
            outbound_buffer_input  => outbound_buffer_input,
            outbound_buffer_output => outbound_buffer_output,
            outbound_buffer_load   => outbound_buffer_load,
            inbound_buffer_input   => inbound_buffer_input,
            inbound_buffer_output  => inbound_buffer_output,
            inbound_buffer_load    => inbound_buffer_load,
            rx_shift_reg           => rx_shift_reg,
            mosi                   => mosi,
            miso                   => miso,
            cs                     => cs,
            clk                    => clk,
            sclk                   => sclk,
            rst                    => rst,
            cpol                   => cpol,
            cpha                   => cpha
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

    -- SPI clock process.
    p_sclk : process
    begin
        for i in 1 to 3000 loop
            wait for 4 * clk_period;
            sclk <= not sclk;
        end loop;
        wait;
    end process p_sclk;

    -- Stimulus process.
    stim_proc : process
    begin
        wait until rising_edge(clk);
        cpol <= '0';
        cpha <= '0';
        mosi <= '1';
        wait until rising_edge(clk);
        wait for 1 fs;
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
        wait for 2 fs;
        cs <= '0';
        wait for 1 fs;
        wait until falling_edge(clk);
        wait for 1 fs;
        wait until rising_edge(clk);
        wait for 1 fs;
        wait until rising_edge(sclk);
        wait for 1 fs;

        wait for 1 fs;
        wait until rising_edge(sclk);
        wait for 1 fs;
        wait until falling_edge(sclk);
        wait for 1 fs;
        mosi <= '0';
        wait until falling_edge(sclk);
        wait for 1 fs;
        wait until falling_edge(sclk);
        wait until rising_edge(sclk);
        wait for 1 fs;
        mosi <= '1';
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        cs <= '1';
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait until rising_edge(sclk);
        wait;
    end process stim_proc;

end architecture rtl;
