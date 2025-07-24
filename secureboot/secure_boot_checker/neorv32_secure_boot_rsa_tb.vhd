library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neorv32_secure_boot_rsa_tb is
end neorv32_secure_boot_rsa_tb;

architecture neorv32_secure_boot_rsa_tb of neorv32_secure_boot_rsa_tb is

  constant RSA_KEY_SIZE : integer := 2048;

  component neorv32_secure_boot_rsa is
    generic (
      RSA_KEY_SIZE : integer := RSA_KEY_SIZE
    );
    port (
      clk_i      : in std_ulogic;
      rstn_i     : in std_ulogic;
      start_i    : in std_ulogic;
      base_i     : in std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);
      exponent_i : in std_ulogic_vector(19 downto 0);
      modulus_i  : in std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);
      result_o   : out std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);
      done_o     : out std_ulogic
    );
  end component;

  signal clk_i      : std_ulogic := '0';
  signal rstn_i     : std_ulogic := '0';
  signal start_i    : std_ulogic := '0';
  signal base_i     : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);
  signal exponent_i : std_ulogic_vector(19 downto 0);
  signal modulus_i  : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);
  signal result_o   : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);
  signal done_o     : std_ulogic;

  constant modulus_c             : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0) := x"A694B13587D61A047502D9E8EDC0E39E89D33DA16D226249A4EE7B504ECB07837BE3597E2AA11874E1829497B44D9BBA99006B122AAADFBB2D47F4636B124E735C7F174900B6BFC74EBA94B5D3CB94BF5581C29F56E2696C28AB1DBF3380DCB3F8161431F80D8E78636C3EDAC88C95F5A1A7574912489D861190F6BF42B97A4CE244A013C773D8BACFB4B4D55CB31F5A0718FD64673DC2EF7A04149724BFA0586B2C45A3BF3CF0919B089EA987DBC64999C4A775C2CF9A7EA3505285899209ADF0BD208995B4A6048E24DCAE6E91B3BE62A11373690DF0C3C2C7E041EEFBA0AB0503E3584123D7D9D39CE2564938E9296BB276B28ABE6CE5B9EFBD73D2E12263";
  constant signature_c           : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0) := x"0f65f1784631153d25938ef6f65683e780dcdb65dfba7b4eb5302d9915c3e96ee55d997794816965a322009ba908c72e986c710bd533936191d55f96a994e40931e15b801ec5e1808125161a24b2ba7d598ac39cbec0c1903b4e7d861836fa2901af7f894ba18150d8c0803a5088269f17232ea541f469553cd87f8a52d6cd5076bc7a14ce305962b06240169891e4b5856d75dd945660f93fa385b4edf89f98d6b2cf9b62fd32d06ac13f462cdce442364b21f29671b329c01ab3615d9fff34e481dfb569b5671b918d7a995cab9d41eaa87aef11ba12467017ae52ce1bb3752c1c9f3722a142cc3739295e179f5296d2c68cde8537a27d9a41789239a7865e";
  constant exponent_c            : std_ulogic_vector(19 downto 0)   := std_ulogic_vector(to_unsigned(65537, 20));
  constant expected_result_lsb_c : std_ulogic_vector(255 downto 0)  := x"0DB190968A7394EE9FB29BAA16ED4FA67AD745949A7B9A0D51779228E3373F18";

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

begin

  -- Instantiate the RSA_core module
  uut : neorv32_secure_boot_rsa
  generic map (
    RSA_KEY_SIZE => RSA_KEY_SIZE
  )
  port map
  (
    clk_i      => clk_i,
    rstn_i     => rstn_i,
    start_i    => start_i,
    base_i     => base_i,
    exponent_i => exponent_i,
    modulus_i  => modulus_i,
    result_o   => result_o,
    done_o     => done_o
  );

  -- Clock process
  clk_i <= not clk_i after 5 ns;

  -- Test process
  process
  begin
    -- Reset
    rstn_i <= '0';
    wait for 10 ns;
    rstn_i <= '1';
    wait for 10 ns;

    -- Test case
    base_i     <= signature_c;
    exponent_i <= exponent_c;
    modulus_i  <= modulus_c;
    start_i    <= '1';
    wait for 10 ns;
    start_i <= '0';

    wait until done_o = '1';
    report "Test 1 Result: " & to_hstring(result_o);
    assert result_o(255 downto 0) = expected_result_lsb_c
    report "Verification of last 256 bits failed!" severity failure;

    report "Verification of last 256 bits passed!" severity note;

    wait;
  end process;

end neorv32_secure_boot_rsa_tb;


