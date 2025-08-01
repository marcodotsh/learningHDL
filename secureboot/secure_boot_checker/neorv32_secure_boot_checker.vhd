library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.neorv32_package.all;
use work.neorv32_secure_boot_checker_verification_image.all;
use work.neorv32_bootloader_image.all; -- this file is generated by the image generator

entity neorv32_secure_boot_checker is
  port (
    clk_i      : in std_ulogic; -- global clock line
    rstn_i     : in std_ulogic; -- async reset, low-active
    bus_req_o  : out bus_req_t; -- bus request
    bus_rsp_i  : in bus_rsp_t; -- bus response
    cpu_rstn_o : out std_ulogic -- output cpu reset signal
  );
end neorv32_secure_boot_checker;

architecture neorv32_secure_boot_checker_rtl of neorv32_secure_boot_checker is

  -- The size of 288 is for demonstration only on a small FPGA, please use at leas 2048 bits for a secure deployment
  constant RSA_KEY_SIZE : integer := 288;
  -- determine physical ROM size in WORDS (expand to next power of two) --
  constant boot_rom_size_index_c : natural                         := index_size_f((bootloader_init_size_c/4)); -- address with (words)
  constant boot_rom_size_c       : natural range 0 to iodev_size_c := (2 ** boot_rom_size_index_c); -- physical size in words

  type state_t is (
    IDLE,
    READ_SIGNATURE_REQ,
    READ_SIGNATURE_RSP,
    START_RSA,
    READ_BOOTLOADER_LENGTH_REQ,
    READ_BOOTLOADER_LENGTH_RSP,
    START_HASHER,
    WAIT_FOR_COMPONENTS,
    CHECK_RESULTS,
    VALID_STATE,
    INVALID_STATE
  );

  signal current_state, next_state : state_t;

  -- RSA component signals
  signal rsa_start_reg : std_ulogic;
  signal rsa_done_wire : std_ulogic;
  type word_array_t is array (0 to RSA_KEY_SIZE/32 - 1) of std_ulogic_vector(31 downto 0);
  signal rsa_base_reg    : word_array_t;
  signal rsa_result_wire : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);

  -- Hasher component signals
  signal hasher_start_reg         : std_ulogic;
  signal hasher_done_wire         : std_ulogic;
  signal hasher_words_to_read_reg : std_ulogic_vector(31 downto 0);
  signal hasher_hash_wire         : std_ulogic_vector(255 downto 0);

  -- Memory access signals
  signal addr_cnt_reg        : natural range 0 to RSA_KEY_SIZE/32 - 1;
  signal length_reg          : std_ulogic_vector(31 downto 0);
  signal bus_req_reg         : bus_req_t;
  signal hasher_bus_req_wire : bus_req_t;

  signal cpu_rstn_wire : std_ulogic;
  signal rsa_base_wire : std_ulogic_vector(RSA_KEY_SIZE - 1 downto 0);

