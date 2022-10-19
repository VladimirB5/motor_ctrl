LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.axi_lite_regs_pkg.all;

ENTITY axi_lite_motor_ctrl IS
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
END ENTITY axi_lite_motor_ctrl;

ARCHITECTURE rtl OF axi_lite_motor_ctrl IS
  -- signals
  signal busy : std_logic;
  -- output registers
  signal  arready_c, arready_s : std_logic;
  signal  rvalid_c, rvalid_s   : std_logic;
  signal  awready_c, awready_s : std_logic;
  signal  wready_c, wready_s   : std_logic;
  signal  bvalid_c, bvalid_s   : std_logic;
  signal  rresp_c, rresp_s     : std_logic_vector(1 downto 0); -- read response
  signal  bresp_c, bresp_s     : std_logic_vector(1 downto 0); -- write resonse
  signal  rdata_c, rdata_s     : std_logic_vector(31 downto 0);
  -- register form reg. bank
  signal reg_c, reg_s : t_axi_lite_regs;

  -- fsm read declaration
  TYPE t_read_state IS (R_IDLE, R_AREADY, R_VDATA);
  SIGNAL fsm_read_c, fsm_read_s :t_read_state;
  
  -- fsm write declaration
  TYPE t_write_state IS (W_IDLE, W_ADDR_DAT, W_RESP);
  SIGNAL fsm_write_c, fsm_write_s :t_write_state;  
  
  -- responses
  constant OKAY   : std_logic_vector(1 downto 0) := B"00";
  constant EXOKAY : std_logic_vector(1 downto 0) := B"01";
  constant SLVERR : std_logic_vector(1 downto 0) := B"10";
  constant DECERR : std_logic_vector(1 downto 0) := B"11";
  begin
  -- sequential 
 state_reg : PROCESS (ACLK, ARESETn)
   BEGIN
    IF ARESETn = '0' THEN
      arready_s      <= '0';
      rvalid_s       <= '0';
      awready_s      <= '0';
      wready_s       <= '0';
      bvalid_s       <= '0';
      rresp_s        <= (others => '0');
      bresp_s        <= (others => '0');
      rdata_s        <= (others => '0');
      -- axi-lite registers
      reg_s          <= C_AXI_LITE_REGS_INIT;

      fsm_read_s     <= R_IDLE; -- init state after reset
      fsm_write_s    <= W_IDLE;
    ELSIF ACLK = '1' AND ACLK'EVENT THEN
      arready_s      <= arready_c;
      rvalid_s       <= rvalid_c;
      awready_s      <= awready_c;
      wready_s       <= wready_c;
      bvalid_s       <= bvalid_c;
      rresp_s        <= rresp_c;
      bresp_s        <= bresp_c;
      rdata_s        <= rdata_c;

      reg_s          <= reg_c;

      fsm_read_s     <= fsm_read_c; -- next fsm state
      fsm_write_s    <= fsm_write_c;
    END IF;       
 END PROCESS state_reg;

 -- read processes ---------------------------------------------------------------------------
 next_state_read_logic : PROCESS (fsm_read_s, ARVALID, RREADY)
 BEGIN
    fsm_read_c <= fsm_read_s;
    CASE fsm_read_s IS
      WHEN R_IDLE =>
        fsm_read_c <= R_AREADY;
      
      when R_AREADY =>
        IF ARVALID = '1' then 
          fsm_read_c <= R_VDATA;
        ELSE
          fsm_read_c <= R_AREADY;
        END IF;
            
      WHEN R_VDATA =>
        IF RREADY = '1' then
          fsm_read_c <= R_IDLE;
        ELSE
          fsm_read_c <= R_VDATA;
        END IF;
    END CASE;        
 END PROCESS next_state_read_logic;
    
  -- ouput combinational logic
 output_read_logic : PROCESS (fsm_read_c)
 BEGIN
    rvalid_c  <= '0';
    arready_c <= '0'; 
    CASE fsm_read_c IS
      WHEN R_IDLE =>
        arready_c <= '0';
      
      WHEN R_AREADY =>
        arready_c <= '1';
             
      WHEN R_VDATA =>
        rvalid_c <= '1';
    END CASE;
  END PROCESS output_read_logic;
  
 -- output read mux
 output_read_mux : PROCESS (fsm_read_s, ARVALID, ARADDR(4 downto 2), reg_s)
 BEGIN
    rdata_c <= (others => '0');
    rresp_c <= OKAY;   
    IF ARVALID = '1' AND fsm_read_s = R_AREADY THEN
      CASE ARADDR(5 downto 2) IS 
        WHEN C_ADDR_ENABLE =>
          rdata_c(0) <= reg_s.enable;
        WHEN C_ADDR_RUN =>
          rdata_c(0) <= reg_s.run;
        WHEN C_ADDR_CTRL =>
          rdata_c(1)           <= reg_s.rev_cmd_a;
          rdata_c(0)           <= reg_s.rev_cmd_b;
          rdata_c(15 downto 8) <= reg_s.channel_a;
          rdata_c(23 downto 16)<= reg_s.channel_b;
        WHEN C_ADDR_LED =>
          rdata_c(1)           <= reg_s.green;
          rdata_c(0)           <= reg_s.red;
        WHEN C_ADDR_TEST => 
          rdata_c <= x"12345678";
        WHEN others =>
          rresp_c <= SLVERR;
      END CASE;
    ELSIF fsm_read_s = R_VDATA THEN
      rdata_c <= rdata_s;
      rresp_c <= rresp_s;
    ELSE
      rdata_c <= (others => '0');
    END IF;
  END PROCESS output_read_mux;
  
