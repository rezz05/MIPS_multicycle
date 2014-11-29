-------------------------------------------------------------------------
-- Design unit: MIPS package
-- Description: package with...
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package MIPS_package is  
        
    -- inst_type defines the instructions decodable by the control unit
    type Instruction_type is  
            ( ADD, SUB, AAND, OOR, SW, LW, ADDI, ORI, SLT, BEQ, J, INVALID_INSTRUCTION);
 
    type Microinstruction is record
    	RegWrite	: std_logic;    	-- Register file write control
    	ALUSrc		: std_logic;        -- Decoded instruction
    	RegDst		: std_logic;        -- Selects the ALU second operand
    	MemToReg	: std_logic;        -- Selects the destination register
    	MemWrite	: std_logic;        -- Selects the data to the register file
    	Branch      : std_logic;        -- Indicates the BEQ instruction
        Jump      : std_logic;          -- Indicates the J instruction
        instruction	: Instruction_type;	-- Enable the data memory write	        
    end record;
 	    
	     
end MIPS_package;


