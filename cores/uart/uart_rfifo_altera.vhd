library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.STD_MATCH;

entity uart_rfifo is

  generic
    (
      fifo_width        : positive := 11;
      fifo_depth        : positive := 16;
      fifo_counter_w    : positive := 5
    );
  port
    (
      -- wishbone interface

      clk               : in std_logic;
      wb_rst_i          : in std_logic;
      data_in           : in  std_logic_vector(fifo_width-1 downto 0);
      data_out          : out std_logic_vector(fifo_width-1 downto 0);
      push              : in  std_logic;
      pop               : in  std_logic;
      overrun           : out std_logic;
      count             : out std_logic_vector(fifo_counter_w-1 downto 0);
      error_bit         : out std_logic;
      fifo_reset        : in  std_logic;
      reset_status      : in std_logic
    );

end uart_rfifo;

architecture SYN of uart_rfifo is

  component rfifo IS
  	PORT
  	(
  		aclr		: IN STD_LOGIC ;
  		clock		: IN STD_LOGIC ;
  		data		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
  		rdreq		: IN STD_LOGIC ;
  		sclr		: IN STD_LOGIC ;
  		wrreq		: IN STD_LOGIC ;
  		full		: OUT STD_LOGIC ;
  		q		    : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
  		usedw		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
  	);
  END component;

  signal aclr         : std_logic;
  signal sclr         : std_logic;
  signal full         : std_logic;
  signal usedw        : std_logic_vector(3 downto 0);
  signal data_out_s   : std_logic_vector(10 downto 0);

begin

  -- asynchronous reset
  aclr <= wb_rst_i;

  process (clk, wb_rst_i)
  begin
    if wb_rst_i = '1' then
      overrun <= '0';
    elsif rising_edge (clk) then
      -- fifo reset strobe
      sclr <= fifo_reset;
      -- reset overrun logic
      if fifo_reset = '1' or reset_status = '1' then
        overrun <= '0';
      end if;
      -- set overrun condition
      if push = '1' and pop = '0' and full = '1' then
        overrun <= '1';
      end if;
    end if;
  end process;

  count <= full & usedw;
  error_bit <= '0';

  rfifo_inst : rfifo
  	port map
  	(
  		aclr		=> aclr,
  		clock		=> clk,
  		data		=> data_in,
  		rdreq		=> pop,
  		sclr		=> sclr,
  		wrreq		=> push,
  		full		=> full,
  		q		    => data_out_s,
  		usedw		=> usedw
  	);

  -- no errors
  data_out <= data_out_s(10 downto 3) & "000";

end SYN;
