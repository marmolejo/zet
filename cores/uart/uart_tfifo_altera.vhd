library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.STD_MATCH;

entity uart_tfifo is

  generic
    (
      fifo_width        : positive := 8;
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
      fifo_reset        : in  std_logic;
      reset_status      : in std_logic
    );

end uart_tfifo;

architecture SYN of uart_tfifo is

  component tfifo IS
  	PORT
  	(
  		aclr		: IN STD_LOGIC ;
  		clock		: IN STD_LOGIC ;
  		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
  		rdreq		: IN STD_LOGIC ;
  		sclr		: IN STD_LOGIC ;
  		wrreq		: IN STD_LOGIC ;
  		full		: OUT STD_LOGIC ;
  		q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
  		usedw		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
  	);
  END component;

  signal aclr     : std_logic;
  signal sclr     : std_logic;
  signal full     : std_logic;
  signal usedw    : std_logic_vector(3 downto 0);

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

  tfifo_inst : tfifo
  	port map
  	(
  		aclr		=> aclr,
  		clock		=> clk,
  		data		=> data_in,
  		rdreq		=> pop,
  		sclr		=> sclr,
  		wrreq		=> push,
  		full		=> full,
  		q		    => data_out,
  		usedw		=> usedw
  	);

end SYN;