begin

  gen_flatten_rsa_base : for i in 0 to RSA_KEY_SIZE/32 - 1 generate
    rsa_base_wire((i + 1) * 32 - 1 downto i * 32) <= rsa_base_reg(i);
  end generate;

  rsa_inst : entity work.neorv32_secure_boot_rsa
    generic map(
      RSA_KEY_SIZE => RSA_KEY_SIZE
    )
    port map
    (
      clk_i      => clk_i,
      rstn_i     => rstn_i,
      start_i    => rsa_start_reg,
      base_i     => rsa_base_wire,
      exponent_i => rsa_public_exponent_c,
      modulus_i  => rsa_modulus_c,
      result_o   => rsa_result_wire,
      done_o     => rsa_done_wire
    );

  hasher_inst : entity work.neorv32_secure_boot_boot_rom_hasher
    port map
    (
      clk_i           => clk_i,
      rst_i           => rstn_i,
      start_i         => hasher_start_reg,
      words_to_read_i => hasher_words_to_read_reg,
      bus_rsp_i       => bus_rsp_i,
      bus_req_o       => hasher_bus_req_wire,
      done_o          => hasher_done_wire,
      hash_o          => hasher_hash_wire
    );

  process (clk_i, rstn_i)
  begin
    if rstn_i = '0' then
      current_state <= IDLE;
    elsif rising_edge(clk_i) then
      current_state <= next_state;
    end if;
  end process;

  process (current_state, rstn_i, bus_rsp_i, rsa_done_wire, hasher_done_wire, rsa_result_wire, hasher_hash_wire, addr_cnt_reg)
  begin
    next_state <= current_state;
    case current_state is
      when IDLE =>
        if rstn_i = '1' then
          next_state <= READ_SIGNATURE_REQ;
        end if;

      when READ_SIGNATURE_REQ =>
        next_state <= READ_SIGNATURE_RSP;

      when READ_SIGNATURE_RSP =>
        if bus_rsp_i.ack = '1' then
          if addr_cnt_reg = (RSA_KEY_SIZE/32) - 1 then
            next_state <= START_RSA;
          else
            next_state <= READ_SIGNATURE_REQ;
          end if;
        end if;

      when START_RSA =>
        next_state <= READ_BOOTLOADER_LENGTH_REQ;

      when READ_BOOTLOADER_LENGTH_REQ =>
        next_state <= READ_BOOTLOADER_LENGTH_RSP;

      when READ_BOOTLOADER_LENGTH_RSP =>
        if bus_rsp_i.ack = '1' then
          next_state <= START_HASHER;
        end if;

      when START_HASHER =>
        next_state <= WAIT_FOR_COMPONENTS;

      when WAIT_FOR_COMPONENTS =>
        if rsa_done_wire = '1' and hasher_done_wire = '1' then
          next_state <= CHECK_RESULTS;
        end if;

      when CHECK_RESULTS =>
        if rsa_result_wire(255 downto 0) = hasher_hash_wire then
          next_state <= VALID_STATE;
        else
          next_state <= INVALID_STATE;
        end if;

      when VALID_STATE =>
        next_state <= VALID_STATE;

      when INVALID_STATE =>
        next_state <= INVALID_STATE;

    end case;
  end process;

  process (clk_i, rstn_i)
  begin
    if rstn_i = '0' then
      rsa_start_reg            <= '0';
      hasher_start_reg         <= '0';
      addr_cnt_reg             <= 0;
      rsa_base_reg             <= (others => (others => '0'));
      length_reg               <= (others => '0');
      bus_req_reg              <= req_terminate_c;
      hasher_words_to_read_reg <= (others => '0');
    elsif rising_edge(clk_i) then
      case current_state is
        when IDLE =>
          addr_cnt_reg <= 0;
          rsa_base_reg <= (others => (others => '0'));
          length_reg   <= (others => '0');
          bus_req_reg  <= req_terminate_c;

        when READ_SIGNATURE_REQ =>
          bus_req_reg.addr <= std_ulogic_vector(to_unsigned((boot_rom_size_c - (RSA_KEY_SIZE/32) - 1 + addr_cnt_reg) * 4, 32));
          bus_req_reg.stb  <= '1';

        when READ_SIGNATURE_RSP =>
          if bus_rsp_i.ack = '1' then
            bus_req_reg.stb                                    <= '0';
            rsa_base_reg((RSA_KEY_SIZE/32) - 1 - addr_cnt_reg) <= bus_rsp_i.data; -- Write directly to rsa_base_reg
            if addr_cnt_reg < (RSA_KEY_SIZE/32) - 1 then
              addr_cnt_reg <= addr_cnt_reg + 1;
            end if;
          end if;

        when START_RSA =>
          rsa_start_reg <= '1';

        when READ_BOOTLOADER_LENGTH_REQ =>
          bus_req_reg.addr <= std_ulogic_vector(to_unsigned((boot_rom_size_c - 1) * 4, 32));
          bus_req_reg.stb  <= '1';

        when READ_BOOTLOADER_LENGTH_RSP =>
          if bus_rsp_i.ack = '1' then
            bus_req_reg.stb <= '0';
            length_reg      <= bus_rsp_i.data;
          end if;

        when START_HASHER =>
          hasher_start_reg         <= '1';
          hasher_words_to_read_reg <= length_reg;

        when WAIT_FOR_COMPONENTS =>

        when CHECK_RESULTS =>

        when VALID_STATE =>
          -- release cpu reset cpu_rstn_wire
        when INVALID_STATE =>
          -- do not release cpu reset cpu_rstn_wire
      end case;
    end if;
  end process;

  with current_state
  select bus_req_o <= bus_req_reg when READ_SIGNATURE_REQ | READ_SIGNATURE_RSP |
  READ_BOOTLOADER_LENGTH_REQ | READ_BOOTLOADER_LENGTH_RSP,
  req_terminate_c when VALID_STATE,
  hasher_bus_req_wire when others;

  cpu_rstn_wire <= '1' when current_state = VALID_STATE else
    '0';

  cpu_rstn_o <= cpu_rstn_wire;

end neorv32_secure_boot_checker_rtl;
