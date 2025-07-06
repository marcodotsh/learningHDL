library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.neorv32_package.all;
use work.neorv32_bootloader_image.all;
use work.sha_256_pkg.all;

entity neorv32_boot_rom_hasher is
    generic (
        RESET_VALUE : std_ulogic := '0'
    );
    port(
        clk         : in  std_ulogic;
        rst         : in  std_ulogic;
        start       : in  std_ulogic;
        words_to_read : in std_ulogic_vector(31 downto 0);
        bus_rsp_i   : in  bus_rsp_t;
        bus_req_o   : out bus_req_t;
        done        : out std_ulogic;
        hash_o      : out std_ulogic_vector((WORD_SIZE * 8)-1 downto 0)
    );
end entity;

architecture behavioral of neorv32_boot_rom_hasher is
    type state_type is (RESET, IDLE, CHECK_INPUT_END, MEM_REQ, MEM_READ, CHECK_FULL_BLOCK, SEND_BLOCK, CHECK_PROGRESS, PAD_ONE_BIT, CHECK_LAST_BLOCK, SEND_BLOCK_AFTER_PAD, CHECK_PROGRESS_AFTER_PAD, ADD_TAIL, DONE_STATE);
    signal CURRENT_STATE, NEXT_STATE : state_type;

    -- counters
    constant WORDS_IN_BLOCK_COUNT_LIMIT : std_ulogic_vector(8 downto 0) := std_ulogic_vector(to_unsigned(16, 9));
    signal   WORDS_IN_BLOCK_COUNTER     : std_ulogic_vector(8 downto 0) := (others => '0');
    signal   BLOCKS_COUNTER             : std_ulogic_vector(31 downto 0) := (others => '0');

    -- output registers
    signal bus_req_reg : bus_req_t;
    signal done_reg : std_ulogic;

    -- internal registers
    signal addr        : std_ulogic_vector(31 downto 0) := (others => '0');
    signal read_data : std_ulogic_vector(31 downto 0);
    signal hash_tail : std_ulogic_vector(63 downto 0); -- size of the bootloader to write in last padded block
    signal msg_block_buf : std_ulogic_vector(0 to (16 * WORD_SIZE)-1);

    -- signals from sha256 core
    signal block_waiting : std_ulogic;
    signal block_process : std_ulogic;
    signal finished : std_ulogic;

    -- signals to sha256 core
    signal block_valid : std_ulogic;
    signal n_blocks : std_ulogic_vector(31 downto 0);
    signal msg_block_in : std_ulogic_vector(0 to (16 * WORD_SIZE)-1);

