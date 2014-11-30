-------------------------------------------------------------------------
-- Design unit: MIPS monocycle
-- Description: Control and data paths port map
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.MIPS_package.all;

entity MIPS_multicycle is
	port ( 
		clk, rst      		: in std_logic;
		
		-- Instruction memory interface
		instructionAddress	: out std_logic_vector(31 downto 0);
		instruction			: in  std_logic_vector(31 downto 0);
		
		-- Data memory interface
		dataAddress 		: out std_logic_vector(31 downto 0);
		data_i				: in  std_logic_vector(31 downto 0);      
        data_o				: out std_logic_vector(31 downto 0);
        MemWrite			: out std_logic 
	);
end MIPS_multicycle;

architecture behavioral of MIPS_multicycle is

    signal pc, result   : std_logic_vector(31 downto 0);
    signal RegWrite : std_logic;
    signal instructionRegister : std_logic_vector(31 downto 0);

    type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, SA, SB);
    signal currentState: State;
    
    -- Register file
    type RegisterArray is array (natural range <>) of std_logic_vector(31 downto 0);
    signal registerFile: RegisterArray(0 to 31);
	
	-- Retrieves the rs field from the instruction
	signal rs: std_logic_vector(4 downto 0);
		
	-- Retrieves the rt field from the instruction
	signal rt: std_logic_vector(4 downto 0);
		
	-- Retrieves the rd field from the instruction
	signal rd: std_logic_vector(4 downto 0);

    -- Retrieves the IMM field for type-I instructions
    signal IMM: std_logic_vector(15 downto 0);
	
	-- ALU zero flag
    signal zero : std_logic;
     
    -- Alias to identify the instructions based on the 'opcode' and 'funct' fields
	signal  opcode     : std_logic_vector(5 downto 0);
	signal  funct      : std_logic_vector(5 downto 0);
    
    signal decodedInstruction: Instruction_type;
        
begin

    process(clk, rst)
    begin
        if rst = '1' then
            pc <= (others=>'0');
            currentState <= S0;
            for i in 0 to 31 loop   
                registerFile(i) <= (others=>'0');  
            end loop;

        elsif rising_edge(clk) then
            case currentState is
                when S0 =>
                    pc <= pc + 4;
                    instructionRegister <= instruction;

                    currentState <= S1;
                when S1 =>
                    if decodedInstruction = ADDI then
                        currentState <= SA;
                    else
                        currentState <= S9;
                    end if;
                when SA =>
                    if rt /= 0 then
                        registerFile(TO_INTEGER(UNSIGNED(rt))) <= result;
                    end if;
                    currentState <= S0;
                when S9 =>
                    currentState <= S0;
                when others =>
                    currentState <= S0;
            end case;
        end if;
    end process;

    instructionAddress <= pc;

    rs      <= instructionRegister(25 downto 21);
    rt      <= instructionRegister(20 downto 16);
    rd      <= instructionRegister(15 downto 11);
    IMM     <= instructionRegister(15 downto 0);
    opcode  <= instructionRegister(31 downto 26);
    funct   <= instructionRegister(5 downto 0);

    -- Instruction decoding
    decodedInstruction <=   ADD     when opcode = "000000" and funct = "100000" else
                            SUB     when opcode = "000000" and funct = "100010" else
                            AAND    when opcode = "000000" and funct = "100100" else
                            OOR     when opcode = "000000" and funct = "100101" else
                            SLT     when opcode = "000000" and funct = "101010" else
                            SLTU    when opcode = "000000" and funct = "101011" else
                            SW      when opcode = "101011" else
                            LW      when opcode = "100011" else
                            ADDI    when opcode = "001000" else
                            ORI     when opcode = "001101" else
                            BEQ     when opcode = "000100" else
                            BNE     when opcode = "000101" else
                            J       when opcode = "000010" else
                            INVALID_INSTRUCTION;    -- Invalid or not implemented instruction
    assert not (decodedInstruction = INVALID_INSTRUCTION and rst = '0')   
    report "******************* INVALID INSTRUCTION *************"
    severity error;
        
    result <=   registerFile(TO_INTEGER(UNSIGNED(rs))) + IMM when currentState = SA else
                registerFile(TO_INTEGER(UNSIGNED(rs))) + registerFile(TO_INTEGER(UNSIGNED(rt)));
    
    MemWrite <= '1' when decodedInstruction = SW else '0';
    
end behavioral;