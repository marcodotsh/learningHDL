library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity neorv32_secure_boot_mod_mult_tb is
end neorv32_secure_boot_mod_mult_tb;

architecture neorv32_secure_boot_mod_mult_tb of neorv32_secure_boot_mod_mult_tb is
  component neorv32_secure_boot_mod_mult is
    port (
      clk_i    : in std_ulogic;
      rst_i    : in std_ulogic;
      a_i      : in std_ulogic_vector(2047 downto 0);
      b_i      : in std_ulogic_vector(2047 downto 0);
      n_i      : in std_ulogic_vector(2047 downto 0);
      start_i  : in std_ulogic;
      result_o : out std_ulogic_vector(2047 downto 0);
      done_o   : out std_ulogic
    );
  end component;

  signal clk, reset, start, done : std_logic := '0';
  signal a, b, n, result         : std_ulogic_vector(2047 downto 0);
  constant CLK_PERIOD            : time := 10 ns;

  function to_slv_padded(num : natural; size : natural) return std_ulogic_vector is
    variable res     : std_ulogic_vector(size - 1 downto 0) := (others => '0');
    variable num_vec : std_ulogic_vector(31 downto 0);
  begin
    num_vec          := std_ulogic_vector(to_unsigned(num, 32));
    res(31 downto 0) := num_vec;
    return res;
  end function;
