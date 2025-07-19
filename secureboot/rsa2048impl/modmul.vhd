library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_mult is
    Port (
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        a      : in  STD_LOGIC_VECTOR(2047 downto 0);
        b      : in  STD_LOGIC_VECTOR(2047 downto 0);
        n      : in  STD_LOGIC_VECTOR(2047 downto 0);
        start  : in  STD_LOGIC;
        result : out STD_LOGIC_VECTOR(2047 downto 0);
        done   : out STD_LOGIC
    );
end mod_mult;

architecture Behavioral of mod_mult is
    type state_type is (IDLE, LOAD, PROCESS_1, PROCESS_2, PROCESS_3, DONE_STATE);
    signal state : state_type := IDLE;
    
    signal a_reg, b_reg, n_reg, result_reg : unsigned(2047 downto 0);
    signal index : integer range 0 to 2047 := 2047;
    signal temp_2050, temp1_2050 : unsigned(2049 downto 0);
begin
    -- State transition process
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= LOAD;
                    end if;
                when LOAD =>
                    state <= PROCESS_1;
                when PROCESS_1 =>
                    state <= PROCESS_2;
                when PROCESS_2 =>
                    state <= PROCESS_3;
                when PROCESS_3 =>
                    if index = 0 then
                        state <= DONE_STATE;
                    else
                        state <= PROCESS_1;
                    end if;
                when DONE_STATE =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- State logic and data path
    process(clk)
        variable temp_var : unsigned(2049 downto 0);
        variable b_i_var : std_logic;
        variable sub_res : unsigned(2049 downto 0);
    begin
        if rising_edge(clk) then
            done <= '0';
            case state is
                when IDLE =>
                    result_reg <= (others => '0');
                    index <= 2047;
                    
                when LOAD =>
                    a_reg <= unsigned(a);
                    b_reg <= unsigned(b);
                    n_reg <= unsigned(n);
                    
                when PROCESS_1 =>
                    b_i_var := b_reg(index);
                    temp_var := resize(result_reg, 2050) sll 1;
                    if b_i_var = '1' then
                        temp_2050 <= temp_var + resize(a_reg, 2050);
                    else
                        temp_2050 <= temp_var;
                    end if;
                    
                when PROCESS_2 =>
                    if temp_2050 >= resize(n_reg, 2050) then
                        temp1_2050 <= temp_2050 - resize(n_reg, 2050);
                    else
                        temp1_2050 <= temp_2050;
                    end if;
                    
                when PROCESS_3 =>
                    if temp1_2050 >= resize(n_reg, 2050) then
                        sub_res := temp1_2050 - resize(n_reg, 2050);
                        result_reg <= sub_res(2047 downto 0);
                    else
                        result_reg <= temp1_2050(2047 downto 0);
                    end if;
                    if index > 0 then
                        index <= index - 1;
                    end if;
                    
                when DONE_STATE =>
                    done <= '1';
                    
            end case;
        end if;
    end process;

    result <= std_logic_vector(result_reg);
end Behavioral;
