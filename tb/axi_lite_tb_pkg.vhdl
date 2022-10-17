LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
use work.tb_top_pkg.all;

-- Package Declaration Section
package axi_lite_tb_pkg is
  
  procedure axi_write (
    signal axi_m_in  : IN   t_AXI_M_IN; 
    signal axi_m_out : OUT  t_AXI_M_OUT;
    signal addr      : IN std_logic_vector(31 downto 0);
    signal data      : IN std_logic_vector(31 downto 0)
   );
   
  procedure axi_read (
    signal axi_m_in  : IN   t_AXI_M_IN; 
    signal axi_m_out : OUT  t_AXI_M_OUT;
    signal addr      : IN  std_logic_vector(31 downto 0);
    signal data      : OUT std_logic_vector(31 downto 0)
   );   
end package axi_lite_tb_pkg;
 
-- Package Body Section
package body axi_lite_tb_pkg is
 
  procedure axi_write (
    signal axi_m_in  : IN   t_AXI_M_IN; 
    signal axi_m_out : OUT  t_AXI_M_OUT;
    signal addr      : IN std_logic_vector(31 downto 0);
    signal data      : IN std_logic_vector(31 downto 0)
   ) is  
  begin 
        wait for 1 ps;
        axi_m_out.awvalid <= '1';
        axi_m_out.awaddr  <= addr;
        wait for 10 ns;
        axi_m_out.wvalid  <= '1';
        axi_m_out.wstrb   <= (others => '1');
        axi_m_out.wdata   <= data;
        wait until axi_m_in.awready = '1' AND axi_m_in.awready'EVENT;
        wait for 1 ns;
        axi_m_out.awvalid <= '0';
        axi_m_out.wvalid  <= '0';
        axi_m_out.awaddr  <= (others => '0');
        axi_m_out.wstrb   <= (others => '0');   
        wait until axi_m_in.clk_syn = '1' AND axi_m_in.clk_syn'EVENT;
        wait for 1 ns;
        axi_m_out.bready <= '1';
        wait until axi_m_in.clk_syn = '1' AND axi_m_in.clk_syn'EVENT;
        wait for 1 ns;
        axi_m_out.bready <= '0'; 
  end axi_write;
  
  procedure axi_read (
    signal axi_m_in  : IN   t_AXI_M_IN; 
    signal axi_m_out : OUT  t_AXI_M_OUT;
    signal addr      : IN  std_logic_vector(31 downto 0);
    signal data      : OUT std_logic_vector(31 downto 0)
   ) is 
  begin
       axi_m_out.arvalid <= '0';
       axi_m_out.rready  <= '0';
       wait until axi_m_in.clk_syn = '0' AND axi_m_in.clk_syn'EVENT;
       axi_m_out.arvalid <= '1';
       axi_m_out.araddr  <= addr;
       --wait until AXI_L_arready = '1' AND AXI_L_awready'EVENT;
       wait until axi_m_in.clk_syn = '1' AND axi_m_in.clk_syn'EVENT;
       wait for 1 ns;
       axi_m_out.arvalid <= '0';
       axi_m_out.rready  <= '1';
       axi_m_out.araddr  <= (others => '0');
       wait until axi_m_in.clk_syn = '1' AND axi_m_in.clk_syn'EVENT;
       data <= axi_m_in.rdata;
       wait for 1 ns;
       axi_m_out.rready  <= '0';
  end axi_read;
 
end package body axi_lite_tb_pkg;
