library IEEE;
use IEEE.STD_LOGIC_1164.all; 
use IEEE.numeric_std.all;

entity cordic_sin_cos is

generic (

    input_size_g    : integer := 17;  --Input size must match LUT width.
    output_size_g   : integer := 16   --Maximum = 32 bits. (Or LUT depth + 1)
);

 port (
    clk           : in std_logic;
    rst           : in std_logic;
    start         : in std_logic;
    angle_in      : in std_logic_vector(input_size_g - 1 downto 0);
    --done          : out std_logic:='0';
    sine_out      : out std_logic_vector(output_size_g - 1 downto 0);
    cosine_out    : out std_logic_vector(output_size_g - 1 downto 0)
);
end cordic_sin_cos;


architecture behavioral of cordic_sin_cos is

---------------------------------------------------------------------------
--Define Cordic look up table (LUT)
---------------------------------------------------------------------------
--Total LUT size = 16*16 ;
constant LUT_depth_c    : integer := output_size_g;
constant LUT_width_c    : integer := input_size_g;



type LUT_t is array (0 to LUT_depth_c - 1) of signed(LUT_width_c - 1 downto 0);
constant cordic_lut_c : LUT_t := (
    "00011001001000011","00001110110101100","00000111110101101","00000011111110101",
    "00000001111111110","00000000111111111","00000000011111111","00000000001111111",
    "00000000000111111","00000000000011111","00000000000001111","00000000000000000",
    "00000000000000000","00000000000000000","00000000000000000","00000000000000000"
);


constant PI         : std_logic_vector(input_size_g - 1 downto  0) := "01100100100000000";
constant PIOver2    : std_logic_vector(input_size_g - 1 downto  0) := "00110010010001000";

constant minusPI         : std_logic_vector(input_size_g - 1 downto  0) := "10011011100000000";
constant minusPIOver2    : std_logic_vector(input_size_g - 1 downto  0) := "11001101101111000";


constant gain_in    : std_logic_vector(output_size_g - 1 downto 0) := X"4DB7";
signal gain     : std_logic_vector(output_size_g downto 0);
signal initial_x    : signed(output_size_g downto 0);
signal initial_y    : signed(output_size_g downto 0);
signal initial_z    : signed(input_size_g - 1 downto 0);
--type pipeline_array_d is array(0 to output_size_g - 1) of std_logic;
--signal initial_d : std_logic;

type pipeline_array_t is array (0 to output_size_g - 1)
                            of signed(output_size_g downto 0);

signal X : pipeline_array_t := (others => (others =>'0'));
signal Y : pipeline_array_t := (others => (others =>'0'));
--signal D : pipeline_array_d := (others => '0');
--signal last_angle    : std_logic_vector(input_size_g - 1 downto 0):=(others=>'0');


type pipeline_array_z_t is array (0 to output_size_g - 1)
                            of signed(input_size_g - 1 downto 0);

signal Z : pipeline_array_z_t := (others => (others =>'0'));

begin

--Expand gain_in by one bit while preserving the sign bit
gain <= ('1' & gain_in) when gain_in(output_size_g - 1) = '1'
    else ('0' & gain_in);


--for making done
--process(angle_in)
--begin
--if(angle_in = last_angle) then
--        last_angle<="01010101010101010";
--        initial_d<='0';
--    else
--        last_angle<=angle_in;
--        initial_d<='1';
--    end if;        
--end process;

initializing : process(start)
begin
    if(start'event and start='1') then  
    if angle_in(input_size_g - 1) = '0' then
        if angle_in < PiOver2 then
            initial_x <= signed(gain);
            initial_y <= (others => '0');
            initial_z <= signed(angle_in);
        elsif (angle_in<pi and angle_in>PiOver2) then
            initial_y <= signed(gain);
            initial_x <= (others => '0');
            initial_z <= signed(angle_in)- signed(PiOver2);
        else 
            initial_x <= -signed(gain);
            initial_y <= (others => '0');
            initial_z <= signed(angle_in)- signed(Pi);
        end if;
    else

        if angle_in > minusPiOver2 then
            initial_x <= signed(gain);
            initial_y <= (others => '0');
            initial_z <= signed(angle_in);
            
        elsif (angle_in>minuspi and angle_in<minusPiOver2) then
            initial_y <= -signed(gain);
            initial_x <= (others => '0');
            initial_z <= signed(angle_in)+ signed(PiOver2);
        else 
            initial_x <= -signed(gain);
            initial_y <= (others => '0');
            initial_z <= signed(angle_in)+ signed(Pi);
        end if;
    end if;
    end if;

end process initializing;


pipelined_cordic : process(clk, rst)
begin

        if (rst = '1') then
                for gen_var in 0 to (output_size_g - 1) loop
                X(gen_var) <= (others => '0');
                Y(gen_var) <= (others => '0');
                Z(gen_var) <= (others => '0');
            end loop;

        elsif (clk'event and clk = '1') then
            X(0) <= initial_x;
            Y(0) <= initial_y;
            Z(0) <= initial_z;
            --d(0) <= initial_d;
--            
            generate_pipeline : for gen_var in 0 to output_size_g - 2 loop
                --d(gen_var+1) <= d(gen_var);
                if (Z(gen_var) < 0) then
                    X(gen_var + 1) <= X(gen_var) + (shift_right((Y(gen_var)), gen_var));
                    Y(gen_var + 1) <= Y(gen_var) - (shift_right((X(gen_var)), gen_var));
                    Z(gen_var + 1) <= Z(gen_var) + cordic_lut_c(gen_var);
                else
                    X(gen_var + 1) <= X(gen_var) - (shift_right((Y(gen_var)), gen_var));
                    Y(gen_var + 1) <= Y(gen_var) + (shift_right((X(gen_var)), gen_var));
                    Z(gen_var + 1) <= Z(gen_var) - cordic_lut_c(gen_var);
                end if;
               
            end loop generate_pipeline;
        end if;
        
end process pipelined_cordic;


sine_out    <= std_logic_vector(Y(output_size_g - 1)(output_size_g - 1 downto 0));
cosine_out  <= std_logic_vector(X(output_size_g - 1 )(output_size_g - 1 downto 0));
--done<=d(15);            
end behavioral;