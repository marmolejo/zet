--
-- DE2 Audio interface
--
-- Note default output freq is not quite correct (not a nice multiple of clock freq)
--

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity audio_if is
  generic (
    REF_CLK       : integer := 18000000;  -- Set REF clk frequency here
    SAMPLE_RATE   : integer := 48000;     -- 48000 samples/sec
    DATA_WIDTH    : integer := 16;			  --	16		Bits
    CHANNEL_NUM   : integer := 2  			  --	Dual Channel
  );
  port
  (
		-- Inputs
    clk           : in std_logic;                       -- Input audio clock (no greater than 18.5 MHz)
    reset         : in std_logic;                       -- Reset
    datal         : in std_logic_vector(15 downto 0);   -- Left channel audio data
    datar         : in std_logic_vector(15 downto 0);   -- Right channel audio data

    -- Outputs
    aud_xck       : out std_logic;                      -- Audio CODEC ADC LR Clock	Audio CODEC Chip Clock
    aud_adclrck   : out std_logic;                      -- Audio CODEC ADC LR Clock
    aud_daclrck   : out std_logic;                      -- Audio CODEC ADC LR Clock	Audio CODEC DAC LR Clock
    aud_bclk      : out std_logic;                      -- Audio CODEC ADC LR Clock	Audio CODEC Bit-Stream Clock
    aud_dacdat    : out std_logic;                      -- Audio CODEC ADC LR Clock	Audio CODEC DAC Data
    next_sample   : out std_logic                       -- Next sample please
  );
end audio_if;

architecture SYN of audio_if is
  signal lrck_div : unsigned(7 downto 0);
begin
  -- Audio
  aud_xck <= clk;

  --next_sample <= '1' when (lrck_div >= ref_clk/(sample_rate*2)-1) else '0';

  --////////////	AUD_BCK and LRCK Generator	//////////////
  audgen: process(clk, reset)
    variable bck_div      : integer;
    variable bck_div_oflow : std_logic;
    variable lrck_div_r   : integer;
    variable aud_bck_r    : std_logic;
    variable lrck         : std_logic;
    variable sel          : integer := 0;
    variable data         : std_logic_vector(15 downto 0);
    variable nextd        : std_logic;
  begin
    aud_bclk <= aud_bck_r;
    aud_daclrck <= lrck;
    aud_adclrck <= lrck;
    aud_dacdat <= data(15-sel);
    lrck_div <= conv_unsigned(lrck_div_r, 8);
    next_sample <= nextd;

    if reset = '1' then
      bck_div     := 0;
      bck_div_oflow := '0';
      aud_bck_r   := '0';
  		lrck_div_r	:= 0;
  		lrck    		:= '0';
      sel         := 0;
      data        := X"0000";
      nextd       := '0';

    elsif rising_edge(clk) then
      nextd := '0';
      -- Generate BCLK and bit select
  		if bck_div_oflow = '1' then
        if aud_bck_r = '1' then
          -- If bit select is about to wrap, toggle LRCK
          if sel = DATA_WIDTH-1 then
            -- Latch input data
            if lrck = '1' then
              data := datal;
            else
              data := datar;
              nextd := '1';
            end if;
    
            -- Generate LRCK
      			lrck_div_r	:=	0;
      			lrck	:= not lrck;
          end if;
  
          -- Bit select counter
          if sel < DATA_WIDTH-1 then
            sel := sel + 1;
          else
            sel := 0;
          end if;
        end if;

        -- Generate BCLK
  			bck_div := 0;
  			aud_bck_r := not aud_bck_r;
      else
  		  bck_div	:= bck_div+1;
  		end if;

  		if bck_div >= REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1 then
        bck_div_oflow := '1';
      else
        bck_div_oflow := '0';
      end if;
    end if;
  end process;
end SYN;
