library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_main is

    generic (
        bits_per_message   : integer := 8;
        sclk_divider_value : integer := 4;
        clk_period         : time    := 6 fs
    );

    port (
        -- Outbound data buffer ports.
        outbound_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0);
        outbound_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0);
        outbound_buffer_load   : in std_logic;

        -- Inbound data buffer ports.
        inbound_buffer_input  : in std_logic_vector(bits_per_message - 1 downto 0);
        inbound_buffer_output : out std_logic_vector(bits_per_message - 1 downto 0);
        inbound_buffer_load   : in std_logic;

        -- Rest of the ports.
        start_transmission     : in std_logic;
        mosi                   : out std_logic := '0';
        miso                   : in std_logic;
        cs                     : out std_logic := '1';
        clk                    : in std_logic;
        sclk                   : out std_logic := '0';
        cpol                   : in std_logic;
        cpha                   : in std_logic;
        last_shift_bit         : out std_logic := '0';
        rst                    : in std_logic;
        sclk_rising_edge_port  : out std_logic;
        sclk_falling_edge_port : out std_logic
    );

end entity spi_main;
architecture beh of spi_main is
    type state_t is (IDLE, TRANSMIT, FINISH_TRANSMISSION);
    signal state                       : state_t;
    signal sclk_rising_edge            : std_logic;
    signal sclk_falling_edge           : std_logic;
    signal outbound_buffer_output_data : std_logic_vector(bits_per_message - 1 downto 0);
    signal inbound_buffer_output_data  : std_logic_vector(bits_per_message - 1 downto 0);
begin

    -- Behavior process.
    bit_counter_beh : process (sclk_rising_edge, sclk_falling_edge)
        variable current_bits_processed : integer := 0;
    begin
        if sclk_rising_edge = '1' then

            -- SPI modes 0 and 3
            if (cpol = '0' and cpha = '0') or (cpol = '1' and cpha = '1') then

                -- If the communication is in Idle state, reset the number of processed bits and
                -- the last bit flag.
                if state = IDLE then
                    current_bits_processed := 0;
                    last_shift_bit <= '0';

                    -- If the transmission is ongoing, update the number of processed bits.
                elsif state = TRANSMIT then

                    -- If all the available bits per transmission have been sent or received,
                    -- raise the last bit flag.
                    if current_bits_processed = bits_per_message then
                        last_shift_bit <= '1';

                        -- If there are still bits remaining, update the count of processed bits.
                    else
                        current_bits_processed := current_bits_processed + 1;
                    end if;
                end if;
            end if;

        elsif sclk_falling_edge = '1' then

            -- SPI modes 1 and 2
            if (cpol = '0' and cpha = '1') or (cpol = '1' and cpha = '0') then

                -- If the communication is in Idle state, reset the number of processed bits and
                -- the last bit flag.
                if state = IDLE then
                    current_bits_processed := 0;
                    last_shift_bit <= '0';

                    -- If the transmission is ongoing, update the number of processed bits.
                elsif state = TRANSMIT then

                    -- If all the available bits per transmission have been sent or received,
                    -- raise the last bit flag.
                    if current_bits_processed = bits_per_message then
                        last_shift_bit <= '1';

                        -- If there are still bits remaining, update the count of processed bits.
                    else
                        current_bits_processed := current_bits_processed + 1;
                    end if;
                end if;
            end if;

        end if;
    end process bit_counter_beh;

    fsm_proc : process (clk)
        variable divider : integer := 0;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                inbound_buffer_output_data  <= (others => '0');
                outbound_buffer_output_data <= "11001100";
                state                       <= IDLE;
                divider := 0;

            else
                case state is
                    when IDLE =>
                        cs                <= '1';
                        sclk              <= cpol;
                        sclk_rising_edge  <= '0';
                        sclk_falling_edge <= '0';

                        -- Allow loading values into the inbound and outbound registers while in the
                        -- Idle state.
                        if inbound_buffer_load = '1' then
                            inbound_buffer_output_data <= inbound_buffer_input;
                        end if;
                        if outbound_buffer_load = '1' then
                            outbound_buffer_output_data <= outbound_buffer_input;
                        end if;

                        if start_transmission = '1' then
                            state <= TRANSMIT;
                        end if;

                    when TRANSMIT =>
                        cs <= '0';

                        if cpha = '1' then

                            -- Generate rising and falling edges of the SCLK.
                            if divider = sclk_divider_value then
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

                            -- Create a synthetic clock (SCLK) from the rising and falling edges and
                            -- shift the outbound and inbound buffers.
                            if sclk_rising_edge = '1' then
                                sclk <= '1';

                                -- SPI modes 0 and 3
                                if (cpol = '0' and cpha = '0') or (cpol = '1' and cpha = '1') then
                                    mosi                        <= outbound_buffer_output_data(0);
                                    outbound_buffer_output_data <= '0' & outbound_buffer_output_data(bits_per_message - 1 downto 1);
                                    inbound_buffer_output_data  <= inbound_buffer_output_data(bits_per_message - 2 downto 0) & miso;
                                end if;

                            elsif sclk_falling_edge = '1' then
                                sclk <= '0';

                                -- SPI modes 1 and 2
                                if (cpol = '0' and cpha = '1') or (cpol = '1' and cpha = '0') then
                                    mosi                        <= outbound_buffer_output_data(0);
                                    outbound_buffer_output_data <= '0' & outbound_buffer_output_data(bits_per_message - 1 downto 1);
                                    inbound_buffer_output_data  <= inbound_buffer_output_data(bits_per_message - 2 downto 0) & miso;
                                end if;
                            end if;

                            -- Move to the finish transmission state when the last bit is sent/received.
                            if last_shift_bit = '1' then
                                state <= FINISH_TRANSMISSION;
                            end if;

                        when FINISH_TRANSMISSION =>
                            cs                <= '1';
                            sclk              <= cpol;
                            sclk_rising_edge  <= '0';
                            sclk_falling_edge <= '0';
                            state             <= IDLE;
                        end case;
                end if;
            end if;
        end process fsm_proc;

        outbound_buffer_output <= outbound_buffer_output_data;
        inbound_buffer_output  <= inbound_buffer_output_data;
        sclk_rising_edge_port  <= sclk_rising_edge;
        sclk_falling_edge_port <= sclk_falling_edge;

    end architecture beh;
