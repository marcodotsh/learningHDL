library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neorv32_secure_boot_serial_adder is
  generic (
    WIDTH : integer := 2050;
    CHUNK_SIZE : integer := 32
  );
  port (
    clk_i    : in std_ulogic;
    rst_i    : in std_ulogic;
    start_i  : in std_ulogic;
    add_sub_i: in std_ulogic; -- '0' for add, '1' for sub
    a_i      : in std_ulogic_vector(WIDTH - 1 downto 0);
    b_i      : in std_ulogic_vector(WIDTH - 1 downto 0);
    s_o      : out std_ulogic_vector(WIDTH - 1 downto 0);
    done_o   : out std_ulogic
  );
end neorv32_secure_boot_serial_adder;

architecture neorv32_secure_boot_serial_adder_rtl of neorv32_secure_boot_serial_adder is

  type state_t is (IDLE, RUN, DONE);
  signal state : state_t;

  constant NUM_CHUNKS   : integer := (WIDTH + CHUNK_SIZE - 1) / CHUNK_SIZE;
  constant PADDED_WIDTH : integer := NUM_CHUNKS * CHUNK_SIZE;

  signal s_reg : unsigned(PADDED_WIDTH - 1 downto 0);
  signal chunk_index : integer range 0 to NUM_CHUNKS - 1;
  signal carry       : std_ulogic;

begin

  process(clk_i, rst_i)
    variable a_chunk, b_chunk_mod : unsigned(CHUNK_SIZE - 1 downto 0);
    variable sum_chunk            : unsigned(CHUNK_SIZE downto 0);
  begin
    if rst_i = '1' then
      state       <= IDLE;
      s_reg       <= (others => '0');
      chunk_index <= 0;
      carry       <= '0';
      done_o      <= '0';
    elsif rising_edge(clk_i) then
      done_o <= '0';
      case state is
        when IDLE =>
          if start_i = '1' then
            s_reg <= (others => '0');
            chunk_index <= 0;
            carry       <= add_sub_i; -- Start with carry=1 for subtraction
            state       <= RUN;
          end if;

        when RUN =>
          -- Get current chunks directly from inputs
          a_chunk := resize(unsigned(a_i), PADDED_WIDTH)((chunk_index + 1) * CHUNK_SIZE - 1 downto chunk_index * CHUNK_SIZE);
          b_chunk_mod := resize(unsigned(b_i), PADDED_WIDTH)((chunk_index + 1) * CHUNK_SIZE - 1 downto chunk_index * CHUNK_SIZE);

          -- Modify B for subtraction
          if add_sub_i = '1' then
            b_chunk_mod := not b_chunk_mod;
          end if;

          -- Perform chunk addition
          sum_chunk := resize(a_chunk, CHUNK_SIZE + 1) +
                       resize(b_chunk_mod, CHUNK_SIZE + 1) +
                       resize(unsigned'('0' & carry), CHUNK_SIZE + 1);

          s_reg((chunk_index + 1) * CHUNK_SIZE - 1 downto chunk_index * CHUNK_SIZE) <= sum_chunk(CHUNK_SIZE - 1 downto 0);
          carry <= sum_chunk(CHUNK_SIZE);

          if chunk_index = NUM_CHUNKS - 1 then
            state <= DONE;
          else
            chunk_index <= chunk_index + 1;
          end if;

        when DONE =>
          done_o <= '1';
          state  <= IDLE;

      end case;
    end if;
  end process;

  s_o <= std_ulogic_vector(s_reg(WIDTH - 1 downto 0));

end neorv32_secure_boot_serial_adder_rtl;
