library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dummy_mem is
	port (
		clk				: in std_logic;
    addr			: in std_logic_vector(15 downto 0);
    data			: out std_logic_vector(15 downto 0)
	);
end dummy_mem;

architecture SIM of dummy_mem is
begin
	process (addr)
	begin
	  data <= addr(15 downto 0) after 12 ns; -- 12ns SRAM
	end process;
end SIM;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ems is
	port (
		fail:				out  boolean := false
	);
end entity tb_ems;

architecture SYN of tb_ems is

	signal clk						: std_logic := '0';
	signal reset					: std_logic	:= '1';

  signal wb_adr_i       : std_logic_vector(15 downto 1) := (others => '0');
  signal wb_dat_i       : std_logic_vector(15 downto 0) := (others => '0');
  signal wb_dat_o       : std_logic_vector(15 downto 0) := (others => '0');
  signal wb_sel_i       : std_logic_vector(1 downto 0) := (others => '0');
  signal wb_cyc_i       : std_logic := '0';
  signal wb_stb_i       : std_logic := '0';
  signal wb_we_i        : std_logic := '0';
  signal wb_ack_o       : std_logic := '0';
	signal ems_io_arena		: std_logic := '0';
  signal sdram_adr_i    : std_logic_vector(19 downto 1) := (others => '0');
  signal sdram_adr_o    : std_logic_vector(31 downto 0) := (others => '0');

  alias sdram_seg_i     : std_logic_vector(19 downto 4) is sdram_adr_i(19 downto 4);
  alias sdram_seg_o     : std_logic_vector(24 downto 5) is sdram_adr_o(24 downto 5);

begin

	-- Generate CLK and reset
  clk <= not clk after 40 ns; -- 12.5MHz
	reset <= '0' after 125 ns;

  process
    procedure wb_wr ( adr : in std_logic_vector(2 downto 0); 
                      dat : in std_logic_vector(7 downto 0)) is
    begin
      wait until falling_edge(clk);
      wb_adr_i(2 downto 1) <= adr(2 downto 1);
      wb_sel_i(0) <= adr(0);
      wb_cyc_i <= '1';
      wb_stb_i <= ems_io_arena;
      wb_we_i <= '1';
      wb_dat_i <= dat & dat;
      wait until falling_edge(clk);
      wb_cyc_i <= '0';
      wb_stb_i <= '0';
      wb_we_i <= '0';
    end procedure wb_wr;
  begin
		wb_adr_i(15 downto 3) <= X"020" & '1';
    sdram_adr_i(3 downto 1) <= (others => '0');
    wait until reset = '0';

    wait until falling_edge(clk);
    sdram_seg_i <= X"A000";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B000";
    wait until falling_edge(clk);
    sdram_seg_i <= X"C000";

    -- enable EMS, page-frame $B000:0, default pages
    wb_wr ("100", X"8B");

    wait until falling_edge(clk);
    sdram_seg_i <= X"A000";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B000";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B400";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B800";
    wait until falling_edge(clk);
    sdram_seg_i <= X"BC00";
    wait until falling_edge(clk);
    sdram_seg_i <= X"C000";

    -- enable EMS, page-frame $B000:0, conventional
    wb_wr ("000", X"2C");
    wb_wr ("001", X"2D");
    wb_wr ("010", X"2E");
    wb_wr ("011", X"2F");
    wb_wr ("100", X"8B");

    wait until falling_edge(clk);
    sdram_seg_i <= X"A000";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B000";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B400";
    wait until falling_edge(clk);
    sdram_seg_i <= X"B800";
    wait until falling_edge(clk);
    sdram_seg_i <= X"BC00";
    wait until falling_edge(clk);
    sdram_seg_i <= X"C000";

    wb_wr ("000", X"40");
    wait until falling_edge(clk);
    sdram_seg_i <= X"B000";
    wb_wr ("000", X"80");
    wb_wr ("000", X"FF");

    wb_wr ("100", X"8C");
    sdram_seg_i <= X"C000";
    wb_wr ("100", X"0C");

		-- attempt to re-enable outside register space
		wb_adr_i(15 downto 3) <= X"022" & '1';
    wb_wr ("100", X"8C");

  end process;

  ems_hw : entity work.ems
		generic map
		(
			IO_BASE_ADDR	=> 16#0208#
		)
    port map
    (
    	wb_clk        => clk,
    	wb_rst        => reset,
    	
    	wb_adr_i      => wb_adr_i,
    	wb_dat_i      => wb_dat_i,
    	wb_dat_o      => wb_dat_o,
    	wb_sel_i      => wb_sel_i,
    	wb_cyc_i      => wb_cyc_i,
    	wb_stb_i      => wb_stb_i,
    	wb_we_i       => wb_we_i,
    	wb_ack_o      => wb_ack_o,
			ems_io_area		=> ems_io_arena,
    
    	sdram_adr_i   => sdram_adr_i,
    	sdram_adr_o   => sdram_adr_o
    );

end SYN;