begin
  uut : neorv32_secure_boot_mod_mult
  port map
  (
    clk_i    => clk,
    rst_i    => reset,
    a_i      => a,
    b_i      => b,
    n_i      => n,
    start_i  => start,
    result_o => result,
    done_o   => done
  );

  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  stim_proc : process
    function to_slv(num : natural; size : natural) return std_ulogic_vector is
    begin
      return std_ulogic_vector(to_unsigned(num, size));
    end function;
  begin
    reset <= '1';
    wait for CLK_PERIOD;
    reset <= '0';
    wait for CLK_PERIOD;

    -- Test 1: 5 * 7 mod 11 = 35 mod 11 = 2
    a     <= to_slv_padded(5, 2048);
    b     <= to_slv_padded(7, 2048);
    n     <= to_slv_padded(11, 2048);
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    while done /= '1' loop
      wait for CLK_PERIOD;
    end loop;
    wait for CLK_PERIOD;
    assert result(31 downto 0) = to_slv(2, 32)
    report "Test 1 failed: Expected 2, got " & integer'image(to_integer(unsigned(result(31 downto 0))))
      severity error;
    report "Test 1 passed";

    -- Test 2: 0 * 0 mod 1 = 0
    a     <= to_slv_padded(0, 2048);
    b     <= to_slv_padded(0, 2048);
    n     <= to_slv_padded(1, 2048);
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    while done /= '1' loop
      wait for CLK_PERIOD;
    end loop;
    wait for CLK_PERIOD;
    assert result(31 downto 0) = to_slv(0, 32)
    report "Test 2 failed: Expected 0, got " & integer'image(to_integer(unsigned(result(31 downto 0))))
      severity error;
    report "Test 2 passed";

    -- Test 3: 2 * 3 mod 5 = 6 mod 5 = 1
    a     <= to_slv_padded(2, 2048);
    b     <= to_slv_padded(3, 2048);
    n     <= to_slv_padded(5, 2048);
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    while done /= '1' loop
      wait for CLK_PERIOD;
    end loop;
    wait for CLK_PERIOD;
    assert result(31 downto 0) = to_slv(1, 32)
    report "Test 3 failed: Expected 1, got " & integer'image(to_integer(unsigned(result(31 downto 0))))
      severity error;
    report "Test 3 passed";

    -- Test 4: 123 * 456 mod 789 = (56088 mod 789) = 69
    a     <= to_slv_padded(123, 2048);
    b     <= to_slv_padded(456, 2048);
    n     <= to_slv_padded(789, 2048);
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    while done /= '1' loop
      wait for CLK_PERIOD;
    end loop;
    wait for CLK_PERIOD;
    assert result(31 downto 0) = to_slv(69, 32)
    report "Test 4 failed: Expected 69, got " & integer'image(to_integer(unsigned(result(31 downto 0))))
      severity error;
    report "Test 4 passed";

    -- Test 5: Large number test (2^10-1)*(2^10-1) mod (2^10) = 1023*1023 mod 1024 = 1
    a     <= to_slv_padded(1023, 2048);
    b     <= to_slv_padded(1023, 2048);
    n     <= to_slv_padded(1024, 2048);
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    while done /= '1' loop
      wait for CLK_PERIOD;
    end loop;
    wait for CLK_PERIOD;
    assert result(31 downto 0) = to_slv(1, 32)
    report "Test 5 failed: Expected 1, got " & integer'image(to_integer(unsigned(result(31 downto 0))))
      severity error;
    report "Test 5 passed";

    -- Test 6: 
    a     <= x"0f65f1784631153d25938ef6f65683e780dcdb65dfba7b4eb5302d9915c3e96ee55d997794816965a322009ba908c72e986c710bd533936191d55f96a994e40931e15b801ec5e1808125161a24b2ba7d598ac39cbec0c1903b4e7d861836fa2901af7f894ba18150d8c0803a5088269f17232ea541f469553cd87f8a52d6cd5076bc7a14ce305962b06240169891e4b5856d75dd945660f93fa385b4edf89f98d6b2cf9b62fd32d06ac13f462cdce442364b21f29671b329c01ab3615d9fff34e481dfb569b5671b918d7a995cab9d41eaa87aef11ba12467017ae52ce1bb3752c1c9f3722a142cc3739295e179f5296d2c68cde8537a27d9a41789239a7865e";
    b     <= x"0f65f1784631153d25938ef6f65683e780dcdb65dfba7b4eb5302d9915c3e96ee55d997794816965a322009ba908c72e986c710bd533936191d55f96a994e40931e15b801ec5e1808125161a24b2ba7d598ac39cbec0c1903b4e7d861836fa2901af7f894ba18150d8c0803a5088269f17232ea541f469553cd87f8a52d6cd5076bc7a14ce305962b06240169891e4b5856d75dd945660f93fa385b4edf89f98d6b2cf9b62fd32d06ac13f462cdce442364b21f29671b329c01ab3615d9fff34e481dfb569b5671b918d7a995cab9d41eaa87aef11ba12467017ae52ce1bb3752c1c9f3722a142cc3739295e179f5296d2c68cde8537a27d9a41789239a7865e";
    n     <= x"A694B13587D61A047502D9E8EDC0E39E89D33DA16D226249A4EE7B504ECB07837BE3597E2AA11874E1829497B44D9BBA99006B122AAADFBB2D47F4636B124E735C7F174900B6BFC74EBA94B5D3CB94BF5581C29F56E2696C28AB1DBF3380DCB3F8161431F80D8E78636C3EDAC88C95F5A1A7574912489D861190F6BF42B97A4CE244A013C773D8BACFB4B4D55CB31F5A0718FD64673DC2EF7A04149724BFA0586B2C45A3BF3CF0919B089EA987DBC64999C4A775C2CF9A7EA3505285899209ADF0BD208995B4A6048E24DCAE6E91B3BE62A11373690DF0C3C2C7E041EEFBA0AB0503E3584123D7D9D39CE2564938E9296BB276B28ABE6CE5B9EFBD73D2E12263";
    start <= '1';
    wait for CLK_PERIOD;
    start <= '0';

    while done /= '1' loop
      wait for CLK_PERIOD;
    end loop;
    wait for CLK_PERIOD;
    assert result = x"6deb5d849fccdaf8942c5bd88d1454be7a83556879268553eb2b6047a83c12755780e71c35214a122ca1d5a85eb0a4da9ad8238f8f2677194e6a531ba2db0dd2e572132d9b1cee65e9560e330bbc9c423970ea8a9a4d6d335aad1b2a2653e33675a8308e336f0b6b2dc9c1da3afeadb8903a3930139c7a34153b16c4b138bcd0efab6926f2cb7e74a935a31bf9787f6ff6f74677725faa586828a25968929f53fe056cb17f887c2bd494f5ea7fefad971aa84dbac836214ebd7c1f0784a9303b7b131cbeee385e1add3153bdd4762bb10741439d2d354ebb13199d2a6fc8a4197df64878f6420dab16855cdb0484dc8bcc885b2926c298e332b728ac1fc723df"
    report "Test 6 failed: got " & integer'image(to_integer(unsigned(result(31 downto 0))))
      severity error;
    report "Test 6 passed";

    report "All tests completed";
    wait;
  end process;
end neorv32_secure_boot_mod_mult_tb;
