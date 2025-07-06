-- Testbench for neorv32_boot_rom: reads first 10 32-bit words

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.neorv32_package.all;
use work.neorv32_bootloader_image.all;


entity sha256_tb is
end entity;

architecture tb of sha256_tb is
  signal clk    : std_ulogic := '0';
  signal rstn   : std_ulogic := '0';
  signal start  : std_ulogic := '0';
  signal words_to_read : std_ulogic_vector(31 downto 0) := x"000003dd";
  signal bus_req : bus_req_t;
  signal bus_rsp : bus_rsp_t;
  signal done    : std_ulogic;
  signal hash_o  : std_ulogic_vector(255 downto 0);

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

begin
  -- Clock generation
  clk_process : process
  begin
    clk <= '0'; wait for 5 ns;
    clk <= '1'; wait for 5 ns;
  end process;

  -- Reset generation
  rst_process: process
  begin
    rstn <= '0';
    wait for 20 ns;
    rstn <= '1';
    wait for 20 ns;
    wait;
  end process;

  -- Start generation
  start_process: process
  begin
    wait for 50 ns;
    start <= '1';
    wait;
  end process;

  -- Wait result
  wait_result: process
  begin
    wait until done = '1';
    report "Computed hash: " & to_hstring(hash_o);
    wait;
  end process;

  -- Boot rom instantiation
  boot_rom: entity work.neorv32_boot_rom
    port map (
      clk_i     => clk,
      rstn_i    => rstn,
      bus_req_i => bus_req,
      bus_rsp_o => bus_rsp
    );

  -- DUT instantiation
  dut: entity work.neorv32_boot_rom_hasher
    port map(
        clk        => clk,
        rst        => rstn,
        start      => start,
        words_to_read => words_to_read,
        bus_rsp_i  => bus_rsp,
        bus_req_o  => bus_req,
        done => done,
        hash_o => hash_o
    );

end architecture;
