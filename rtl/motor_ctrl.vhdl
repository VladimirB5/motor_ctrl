LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

ENTITY motor_ctrl IS
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
   pwm_freq    : IN std_logic_vector(15 downto 0);
   -- to motor controler
   for_a       : OUT std_logic;
   rev_a       : OUT std_logic;
   for_b       : OUT std_logic;
   rev_b       : OUT std_logic
  );
END ENTITY motor_ctrl;

ARCHITECTURE rtl OF motor_ctrl IS
  -- registers
  signal cnt_c,  cnt_s  : unsigned(7 downto 0);
  signal cnt_freq_c, cnt_freq_s : unsigned(15 downto 0);
  signal fora_c, fora_s : std_logic;
  signal reva_c, reva_s : std_logic;
  signal forb_c, forb_s : std_logic;
  signal revb_c, revb_s : std_logic;
  -- signals
  signal pwm_a : std_logic;
  signal pwm_b : std_logic;
  signal pwm_up : std_logic;
  -- constants
  constant MAX_VAL : std_logic_vector(7 downto 0) := x"FF";
BEGIN
-------------------------------------------------------------------------------
-- sequential
-------------------------------------------------------------------------------
  state_reg : PROCESS (clk, rstn)
   BEGIN
    IF rstn = '0' THEN
      cnt_s         <= (others => '0');
      fora_s        <= '0';
      forb_s        <= '0';
      reva_s        <= '0';
      revb_s        <= '0';
      cnt_freq_s    <= (others => '0');
    ELSIF clk = '1' AND clk'EVENT THEN
      IF enable = '1' THEN
        cnt_s         <= cnt_c;
        fora_s        <= fora_c;
        forb_s        <= forb_c;
        reva_s        <= reva_c;
        revb_s        <= revb_c;
        cnt_freq_s    <= cnt_freq_c;
      END IF;
    END IF;
  END PROCESS state_reg;

-------------------------------------------------------------------------------
-- combinational parts
-------------------------------------------------------------------------------
-- freq counter
-- frequency of PWM can be decreased:
-- PWM_FREQ_CNT_val = PWM_FREQ / (1/(clk_speed / 256))
cnt_freq_c <= cnt_freq_s + 1 when run = '1' AND pwm_up = '0' ELSE
              (others => '0');

pwm_up <= '1' when pwm_freq = x"0000" OR cnt_freq_s = unsigned(pwm_freq) ELSE
          '0';

-- counter is common for both channels 
cnt_c <= cnt_s + 1 WHEN run = '1' and pwm_up = '1' ELSE
         cnt_s WHEN run = '1' ELSE
         (others => '0');

 -- channel a

pwm_a <= '1' WHEN channel_a = MAX_VAL ELSE
         '1' WHEN cnt_s < unsigned(channel_a) ELSE
         '0';

fora_c <= '1' WHEN rev_cmd_a = '0' and pwm_a = '1' and run = '1' ELSE
          '0';

reva_c <= '1' WHEN rev_cmd_a = '1' and pwm_a = '1' and run = '1' ELSE
          '0';

 -- channel b

pwm_b <= '1' WHEN channel_b = MAX_VAL ELSE
         '1' WHEN cnt_s < unsigned(channel_b) ELSE
         '0';

forb_c <= '1' WHEN rev_cmd_b = '0' and pwm_b = '1' and run = '1' ELSE
          '0';

revb_c <= '1' WHEN rev_cmd_b = '1' and pwm_b = '1' and run = '1' ELSE
          '0';

-------------------------------------------------------------------------------
-- output assigment
-------------------------------------------------------------------------------
 for_a <= fora_s;
 rev_a <= reva_s;
 for_b <= forb_s;
 rev_b <= revb_s;

-- psl default clock is rising_edge (clk);
-- psl assert always for_a = '1' -> rev_a = '0';
-- psl assert always rev_a = '1' -> for_a = '0';
-- psl assert always for_b = '1' -> rev_b = '0';
-- psl assert always rev_b = '1' -> for_b = '0';

END ARCHITECTURE rtl;

