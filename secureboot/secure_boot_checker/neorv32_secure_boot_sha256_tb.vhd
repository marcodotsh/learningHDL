-- Testbench for neorv32_boot_rom: reads first 10 32-bit words

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.neorv32_package.all;
use work.neorv32_bootloader_image.all;
entity neorv32_secure_boot_sha256_tb is
end entity;

architecture neorv32_secure_boot_sha256_tb of neorv32_secure_boot_sha256_tb is
  signal clk_i           : std_ulogic                     := '0';
  signal rstn_i          : std_ulogic                     := '0';
  signal start_i         : std_ulogic                     := '0';
  signal words_to_read_i : std_ulogic_vector(31 downto 0) := x"000003dd";
  signal bus_req_wire    : bus_req_t;
  signal bus_rsp_wire    : bus_rsp_t;
  signal done_o          : std_ulogic;
  signal hash_o          : std_ulogic_vector(255 downto 0);

  function to_hstring(slv : std_ulogic_vector) return string is
    variable result         : string(1 to slv'length/4);
    variable v              : std_ulogic_vector(3 downto 0);
    variable idx            : integer := 1;
    variable i              : integer := slv'left;
  begin
    while i >= slv'right loop
      v := slv(i downto i - 3);
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
        when others => result(idx) := 'F';
      end case;
      idx := idx + 1;
      i   := i - 4;
    end loop;
    return result;
  end function;

  -- Dummy ROM for testbench
  constant tb_rom_words_c : integer := 256; -- enough for all test cases
  type tb_rom_array_t is array(0 to tb_rom_words_c - 1) of std_ulogic_vector(31 downto 0);
  signal tb_rom : tb_rom_array_t := (others => (others => '0'));

  -- Helper to initialize ROM for test cases
  procedure fill_rom(variable rom : inout tb_rom_array_t; data : std_ulogic_vector; words : integer) is
  begin
    for i in 0 to tb_rom_words_c - 1 loop
      if i < words then
        rom(i) := data;
      else
        rom(i) := (others => '0');
      end if;
    end loop;
  end procedure;

  -- Helper to run a single test case
  procedure run_test(
    variable v_rom : in tb_rom_array_t;
    words          : integer;
    data           : std_ulogic_vector;
    msg            : string
  ) is
  begin
    -- This procedure only prepares the ROM content, actual signal assignments are done in the process.
    -- No signal assignments here to avoid multiple drivers and shadowing.
    null;
  end procedure;

  -- Dummy ROM signals
  signal tb_rom_rdata : std_ulogic_vector(31 downto 0);
  signal tb_rom_rden  : std_ulogic := '0';

  -- ROM select signal: '0' = dummy ROM, '1' = original boot ROM
  signal tb_use_boot_rom : std_ulogic := '0';

  -- Signals for original boot ROM
  signal boot_rom_rsp_wire : bus_rsp_t;

begin
  -- Clock generation
  clk_process : process
  begin
    clk_i <= '0';
    wait for 5 ns;
    clk_i <= '1';
    wait for 5 ns;
  end process;

  -- Dummy ROM process (replaces neorv32_boot_rom for most tests)
  tb_rom_process : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if bus_req_wire.stb = '1' then
        tb_rom_rdata <= tb_rom(to_integer(unsigned(bus_req_wire.addr(9 downto 2))));
        tb_rom_rden  <= '1';
      else
        tb_rom_rden <= '0';
      end if;
    end if;
  end process;

  -- Original boot ROM instantiation (for last test)
  boot_rom : entity work.neorv32_boot_rom
    port map
    (
      clk_i     => clk_i,
      rstn_i    => rstn_i,
      bus_req_i => bus_req_wire,
      bus_rsp_o => boot_rom_rsp_wire
    );

  -- Bus response mux
  bus_rsp_wire.data <= boot_rom_rsp_wire.data when tb_use_boot_rom = '1' else
  tb_rom_rdata when tb_rom_rden = '1' else
  (others => '0');
  bus_rsp_wire.ack <= boot_rom_rsp_wire.ack when tb_use_boot_rom = '1' else
  tb_rom_rden;
  bus_rsp_wire.err <= boot_rom_rsp_wire.err when tb_use_boot_rom = '1' else
  '0';

  -- DUT instantiation
  dut : entity work.neorv32_secure_boot_boot_rom_hasher
    port map
    (
      clk_i           => clk_i,
      rst_i           => rstn_i,
      start_i         => start_i,
      words_to_read_i => words_to_read_i,
      bus_rsp_i       => bus_rsp_wire,
      bus_req_o       => bus_req_wire,
      done_o          => done_o,
      hash_o          => hash_o
    );

  -- Main test process
  test_process : process
    variable v_rom : tb_rom_array_t;
  begin
    -- Use dummy ROM for all but last test
    tb_use_boot_rom <= '0';

    -- Test 1: 0-word message
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait for 10 ns;
    fill_rom(v_rom, x"00000000", 0);
    for i in 0 to tb_rom_words_c - 1 loop tb_rom(i) <= v_rom(i);
    end loop;
    words_to_read_i <= std_ulogic_vector(to_unsigned(0, 32));
    start_i         <= '1';
    wait for 10 ns;
    start_i <= '0';
    wait until done_o = '1';
    report "Hash 0-word message: " & to_hstring(hash_o);
    assert hash_o = x"E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"
    report "Hash 0-word message: assertion failed!" severity error;
    wait for 10 ns;

    -- Test 2: 1-word message
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait for 10 ns;
    fill_rom(v_rom, x"AAAAAAAA", 1);
    for i in 0 to tb_rom_words_c - 1 loop tb_rom(i) <= v_rom(i);
    end loop;
    words_to_read_i <= std_ulogic_vector(to_unsigned(1, 32));
    start_i         <= '1';
    wait for 10 ns;
    start_i <= '0';
    wait until done_o = '1';
    report "Hash 1-word message: " & to_hstring(hash_o);
    assert hash_o = x"DBED14CEB001D110D766B9013D3B5BBFFAD6915475A9BA07932D2AC057944C04"
    report "Hash 1-word message: assertion failed!" severity error;
    wait for 10 ns;

    -- Test 3: 13-word message (single block, padding+length fits)
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait for 10 ns;
    fill_rom(v_rom, x"AAAAAAAA", 13);
    for i in 0 to tb_rom_words_c - 1 loop tb_rom(i) <= v_rom(i);
    end loop;
    words_to_read_i <= std_ulogic_vector(to_unsigned(13, 32));
    start_i         <= '1';
    wait for 10 ns;
    start_i <= '0';
    wait until done_o = '1';
    report "Hash 13-word message: " & to_hstring(hash_o);
    assert hash_o = x"C333D81E26277E08603A370D0F5A80E9AC1BEEA75D59B7FED0935F7C5B7B28F6"
    report "Hash 13-word message: assertion failed!" severity error;
    wait for 10 ns;

    -- Test 4: 14-word message (padding split, needs 2 blocks)
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait for 10 ns;
    fill_rom(v_rom, x"AAAAAAAA", 14);
    for i in 0 to tb_rom_words_c - 1 loop tb_rom(i) <= v_rom(i);
    end loop;
    words_to_read_i <= std_ulogic_vector(to_unsigned(14, 32));
    start_i         <= '1';
    wait for 10 ns;
    start_i <= '0';
    wait until done_o = '1';
    report "Hash 14-word message: " & to_hstring(hash_o);
    assert hash_o = x"d464bb04abbc80a2254cd4ad0f3356f1b70b5b6390085b193edcd291f065b01e"
    report "Hash 14-word message: assertion failed!" severity error;
    wait for 10 ns;

    -- Test 5: 16-word message (padding+length in 2nd block)
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait for 10 ns;
    fill_rom(v_rom, x"AAAAAAAA", 16);
    for i in 0 to tb_rom_words_c - 1 loop tb_rom(i) <= v_rom(i);
    end loop;
    words_to_read_i <= std_ulogic_vector(to_unsigned(16, 32));
    start_i         <= '1';
    wait for 10 ns;
    start_i <= '0';
    wait until done_o = '1';
    report "Hash 16-word message: " & to_hstring(hash_o);
    assert hash_o = x"693E5F0F347A5D70ACBB7BAAAB9BEB988301B3E9588E32C73D7DCDFB7B2C4604"
    report "Hash 16-word message: assertion failed!" severity error;
    wait for 10 ns;

    -- Switch to original boot ROM for last test
    tb_use_boot_rom <= '1';
    wait for 10 ns;

    -- Original test: full bootloader
    rstn_i <= '0';
    wait for 20 ns;
    rstn_i <= '1';
    wait for 10 ns;
    words_to_read_i <= x"00000066";
    start_i         <= '1';
    wait for 10 ns;
    start_i <= '0';
    wait until done_o = '1';
    report "Hash full bootloader: " & to_hstring(hash_o);
    assert hash_o(255 downto 0) = x"DFD2154ED878444AA8697FB19ED3A87653F3269BC5BEE2D4BFCE50925E10E89A"
    report "Hash full bootloader: assertion failed!" severity error;

    wait;
  end process;

end architecture;
