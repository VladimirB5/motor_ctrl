LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
-- Package Declaration Section
package tb_top_pkg is
  
  -- axi lite interface
  type t_AXI_M_IN is record
    clk_syn        : std_logic;
    AWREADY        : std_logic;
    WREADY         : std_logic;
    BVALID         : std_logic;
    BRESP          : std_logic_vector(1 downto 0);
    ARREADY        : std_logic;
    RVALID         : std_logic;
    RDATA          : std_logic_vector(31 downto 0);
    RRESP          : std_logic_vector(1 downto 0);      
  end record t_AXI_M_IN;  
  
  type t_AXI_M_OUT is record
    ACLK           : std_logic;    
    AWVALID        : std_logic;
    AWADDR         : std_logic_vector(31 downto 0);
    AWPROT         : std_logic_vector(2 downto 0);
    WVALID         : std_logic;
    WDATA          : std_logic_vector(31 downto 0);
    WSTRB          : std_logic_vector(3 downto 0); -- C_S_AXI_DATA_WIDTH/8)-1 : 0
    BREADY         : std_logic;
    ARVALID        : std_logic;
    ARADDR         : std_logic_vector(31 downto 0);
    ARPROT         : std_logic_vector(2 downto 0);
    RREADY         : std_logic;
  end record t_AXI_M_OUT;    

  type t_CTRL is record
   stop_sim : boolean;
   rst_n    : std_logic;
   -- temporary added signals...
  end record t_CTRL;

  type t_SIG_CHECK is record
    for_a       : std_logic;
    rev_a       : std_logic;
    for_b       : std_logic;
    rev_b       : std_logic;
    -- leds
    green_led   : std_logic;
    red_led     : std_logic;
  end record t_SIG_CHECK;
      
end package tb_top_pkg;