-- write processes ------------------------------------------------------------------------  
 next_state_write_logic : PROCESS (fsm_write_s, AWVALID, WVALID, BREADY)
 BEGIN
    fsm_write_c <= fsm_write_s;
    CASE fsm_write_s IS
      WHEN W_IDLE =>
        IF AWVALID = '1' AND WVALID = '1' THEN
          fsm_write_c <= W_ADDR_DAT;
        END IF;
            
      WHEN W_ADDR_DAT =>
        fsm_write_c <= W_RESP;
      
      WHEN W_RESP =>
        IF BREADY = '1' THEN 
          fsm_write_c <= W_IDLE;
        END IF;
    END CASE;
 END PROCESS next_state_write_logic;
  
 output_write_logic : PROCESS (fsm_write_c, AWADDR(4 downto 2), WDATA, bresp_s, reg_s)
 BEGIN
    awready_c      <= '0';
    wready_c       <= '0';
    bvalid_c       <= '0';
    bresp_c        <= bresp_s;
    -- axi registers
    reg_c          <= reg_s;

    CASE fsm_write_c IS
      WHEN W_IDLE => 
        bresp_c   <= OKAY;
        awready_c <= '0';
        wready_c  <= '0';
        bvalid_c  <= '0';
            
      WHEN W_ADDR_DAT =>
        CASE AWADDR(5 downto 2) IS
          WHEN C_ADDR_ENABLE =>
            reg_c.enable <= WDATA(0);
          WHEN C_ADDR_RUN =>
            reg_c.run <= WDATA(0);
          WHEN C_ADDR_CTRL =>
            reg_c.rev_cmd_a <= WDATA(1);
            reg_c.rev_cmd_b <= WDATA(0);
            reg_c.channel_a <= WDATA(15 downto 8);
            reg_c.channel_b <= WDATA(23 downto 16);
          WHEN C_ADDR_LED  =>
            reg_c.green <= WDATA(1);
            reg_c.red   <= WDATA(0);
          WHEN C_ADDR_TEST => 
            -- RO address
          WHEN others =>
            bresp_c <= SLVERR;
        END CASE;      
        awready_c <= '1';
        wready_c  <= '1';
        bvalid_c  <= '0';      
      
      WHEN W_RESP =>
        awready_c <= '0';
        wready_c  <= '0';
        bvalid_c  <= '1';      
    END CASE;
  END PROCESS output_write_logic; 
  
  -- output assigment
  -- read channels
  ARREADY <= arready_s;
  RVALID  <= rvalid_s;
  RDATA   <= rdata_s;
  RRESP   <= rresp_s;
  -- write channels
  AWREADY <= awready_s;
  WREADY  <= wready_s;
  BVALID  <= bvalid_s;
  BRESP   <= bresp_s;
  -- output from register bank
  enable    <= reg_s.enable;
  run       <= reg_s.run;
  rev_cmd_a <= reg_s.rev_cmd_a;
  rev_cmd_b <= reg_s.rev_cmd_b;
  channel_a <= reg_s.channel_a;
  channel_b <= reg_s.channel_b;
  red_led   <= reg_s.red;
  green_led <= reg_s.green;
END ARCHITECTURE RTL;
 
