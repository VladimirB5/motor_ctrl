LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

use work.tb_top_pkg.all;
use work.axi_lite_tb_pkg.all;

ENTITY stimuli_tb IS 
  port (
    axi_m_in  : IN   t_AXI_M_IN;
    axi_m_out : OUT  t_AXI_M_OUT;
    ctrl      : OUT  t_CTRL;
    sig_check : IN   t_SIG_CHECK
  );
END ENTITY stimuli_tb;

ARCHITECTURE basic_test OF stimuli_tb IS
-------------------------------------------------------------------------------
  signal address   : std_logic_vector(31 downto 0);
  signal data      : std_logic_vector(31 downto 0);
  signal data_read : std_logic_vector(31 downto 0) := (others => '0');
 
begin

   sim: process
     begin
     axi_m_out.ARPROT  <= (others => '0');
     --AXI_L_ARVALID <= '0';     
     ctrl.rst_n <= '0';
     wait for 100 ns;
     wait for 100 ns;

     ctrl.rst_n <= '1';
          
     wait for us;
     address <= x"00000000";
     data    <= x"00000001"; -- enable motor controler
     axi_write(axi_m_in, axi_m_out, address, data);
     
     address <= x"00000008";
     data    <= x"00808000"; -- set pwm to 50%
     --data    <= x"00ffff00"; -- set pwm to 50%
     --data      <= x"00010100";
     --data      <= x"00000000";
     axi_write(axi_m_in, axi_m_out, address, data);

     address <= x"00000004";
     data    <= x"00000001"; -- run
     axi_write(axi_m_in, axi_m_out, address, data);
     
     -- set read led to '1'
     address <= x"0000000C";
     data    <= x"00000001";
     axi_write(axi_m_in, axi_m_out, address, data);

     -- read value from register and check it
     axi_read(axi_m_in, axi_m_out, address, data_read);
     if data_read /= x"00000001" then
       report "Bad data read from register(1)" severity FAILURE;
     end if;
     wait for 10 ns;
     if sig_check.green_led /= '0' OR sig_check.red_led /= '1' then
       report "Bad value of green and red led (1)" severity FAILURE;
     end if;

     -- set green led to '1'
     address <= x"0000000C";
     data    <= x"00000002";
     axi_write(axi_m_in, axi_m_out, address, data);

    -- read value from register and check it
     axi_read(axi_m_in, axi_m_out, address, data_read);
     if data_read /= x"00000002" then
       report "Bad data read from register(2)" severity FAILURE;
     end if;
     wait for 10 ns;
     if sig_check.green_led /= '1' OR sig_check.red_led /= '0' then
       report "Bad value of green and red led (2)" severity FAILURE;
     end if;

     -- set read and green led to '1'
     address <= x"0000000C";
     data    <= x"00000003";
     axi_write(axi_m_in, axi_m_out, address, data);

     -- read value from register and check it
     axi_read(axi_m_in, axi_m_out, address, data_read);
     if data_read /= x"00000003" then
       report "Bad data read from register(3)" severity FAILURE;
     end if;
     if sig_check.green_led /= '1' OR sig_check.red_led /= '1' then
       report "Bad value of green and red led (3)" severity FAILURE;
     end if;

     wait for 500 us;
     
     ctrl.stop_sim <= true;
     --report "simulation finished successfully" severity FAILURE;
     wait;    
   end process;

end ARCHITECTURE basic_test;
 
 
 
