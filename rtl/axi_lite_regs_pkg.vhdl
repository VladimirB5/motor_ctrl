LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
-- Package Declaration Section
package axi_lite_regs_pkg is
  
  -- axi lite reg map registers
  type t_axi_lite_regs is record
    enable    : std_logic;
    run       : std_logic;
    rev_cmd_a : std_logic;
    rev_cmd_b : std_logic;
    channel_a : std_logic_vector(7 downto 0);
    channel_b : std_logic_vector(7 downto 0);
    green     : std_logic;
    red       : std_logic;
  end record t_axi_lite_regs;

  constant C_AXI_LITE_REGS_INIT : t_axi_lite_regs :=
            (enable    => '0',
             run       => '0',
             rev_cmd_a => '0',
             rev_cmd_b => '0',
             channel_a => (others => '0'),
             channel_b => (others => '0'),
             green     => '0',
             red       => '0');

    -- reg addresses
  CONSTANT  C_ADDR_ENABLE   : std_logic_vector(3 downto 0) := "0000";
  CONSTANT  C_ADDR_RUN      : std_logic_vector(3 downto 0) := "0001";
  CONSTANT  C_ADDR_CTRL     : std_logic_vector(3 downto 0) := "0010";
  CONSTANT  C_ADDR_LED      : std_logic_vector(3 downto 0) := "0011";
  CONSTANT  C_ADDR_TEST     : std_logic_vector(3 downto 0) := "0100";
      
end package axi_lite_regs_pkg;
