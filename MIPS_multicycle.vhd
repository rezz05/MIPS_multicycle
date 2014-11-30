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
		
		-- Data memory interface
		memAddress    		: out std_logic_vector(31 downto 0);
		data_i				: in  std_logic_vector(31 downto 0);      
        data_o				: out std_logic_vector(31 downto 0);
        MemWrite			: out std_logic 
	);
end MIPS_multicycle;

architecture behavioral of MIPS_multicycle is

    signal pc : std_logic_vector(31 downto 0);
    signal RegWrite : std_logic;
    signal instructionRegister, regA, regB : std_logic_vector(31 downto 0);

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

    signal offsetBranch : std_logic_vector(31 downto 0);
    signal offsetJump   : std_logic_vector(27 downto 0);

    signal r_Address : std_logic_vector(31 downto 0);
     
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
            r_Address <= (others=>'0');
            for i in 0 to 31 loop   
                registerFile(i) <= (others=>'0');  
            end loop;

        elsif rising_edge(clk) then
            case currentState is
                when S0 =>
                    pc <= pc + 4;
                    instructionRegister <= data_i;

                    currentState <= S1;

                when S1 =>
                    if decodedInstruction = ADDI or decodedInstruction = LW or decodedInstruction = SW then
                        currentState <= S2;
                    elsif decodedInstruction = ADD or decodedInstruction = SLT or decodedInstruction = SLTU then
                        currentState <= S4;
                    elsif decodedInstruction = BEQ or decodedInstruction = BNE then
                        currentState <= S6;
                    elsif decodedInstruction = J then
                        currentState <= S8;
                    else
                        currentState <= S0;
                    end if;

                when S2 =>
                    if IMM(15) = '1' then
                        regB <= x"FFFF" & IMM;
                    else
                        regB <= x"0000" & IMM;
                    end if;
                    currentState <= S3;

                when S3 =>
                    r_Address  <= regA + regB;
                    if decodedInstruction = ADDI and rt /= 0 then
                        registerFile(TO_INTEGER(UNSIGNED(rt))) <= regA + regB;
                        currentState <= S0;
                    elsif decodedInstruction = SW then
                        currentState <= S9;
                    else -- default, for LW
                        currentState <= S7;
                    end if;

                when S4 =>
                    regB <= registerFile(TO_INTEGER(UNSIGNED(rt)));
                    currentState <= S5;

                when S5 =>
                    if decodedInstruction = ADD and rd /= 0 then
                        registerFile(TO_INTEGER(UNSIGNED(rd))) <= regA + regB;
                    else
                        if decodedInstruction = SLT and rd /= 0 and signed(registerFile(TO_INTEGER(UNSIGNED(rs)))) < signed(registerFile(TO_INTEGER(UNSIGNED(rt)))) then
                            registerFile(TO_INTEGER(UNSIGNED(rd))) <= x"00000001";
                        elsif decodedInstruction = SLTU and rd /= 0 and registerFile(TO_INTEGER(UNSIGNED(rs))) < registerFile(TO_INTEGER(UNSIGNED(rt))) then
                            registerFile(TO_INTEGER(UNSIGNED(rd))) <= x"00000001";
                        else
                            registerFile(TO_INTEGER(UNSIGNED(rd))) <= x"00000000";
                        end if;
                    end if;
                    currentState <= S0;

                when S6 =>
                    if decodedInstruction = BEQ and (registerFile(TO_INTEGER(UNSIGNED(rs))) = registerFile(TO_INTEGER(UNSIGNED(rt)))) then
                        pc <= pc + (offsetBranch(29 downto 0) & "00");
                    elsif decodedInstruction = BNE and (registerFile(TO_INTEGER(UNSIGNED(rs))) /= registerFile(TO_INTEGER(UNSIGNED(rt)))) then
                        pc <= pc + (offsetBranch(29 downto 0) & "00");
                    end if;
                    currentState <= S0;

                when S7 =>
                    registerFile(TO_INTEGER(UNSIGNED(rt))) <= data_i;
                    currentState <= S0;

                when S8 =>
                    pc <= pc(31 downto 28) & offsetJump;
                    currentState <= S0;

                when S9 =>
                    currentState <= S0;

                when others =>
                    currentState <= S0;
            end case;
        end if;
    end process;

    regA    <=  registerFile(TO_INTEGER(UNSIGNED(rs)));  -- RegA is always rs

    rs      <= instructionRegister(25 downto 21);
    rt      <= instructionRegister(20 downto 16);
    rd      <= instructionRegister(15 downto 11);
    IMM     <= instructionRegister(15 downto 0);
    opcode  <= instructionRegister(31 downto 26);
    funct   <= instructionRegister(5 downto 0);

    offsetBranch <= (x"0000" & instructionRegister(15 downto 0));
    offsetJump <= instructionRegister(25 downto 0) & "00";
    data_o <= registerFile(TO_INTEGER(UNSIGNED(rt)));

    -- Instruction decoding
    decodedInstruction <=   ADD     when opcode = "000000" and funct = "100000" else
                            SLT     when opcode = "000000" and funct = "101010" else
                            SLTU    when opcode = "000000" and funct = "101011" else
                            SW      when opcode = "101011" else
                            LW      when opcode = "100011" else
                            ADDI    when opcode = "001000" else
                            BEQ     when opcode = "000100" else
                            BNE     when opcode = "000101" else
                            J       when opcode = "000010" else
                            INVALID_INSTRUCTION;    -- Invalid or not implemented instruction
    assert not (decodedInstruction = INVALID_INSTRUCTION and rst = '0')   
    report "******************* INVALID INSTRUCTION *************"
    severity error;

    memAddress <= r_Address when currentState = S7 or currentState = S9 else pc;
    MemWrite <= '1' when currentState = S9 else '0';
    
end behavioral;