library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity cordic_tb is
--  Port ( );
end cordic_tb;

architecture Behavioral of cordic_tb is
constant input_size  : integer := 17;
constant output_size : integer := 16;
constant T : time := 20ms;

signal clk          : std_logic;
signal sin,cos      : std_logic_vector(output_size-1 downto 0);
signal angle        : std_logic_vector(input_size-1 downto 0);
signal start        : std_logic;
--signal done         : std_logic;
signal rst          : std_logic;
begin
uut: entity WORK.cordic_sin_cos(behavioral)
generic map (
    input_size_g => input_size,
    output_size_g => output_size 
)
 port map (
    clk           =>  clk,
    rst           =>  rst,
    start         =>  start,
    angle_in      =>  angle,
    sine_out      =>  sin,
    --done          => done,
    cosine_out    =>  cos
);

process
begin
   
    clk <= '1';
    wait for T/2;
    clk <= '0';
    wait for T/2;
end process;

process
begin
   
    start <= '0';
    wait for T/4;
    start <= '1';
    wait for T/4;
    start <= '0';
    wait for 1.75*T;
    start <= '1';
    wait for T/2;
    start <= '0';
    wait for 100*T;
end process;

rst<='1','0' after T/2;
process
begin

    angle <= "00010000110000010";
    wait until falling_edge(clk);
    wait for T;
    
    angle<="01000011000000100";
    wait until falling_edge(clk);
    wait for T/2;
    
    angle<="01110101010010010";
    wait until rising_edge(clk);
    
    angle <= "11100110110111101"; -- 30 degrees = 0.523 radians
    wait until rising_edge(clk);
    angle<="10111100111111100";
    wait until rising_edge(clk);
    angle<="10001010101101110";
    wait for 100*T;
    
end process;

--process
--begin
--    wait until clk='0';
        
--        angle <= "00010000110000010"; -- 30 degrees = 0.523 radians
         
--        wait for 17 * T; 
--        angle <= "00011001001000011"; -- 45 degrees = 0.758 radians
         
--        wait for 17 * T;
--        angle <= "00100001100000010"; -- 60 degrees = 1.047 radians
--        angle <= "00110010010001000"; -- 90 degrees = 1.571 radians
--        angle <= "01000011000000100"; -- 120 degrees = 2.094 radians
--        angle <= "01001011011001000"; -- 135 degrees = 2.356 radians
--        angle <= "01010011110001101"; -- 150 degrees = 2.618 radians
--        angle <= "01100100100000000"; -- 180 degrees = 3.141 radians
--        angle <= "01110101010010010"; -- 210 degrees = 3.6652 radians
        
        --angle <= "11101111001111110"; -- -30 degrees = 0.523 radians
        --angle <= "11100110110111101"; -- -45 degrees = 0.758 radians
        --angle <= "11011110011111110"; -- -60 degrees = 1.047 radians
        --angle <= "11001101101111000"; -- -90 degrees = 1.571 radians
        --angle <= "10111100111111100"; -- -120 degrees = 2.094 radians
        --angle <= "10110100100111000"; -- -135 degrees = 2.356 radians
        --angle <= "10101100001110011"; -- -150 degrees = 2.618 radians
        --angle <= "10011011100000000"; -- -180 degrees = 3.141 radians
        --angle <= "10001010101101110"; -- -210 degrees = 3.6652 radians
        
        

end Behavioral;
