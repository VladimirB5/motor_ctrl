LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.axi_lite_regs_pkg.all;

ENTITY motor_ctrl_top IS
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
END ENTITY motor_ctrl_top;

ARCHITECTURE rtl OF motor_ctrl_top IS

COMPONENT axi_lite_motor_ctrl IS
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

  --registers
  enable      : OUT std_logic; -- power savings
  run         : OUT std_logic; -- enable outputs, counters run
  rev_cmd_a   : OUT std_logic; -- reverse channel a
  rev_cmd_b   : OUT std_logic; -- reverse channel b
  channel_a   : OUT std_logic_vector(7 downto 0); -- channel a pwm
  channel_b   : OUT std_logic_vector(7 downto 0); -- channel b pwm
  red_led     : OUT std_logic;
  green_led   : OUT std_logic
  );
END COMPONENT;

COMPONENT motor_ctrl IS
  port (
   clk         : IN    std_logic;
   rstn        : IN    std_logic;
   -- ctrl_signals
   enable      : IN std_logic; -- power savings
   run         : IN std_logic; -- enable outputs, counters run
   rev_cmd_a   : IN std_logic; -- reverse channel a
   rev_cmd_b   : IN std_logic; -- reverse channel b
   channel_a   : IN std_logic_vector(7 downto 0); -- channel a pwm
   channel_b   : IN std_logic_vector(7 downto 0); -- channel b pwm
   -- to motor controler
   for_a       : OUT std_logic;
   rev_a       : OUT std_logic;
   for_b       : OUT std_logic;
   rev_b       : OUT std_logic
  );
END COMPONENT;

  signal enable    : std_logic;
  signal run       : std_logic;
  signal rev_cmd_a : std_logic;
  signal rev_cmd_b : std_logic;
  signal channel_a : std_logic_vector(7 downto 0);
  signal channel_b : std_logic_vector(7 downto 0);

BEGIN

  i_axi_lite_motor: axi_lite_motor_ctrl
  port map (
  -- Global signals
  ACLK    => ACLK,
  ARESETn => ARESETn,
  -- write adress channel
  AWVALID => AWVALID,
  AWREADY => AWREADY,
  AWADDR  => AWADDR,
  AWPROT  => AWPROT,
  -- write data channel
  WVALID  => WVALID,
  WREADY  => WREADY,
  WDATA   => WDATA,
  WSTRB   => WSTRB,
  -- write response channel
  BVALID  => BVALID,
  BREADY  => BREADY,
  BRESP   => BRESP,
  -- read address channel
  ARVALID => ARVALID,
  ARREADY => ARREADY,
  ARADDR  => ARADDR,
  ARPROT  => ARPROT,
  -- read data channel
  RVALID  => RVALID,
  RREADY  => RREADY,
  RDATA   => RDATA,
  RRESP   => RRESP,

  --registers
  enable    => enable,
  run       => run,
  rev_cmd_a => rev_cmd_a,
  rev_cmd_b => rev_cmd_b,
  channel_a => channel_a,
  channel_b => channel_b,
  red_led   => red_led,
  green_led => green_led
  );

  i_motor_ctrl : motor_ctrl
  port map (
   clk         => ACLK,
   rstn        => ARESETn,
   -- ctrl_signals
   enable      => enable,
   run         => run,
   rev_cmd_a   => rev_cmd_a,
   rev_cmd_b   => rev_cmd_b,
   channel_a   => channel_a,
   channel_b   => channel_b,
   -- to motor controler
   for_a       => for_a,
   rev_a       => rev_a,
   for_b       => for_b,
   rev_b       => rev_b
  );

END ARCHITECTURE rtl;
