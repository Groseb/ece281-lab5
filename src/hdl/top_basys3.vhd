--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--|
--| Documentation Statement: C3C McClung suggested I use a state
--| machine and he taught me how to do most of Task A.
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
port (
         clk   : in std_logic;
         sw    : in std_logic_vector(15 downto 0);
         btnU  : in std_logic;
         btnL  : in std_logic;
         btnR  : in std_logic;
         btnC  : in std_logic;
         
         led : out std_logic_vector(15 downto 0);
         
         seg : out std_logic_vector(6 downto 0);
         
         an  : out std_logic_vector(3 downto 0)
         
      );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component sevenSegDecoder is
         port( i_D : in std_logic_vector (3 downto 0);
               o_S : out std_logic_vector (6 downto 0));
               end component sevenSegDecoder;
               
	component TDM4 is
	     generic (constant k_WIDTH : natural  := 4);
	     Port ( i_clk    : in std_logic;
	            i_reset  : in std_logic;
	            i_D3     : in std_logic_vector (k_WIDTH - 1 downto 0);
	            i_D2     : in std_logic_vector (k_WIDTH - 1 downto 0);
	            i_D1     : in std_logic_vector (k_WIDTH - 1 downto 0);
	            i_D0     : in std_logic_vector (k_WIDTH - 1 downto 0);
	            o_data   : out std_logic_vector (k_WIDTH - 1 downto 0);
	            o_sel    : out std_logic_vector (3 downto 0)
                );
          end component TDM4;
   
    component clock_divider is
       generic (constant k_DIV : natural := 2 );
       
         port ( i_clk   : in std_logic;
                i_reset : in std_logic;
                o_clk   : out std_logic
         );
      end component clock_divider;
      
    component ALU is
    generic (N: integer := 0);
    Port ( i_A : in std_logic_vector (N-1 downto 0);
           i_B : in std_logic_vector (N-1 downto 0);
           o_flag : out std_logic_vector (2 downto 0);
           o_ALU : out std_logic_vector (N-1 downto 0);
           op : in std_logic_vector (2 downto 0)
           );
     end component ALU;
      
    component controller_fsm is
       Port ( i_input : in std_logic_vector(7 downto 0);
              i_adv   : in std_logic;
              i_reset : in std_logic;
              o_S     : out std_logic_vector(3 downto 0);
              o_A     : out std_logic_vector(7 downto 0);
              o_B     : out std_logic_vector(7 downto 0)
              );
     end component controller_fsm;
     
   signal w_A : std_logic_vector(7 downto 0);
   signal w_B : std_logic_vector(7 downto 0);
   signal w_cycle : std_logic_vector(3 downto 0);
   signal w_display : std_logic_vector(7 downto 0);
   
   signal w_clk : std_logic;
   
--   signal w_negative  : std_logic;
--   signal w_hundresds : std_logic_vector(3 downto 0);
--   signal w_tens      : std_logic_vector(3 downto 0);
--   signal w_ones      : std_logic_vector(3 downto 0);
signal w_flag : std_logic_vector(2 downto 0);
   signal w_data : std_logic_vector(3 downto 0);
   signal w_sel  : std_logic_vector(3 downto 0);
   
   signal w_result : std_logic_vector(7 downto 0);
   signal w_bin    : std_logic_vector(7 downto 0);
   signal w_ALU    : std_logic_vector(7 downto 0);
   signal w_op     : std_logic_vector(2 downto 0);
   
   signal w_7SD_EN_n : std_logic;
   
   signal w_tdmre : std_logic_vector(0 downto 0);
   
begin
	-- PORT MAPS ----------------------------------------
ALU_inst : ALU
       port map (
       i_A => w_A,
       i_B => w_B,
       o_flag => led(15 downto 13),
       o_ALU => w_ALU,
       op => sw(15 downto 13)
       );
       
TDM4_inst : TDM4
        port map ( i_clk => w_clk,
                   i_reset => btnL,
                   i_D3 => w_display(7 downto 4),
                   i_D2 => w_display(3 downto 0),
                   i_D1 => w_display(3 downto 0),
                   i_D0 => w_display(7 downto 4),
                   o_data => w_data,
                   o_sel => w_sel
                   );
 
sevenSegDecoder_inst : sevenSegDecoder
       port map ( i_D => w_data,
                  o_S => seg
                  );
clkdiv_inst : clock_divider
       generic map (k_DIV => 100000)
       port map ( i_clk => clk,
                  i_reset => btnL,
                  o_clk => w_clk
                  );
                  
controller_fsm_inst : controller_fsm
       port map ( i_input => sw(7 downto 0),
                  i_adv => btnC,
                  i_reset => btnR,
                  o_S => w_cycle,
                  o_A => w_A,
                  o_B => w_B
                  );    
                  
w_display <= w_ALU;
w_7SD_EN_n <= '1';
an(3) <= w_7SD_EN_n;
an(2) <= w_7SD_EN_n;              
an(1) <= '1' when w_cycle="1000" or w_sel="1011" or w_sel="1101" else '0';	
an(0) <= '1' when w_cycle="1000" or w_sel="0111" or w_sel="1110" else '0';	
	-- CONCURRENT STATEMENTS ----------------------------

w_display <= w_A when w_cycle="0001" else
w_B when w_cycle="0010" else
w_ALU when w_cycle="0100" else "00000000";

led(12 downto 4) <= "000000000";
led(3 downto 0) <= w_cycle;	
end top_basys3_arch;
