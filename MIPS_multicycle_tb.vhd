-------------------------------------------------------------------------
-- Design unit: MIPS monocycle test bench
-- Description: 
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use work.MIPS_package.all;


entity MIPS_multicycle_tb is
end MIPS_multicycle_tb;


architecture arch1 of MIPS_multicycle_tb is

	signal clock: std_logic := '0';
	signal reset, MemWrite: std_logic;
	signal instructionAddress, dataAddress, instruction, data_i, data_o : std_logic_vector(31 downto 0);
	signal uins: Microinstruction;
	
begin

	clock <= not clock after 5 ns;
	
	reset <= '1', '0' after 7 ns;
				
		
	MIPS_MONOCYCLE: entity work.MIPS_multicycle(behavioral) 
		port map (
			clk				=> clock,
			rst				=> reset,
			
			-- Instruction memory interface
			instructionAddress	=> instructionAddress,	
			instruction			=> instruction,		
			 	
			 -- Data memory interface
			dataAddress			=> dataAddress,
			data_i				=> data_i,
			data_o				=> data_o,
			MemWrite			=> MemWrite
		);
	
	
	INSTRUCTION_MEMORY: entity work.Memory(behavioral)
		generic map (
			SIZE 			=> 100,
			START_ADDRESS 	=> x"00000000",     -- Address to be mapped to address 0x00000000
			imageFileName	=> "program.txt"
		)
		port map (
			clock		=> clock,
			MemWrite 	=> '0',
			address		=> instructionAddress,	
			data_i		=> data_o,
			data_o		=> instruction
		);
		
	DATA_MEMORY: entity work.Memory(behavioral)
		generic map (
			SIZE 			=> 100,
			START_ADDRESS 	=> x"00002000",     -- Address to be mapped to address 0x00000000
			imageFileName	=> "data.txt"
		)
		port map (
			clock		=> clock,
			MemWrite	=> MemWrite,
			address		=> dataAddress,	
			data_i		=> data_o,
			data_o		=> data_i
		);	
	
	
	
end arch1;


