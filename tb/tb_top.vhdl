LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
use work.tb_top_pkg.all;

ENTITY tb_top IS 
END ENTITY tb_top;

ARCHITECTURE behavior OF tb_top IS
-------------------------------------------------------------------------------
COMPONENT motor_ctrl_top IS
  port (
  -- Global signals
  ACLK    : IN std_logic;
  ARESETn : IN std_logic;
  -- write adress channel
  AWVALID : IN std_logic;
  AWREADY : OUT std_logic;
  AWADDR  : IN std_logic_vector(31 downto 0);
  AWPROT  : IN std_logic_vector(2 downto 0);
  -- write data channel
  WVALID  : IN std_logic;
  WREADY  : OUT std_logic;
  WDATA   : IN std_logic_vector(31 downto 0);
  WSTRB   : IN std_logic_vector(3 downto 0); -- C_S_AXI_DATA_WIDTH/8)-1 : 0
  -- write response channel
  BVALID  : OUT std_logic;
  BREADY  : IN std_logic;
  BRESP   : OUT std_logic_vector(1 downto 0);
  -- read address channel
  ARVALID : IN  std_logic;
  ARREADY : OUT std_logic;
  ARADDR  : IN std_logic_vector(31 downto 0);
  ARPROT  : IN std_logic_vector(2 downto 0);
  -- read data channel
  RVALID  : OUT std_logic;
  RREADY  : IN std_logic;
  RDATA   : OUT std_logic_vector(31 downto 0);
  RRESP   : OUT std_logic_vector(1 downto 0);

  -- to motor controler
  for_a       : OUT std_logic;
  rev_a       : OUT std_logic;
  for_b       : OUT std_logic;
  rev_b       : OUT std_logic;

  -- leds
  green_led   : OUT std_logic;
  red_led     : OUT std_logic
  );
END COMPONENT;


COMPONENT stimuli_tb IS 
  port (
    axi_m_in  : IN   t_AXI_M_IN; 
    axi_m_out : OUT  t_AXI_M_OUT;
    ctrl      : OUT  t_CTRL;
    sig_check : IN   t_SIG_CHECK
  );
END COMPONENT stimuli_tb;
-------------------------------------------------------------------------------

   signal clk_100   : std_logic := '0';
   signal rst_n     : std_logic := '0';   
   
   signal AXI_L_ACLK    : std_logic;
   -- axi lite signals
   signal AXI_L_AWVALID : std_logic := '0';
   signal AXI_L_AWREADY : std_logic;
   signal AXI_L_AWADDR  : std_logic_vector(31 downto 0) := (others => '0');
   signal AXI_L_AWPROT  : std_logic_vector(2 downto 0)  := (others => '0');
    -- write data channel
   signal AXI_L_WVALID  : std_logic := '0';
   signal AXI_L_WREADY  : std_logic;
   signal AXI_L_WDATA   : std_logic_vector(31 downto 0) := (others => '0');
   signal AXI_L_WSTRB   : std_logic_vector(3 downto 0)  := (others => '0'); -- C_S_AXI_DATA_WIDTH/8)-1 : 0
    -- write response channel
   signal AXI_L_BVALID  : std_logic;
   signal AXI_L_BREADY  : std_logic := '0';
   signal AXI_L_BRESP   : std_logic_vector(1 downto 0);
    -- read address channel
   signal AXI_L_ARVALID : std_logic;
   signal AXI_L_ARREADY : std_logic;
   signal AXI_L_ARADDR  : std_logic_vector(31 downto 0);
   signal AXI_L_ARPROT  : std_logic_vector(2 downto 0);
    -- read data channel
   signal AXI_L_RVALID  : std_logic;
   signal AXI_L_RREADY  : std_logic;
   signal AXI_L_RDATA   : std_logic_vector(31 downto 0);
   signal AXI_L_RRESP   : std_logic_vector(1 downto 0);    

   signal stop_sim: boolean := false;
   constant clk_period_100  : time := 10 ns;
   constant clk_period_25   : time := 40 ns;
   
   signal address : std_logic_vector(31 downto 0);
   signal data    : std_logic_vector(31 downto 0);   
   
   signal write_start : std_logic := '0';
   signal read_start : std_logic := '0';

   signal sig_check : t_SIG_CHECK;
begin

   i_motor_ctrl_top: motor_ctrl_top
   PORT MAP (
     -- axi-lite
     -- Global signals
     ACLK    => clk_100,
     ARESETn => rst_n,
     -- write adress channel
     AWVALID => AXI_L_AWVALID,
     AWREADY => AXI_L_AWREADY,
     AWADDR  => AXI_L_AWADDR,
     AWPROT  => AXI_L_AWPROT,
     -- write data channel
     WVALID  => AXI_L_WVALID,
     WREADY  => AXI_L_WREADY,
     WDATA   => AXI_L_WDATA,
     WSTRB   => AXI_L_WSTRB,
     -- write response channel
     BVALID  => AXI_L_BVALID,
     BREADY  => AXI_L_BREADY,
     BRESP   => AXI_L_BRESP,
     -- read address channel
     ARVALID => AXI_L_ARVALID,
     ARREADY => AXI_L_ARREADY,
     ARADDR  => AXI_L_ARADDR,
     ARPROT  => AXI_L_ARPROT,
     -- read data channel
     RVALID  => AXI_L_RVALID,
     RREADY  => AXI_L_RREADY,
     RDATA   => AXI_L_RDATA,
     RRESP   => AXI_L_RRESP,

     -- to motor controler
     for_a      => sig_check.for_a,
     rev_a      => sig_check.rev_a,
     for_b      => sig_check.for_b,
     rev_b      => sig_check.rev_b,

     -- leds
     green_led  => sig_check.green_led,
     red_led    => sig_check.red_led
   );
           
   i_stimuli_tb : stimuli_tb
   PORT MAP (
     axi_m_in.clk_syn => clk_100,
     axi_m_in.AWREADY => AXI_L_AWREADY,
     axi_m_in.WREADY  => AXI_L_WREADY,
     axi_m_in.BVALID  => AXI_L_BVALID,
     axi_m_in.BRESP   => AXI_L_BRESP,
     axi_m_in.ARREADY => AXI_L_ARREADY,
     axi_m_in.RVALID  => AXI_L_RVALID,
     axi_m_in.RDATA   => AXI_L_RDATA,
     axi_m_in.RRESP   => AXI_L_RRESP,
     
     axi_m_out.ACLK   => AXI_L_ACLK,    
     axi_m_out.AWVALID=> AXI_L_AWVALID,
     axi_m_out.AWADDR => AXI_L_AWADDR,
     axi_m_out.AWPROT => AXI_L_AWPROT,
     axi_m_out.WVALID => AXI_L_WVALID,
     axi_m_out.WDATA  => AXI_L_WDATA,
     axi_m_out.WSTRB  => AXI_L_WSTRB,
     axi_m_out.BREADY => AXI_L_BREADY,
     axi_m_out.ARVALID=> AXI_L_ARVALID,
     axi_m_out.ARADDR => AXI_L_ARADDR,
     axi_m_out.ARPROT => AXI_L_ARPROT,
     axi_m_out.RREADY => AXI_L_RREADY,
--      t_CTRL
     ctrl.stop_sim    => stop_sim,
     ctrl.rst_n       => rst_n,
     sig_check        => sig_check
   );  
   
   clock_100: process
     begin
        clk_100 <= '0';
        wait for clk_period_100/2;  --
        clk_100 <= '1';
        wait for clk_period_100/2;  --
        if stop_sim = true then
          wait;
        end if;
   end process;
   

end ARCHITECTURE behavior; 
 
