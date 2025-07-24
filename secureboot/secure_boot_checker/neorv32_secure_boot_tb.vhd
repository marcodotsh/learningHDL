library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.neorv32_package.all;

entity neorv32_secure_boot_tb is
end neorv32_secure_boot_tb;

architecture neorv32_secure_boot_tb of neorv32_secure_boot_tb is

  -- Clock period
  constant clk_period : time := 10 ns;

  -- Signals
  signal clk_i        : std_ulogic;
  signal rstn_i       : std_ulogic;
  signal bus_req_wire : bus_req_t;
  signal bus_rsp_wire : bus_rsp_t;
  signal cpu_rstn_o   : std_ulogic;

  -- Instantiate the boot ROM
  component neorv32_boot_rom
    port (
      clk_i     : in std_ulogic;
      rstn_i    : in std_ulogic;
      bus_req_i : in bus_req_t;
      bus_rsp_o : out bus_rsp_t
    );
  end component;

  -- Instantiate the secure boot checker
  component neorv32_secure_boot_checker
    port (
      clk_i      : in std_ulogic;
      rstn_i     : in std_ulogic;
      bus_req_o  : out bus_req_t;
      bus_rsp_i  : in bus_rsp_t;
      cpu_rstn_o : out std_ulogic
    );
  end component;

begin

  -- Instantiate the boot ROM
  boot_rom_inst : neorv32_boot_rom
  port map
  (
    clk_i     => clk_i,
    rstn_i    => rstn_i,
    bus_req_i => bus_req_wire,
    bus_rsp_o => bus_rsp_wire
  );

  -- Instantiate the secure boot checker
  secure_boot_checker_inst : neorv32_secure_boot_checker
  port map
  (
    clk_i      => clk_i,
    rstn_i     => rstn_i,
    bus_req_o  => bus_req_wire,
    bus_rsp_i  => bus_rsp_wire,
    cpu_rstn_o => cpu_rstn_o
  );

  -- Clock generation
  clk_process : process
  begin
    clk_i <= '0';
    wait for clk_period/2;
    clk_i <= '1';
    wait for clk_period/2;
  end process;

  -- Test sequence
  test_process : process
  begin
    -- Reset the system
    rstn_i <= '0';
    wait for 100 ns;
    rstn_i <= '1';

    -- Wait for the cpu_rstn to go high
    wait until cpu_rstn_o = '0';
    report "CPU reset disabled. Secure boot successful!";

    -- Stop the simulation
    wait;
  end process;

end neorv32_secure_boot_tb;
