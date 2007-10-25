

library ieee;
use std.textio.all;
use ieee.std_logic_1164.all;
use work.generic_data.all;

entity test_stub is

  port (
    -- control pins
    W_N       : in std_logic;
    E_N       : in std_logic;
    G_N       : in std_logic;
    Byte_N    : in std_logic;
    RP        : in std_logic;
    RB        : out std_logic;
    -- buses
    A         : in std_logic_vector(Addr_Bus_Dim - 1 downto 0);
    DQ        : inout std_logic_vector(Data_Bus_Dim - 2 downto 0);
    -- other pins
    DQ15A_1   : inout std_logic
  );

end test_stub;

architecture arch_stim of test_stub is

Component M29DW323D
port
      (
      E_N, Byte_N, G_N, W_N : in std_logic;
      A: in std_logic_vector(Addr_Bus_dim - 1 downto 0);
      DQ: inout std_logic_vector(14 downto 0);
      RP_N,Vcc, Vss, VppWP_N: in real;
      RB: out std_logic;
      DQ15A_1 : inout std_logic
      );
end component;

  signal  RP_N: real := 3.0;
  signal  Vcc: real := 3.0;
  signal  Vss: real := 0.0;
  signal  VppWP_N: real := 3.0;


begin   


mod_ule : M29DW323D
		port map
                 (
                 Vcc => Vcc, 
                 Vss => Vss, 
                 VppWP_N => VppWP_N, 
                 RP_N => RP_N, 
                 
                 W_N => W_N, 
                 E_N => E_N, 
                 G_N => G_N, 

                 Byte_N => Byte_N, 
                 RB => RB, 
                 A => A, 
                 DQ => DQ, 
                 DQ15A_1 => DQ15A_1 
                 );

reset_flash : process( RP, RP_N )
begin
   if RP = '1' then
	   RP_N <= 3.0;
	else RP_N <= 0.0;
  end if;
end process;

end arch_stim;    -- architecture body