function to_hstring(slv : std_ulogic_vector) return string is
  variable result : string(1 to slv'length/4);
  variable v      : std_ulogic_vector(3 downto 0);
  variable idx    : integer := 1;
  variable i      : integer := slv'left;
begin
  while i >= slv'right loop
    v := slv(i downto i-3);
    case v is
      when "0000" => result(idx) := '0';
      when "0001" => result(idx) := '1';
      when "0010" => result(idx) := '2';
      when "0011" => result(idx) := '3';
      when "0100" => result(idx) := '4';
      when "0101" => result(idx) := '5';
      when "0110" => result(idx) := '6';
      when "0111" => result(idx) := '7';
      when "1000" => result(idx) := '8';
      when "1001" => result(idx) := '9';
      when "1010" => result(idx) := 'A';
      when "1011" => result(idx) := 'B';
      when "1100" => result(idx) := 'C';
      when "1101" => result(idx) := 'D';
      when "1110" => result(idx) := 'E';
      when others  => result(idx) := 'F';
    end case;
    idx := idx + 1;
    i := i - 4;
  end loop;
  return result;
end function;

function state_to_string(s : state_type) return string is
begin
  case s is
    when RESET    => return "RESET";
    when IDLE     => return "IDLE";
    when CHECK_INPUT_END     => return "CHECK_INPUT_END";
    when MEM_REQ  => return "MEM_REQ";
    when MEM_READ => return "MEM_READ";
    when CHECK_FULL_BLOCK => return "CHECK_FULL_BLOCK";
    when SEND_BLOCK       => return "SEND_BLOCK";
    when CHECK_PROGRESS   => return "CHECK_PROGRESS";
    when PAD_ONE_BIT   => return "PAD_ONE_BIT";
    when CHECK_LAST_BLOCK   => return "CHECK_LAST_BLOCK";
    when SEND_BLOCK_AFTER_PAD   => return "SEND_BLOCK_AFTER_PAD";
    when CHECK_PROGRESS_AFTER_PAD   => return "CHECK_PROGRESS_AFTER_PAD";
    when ADD_TAIL   => return "ADD_TAIL";
    when DONE_STATE     => return "DONE_STATE";
  end case;
end function;

begin

    sha256_core: entity work.sha_256_core
    port map (
      clk          => clk,
      rst          => rst,
      block_waiting  => block_waiting,
      block_valid  => block_valid,
      block_process  => block_process,
      n_blocks     => n_blocks,
      msg_block_in => msg_block_in,
      finished     => finished,
      data_out => hash_o
    );

    --state report
    process(clk)
    begin
    if rising_edge(clk) then
        report state_to_string(CURRENT_STATE) & "->" & state_to_string(NEXT_STATE);
    end if;
    end process;

    --change state logic
    process(clk, rst)
    begin
        if(rst=RESET_VALUE) then
            CURRENT_STATE <= RESET;
        elsif(rising_edge(clk)) then
            CURRENT_STATE <= NEXT_STATE;
        end if;
    end process;

    --next state logic
    process(CURRENT_STATE, rst, start, bus_rsp_i, WORDS_IN_BLOCK_COUNTER, block_waiting, block_process, addr, words_to_read, BLOCKS_COUNTER)
    begin
        case CURRENT_STATE is
            when RESET =>
                if(rst=RESET_VALUE) then
                    NEXT_STATE <= RESET;
                else
                    NEXT_STATE <= IDLE;
                end if;
            when IDLE =>
                if start = '1' then
                    NEXT_STATE <= CHECK_INPUT_END;
                else
                    NEXT_STATE <= IDLE;
                end if;
            when CHECK_INPUT_END =>
                if shift_right(unsigned(addr),2) = unsigned(words_to_read) then
                    NEXT_STATE <= PAD_ONE_BIT;
                else
                    NEXT_STATE <= MEM_REQ;
                end if;
            when MEM_REQ =>
                NEXT_STATE <= MEM_READ;
            when MEM_READ =>
                if bus_rsp_i.ack = '1' then
                    NEXT_STATE <= CHECK_FULL_BLOCK;
                else
                    NEXT_STATE <= MEM_READ;
                end if;
            when CHECK_FULL_BLOCK =>
                if (unsigned(WORDS_IN_BLOCK_COUNTER) = (unsigned(WORDS_IN_BLOCK_COUNT_LIMIT)-1)) then
                    NEXT_STATE <= SEND_BLOCK;
                else
                    NEXT_STATE <= CHECK_INPUT_END;
                end if;
            when SEND_BLOCK =>
                if (block_waiting = '1') then
                   NEXT_STATE <= CHECK_PROGRESS; 
                else
                    NEXT_STATE <= SEND_BLOCK;
                end if;
            when CHECK_PROGRESS =>
                if (block_process = '1') then
                    if unsigned(BLOCKS_COUNTER) = unsigned(n_blocks) then
                        NEXT_STATE <= DONE_STATE;
                    else
                        NEXT_STATE <= CHECK_INPUT_END;
                    end if;
                else
                    NEXT_STATE <= CHECK_PROGRESS;
                end if;
            when PAD_ONE_BIT =>
                NEXT_STATE <= CHECK_LAST_BLOCK;
            when CHECK_LAST_BLOCK =>
                if unsigned(BLOCKS_COUNTER) = unsigned(n_blocks)-1 then
                    NEXT_STATE <= ADD_TAIL;
                else
                    NEXT_STATE <= SEND_BLOCK_AFTER_PAD;
                end if;
            when SEND_BLOCK_AFTER_PAD =>
                if (block_waiting = '1') then
                   NEXT_STATE <= CHECK_PROGRESS_AFTER_PAD; 
                else
                    NEXT_STATE <= SEND_BLOCK_AFTER_PAD;
                end if;
            when CHECK_PROGRESS_AFTER_PAD =>
                if (block_process = '1') then
                    if unsigned(BLOCKS_COUNTER) = unsigned(n_blocks) then
                        NEXT_STATE <= DONE_STATE;
                    else
                        NEXT_STATE <= ADD_TAIL;
                    end if;
                else
                    NEXT_STATE <= CHECK_PROGRESS;
                end if;
            when ADD_TAIL =>
                NEXT_STATE <= SEND_BLOCK;
            when DONE_STATE =>
                NEXT_STATE <= DONE_STATE;
        end case;
    end process;

    --output and register logic
    process(clk, rst)
    begin
        if(rst=RESET_VALUE) then
            bus_req_reg <= req_terminate_c;
            done_reg <= '0';
            addr  <= (others => '0');
            read_data <= (others => '0');
            block_valid <= '0';
            msg_block_buf <= (others => '0');
            WORDS_IN_BLOCK_COUNTER <= (others => '0');
            BLOCKS_COUNTER <= (others => '0');
        elsif(rising_edge(clk)) then
            case CURRENT_STATE is
                when RESET =>
                    bus_req_reg <= req_terminate_c;
                    done_reg <= '0';
                    addr  <= (others => '0');
                    read_data  <= (others => '0');
                    block_valid <= '0';
                    msg_block_buf <= (others => '0');
                    WORDS_IN_BLOCK_COUNTER <= (others => '0');
                    BLOCKS_COUNTER <= (others => '0');
                when IDLE =>
                    bus_req_reg <= req_terminate_c;
                    done_reg <= '0';
                    addr  <= (others => '0');
                    read_data  <= (others => '0');
                    block_valid <= '0';
                    msg_block_buf <= (others => '0');
                    -- wait for start signal
                when CHECK_INPUT_END =>
                    -- do nothing, only select next state 
                when MEM_REQ =>
                    bus_req_reg.addr  <= std_ulogic_vector(unsigned(base_io_bootrom_c) + unsigned(addr));
                    bus_req_reg.data  <= (others => '0');
                    bus_req_reg.ben   <= (others => '1');
                    bus_req_reg.stb   <= '1';
                    bus_req_reg.rw    <= '0';
                    bus_req_reg.src   <= '0';
                    bus_req_reg.priv  <= '0';
                    bus_req_reg.debug <= '0';
                    bus_req_reg.amo   <= '0';
                    bus_req_reg.amoop <= (others => '0');
                    bus_req_reg.burst <= '0';
                    bus_req_reg.lock  <= '0';
                    bus_req_reg.fence <= '0';
                when MEM_READ =>
                    -- Deassert stb, hold all other signals stable
                    if bus_rsp_i.ack = '1' then
                        bus_req_reg.stb <= '0';
                        read_data <= std_ulogic_vector(bus_rsp_i.data);
                    end if;
                when CHECK_FULL_BLOCK =>
                    addr <= std_ulogic_vector(unsigned(addr) + 4);
                    for i in 0 to 3 loop
                        for j in 0 to 7 loop
                            msg_block_buf(to_integer(32*unsigned(WORDS_IN_BLOCK_COUNTER) + 8*i + j)) <= read_data(8*i +(7-j)); 
                        end loop;
                    end loop;
                    if (unsigned(WORDS_IN_BLOCK_COUNTER) = unsigned(WORDS_IN_BLOCK_COUNT_LIMIT)-1) then
                        
                    else
                        WORDS_IN_BLOCK_COUNTER <= std_ulogic_vector(unsigned(WORDS_IN_BLOCK_COUNTER) + 1);
                    end if;
                when SEND_BLOCK =>
                    if (block_waiting = '1') then
                        block_valid <= '1';
                        msg_block_in <= msg_block_buf;
                        msg_block_buf <= (others => '0');
                        BLOCKS_COUNTER <= std_ulogic_vector(unsigned(BLOCKS_COUNTER) + 1);
                    end if;
                when CHECK_PROGRESS =>
                    block_valid <= '0';
                    if (block_process = '1') then
                        WORDS_IN_BLOCK_COUNTER <= (others => '0');
                    end if;
                when PAD_ONE_BIT =>
                    msg_block_buf(to_integer(32*unsigned(WORDS_IN_BLOCK_COUNTER))) <= '1';
                when CHECK_LAST_BLOCK =>
                    -- do nothing, only select next state
                when SEND_BLOCK_AFTER_PAD =>
                    if (block_waiting = '1') then
                        block_valid <= '1';
                        msg_block_in <= msg_block_buf;
                        msg_block_buf <= (others => '0');
                        BLOCKS_COUNTER <= std_ulogic_vector(unsigned(BLOCKS_COUNTER) + 1);
                    end if;
                when CHECK_PROGRESS_AFTER_PAD =>
                    block_valid <= '0';
                    if (block_process = '1') then
                        WORDS_IN_BLOCK_COUNTER <= (others => '0');
                    end if;
                when ADD_TAIL =>
                    for i in 0 to 63 loop
                        msg_block_buf(14*32 + i) <= hash_tail(63-i);
                    end loop;
                when DONE_STATE =>
                    bus_req_reg.stb <= '0';
                    if finished = '1' then
                        done_reg <= '1';
                    end if;
            end case;
        end if;
    end process;

    bus_req_o <= bus_req_reg;
    done <= done_reg;
    n_blocks <= std_ulogic_vector(shift_right(unsigned(words_to_read) + to_unsigned(2, words_to_read'length) , 4) + to_unsigned(1, words_to_read'length)); --padded blocks to hash
    hash_tail <= std_ulogic_vector("000000000000000000000000000" & unsigned(words_to_read) & "00000"); --bit from 32 bit words

end architecture;