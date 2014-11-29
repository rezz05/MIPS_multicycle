.text
	addi 	$a0, $zero, 0x00002000	# StartAddr
	addi 	$a1, $zero, 5		# Size
	addi 	$a2, $zero, 0		# UP, 1 crescente, 0 decresente
	addi 	$a3, $zero, 1		# SignedData, 0 unsigned, 1 signed


	addi 	$t0, $zero, 1 		# i <= 1
	add 	$t1, $zero, $a0		# t1 <= a0/startAddr
for:
	beq 	$t0, $a1, End_For 	# i < size
	addi	$t1, $t1, 4		# t1 <= t1 + 4
	lw 	$t2, 0($t1)		# t2 <= mem[t1] / t2 == eleito
	addi 	$t3, $t0, -1		# t3 <= t1 - 1 / j - 1

for_swap:
	slt 	$at, $t3, $zero
	bne 	$at, $zero, end_swap	# if j < 0
	add 	$t4, $t3, $t3		#
	add 	$t4, $t4, $t4		# t4 <=  i * 4
	add	$t4, $t4, $a0		# t4 <= t4 + a0
	lw 	$t5, 0($t4)		# t5 <= mem[j]
	
	bne	$a3, $zero, signed	# SignedData = 1, jump para comparacoes signed
	
	# Comparacoes Unsigned
	beq 	$a2, $zero, u_Decr 	# UP = 0, jump para comparacao decrescente 
	# Crescente Unsigned
	sltu 	$at, $t2, $t5
	beq 	$at, $zero, end_swap	# if eleito < mem[j]
	j 	end_comp
	
u_Decr:	# Decrescente Unsigned
	sltu 	$at, $t5, $t2		
	beq 	$at, $zero, end_swap	# if eleito > mem[j]
	j 	end_comp

signed:
	# Comparacoes Signed
	beq 	$a2, $zero, s_Decr 	# UP = 0, jump para comparacao decrescente 
	# Crescente Signed
	slt 	$at, $t2, $t5
	beq 	$at, $zero, end_swap	# if eleito < mem[j]
	j 	end_comp
	
s_Decr:	# Decrescente Unsigned
	slt 	$at, $t5, $t2		
	beq 	$at, $zero, end_swap	# if eleito > mem[j]
	j 	end_comp
	
end_comp:
	sw 	$t5, 4($t4)		# mem[j + 1] <= t5/
	addi 	$t3, $t3, -1		# j--
	j 	for_swap

end_swap:
	add 	$t4, $t3, $t3		#
	add 	$t4, $t4, $t4		# t4 <= i * 4
	add	$t4, $t4, $a0		# t4 <= t4 + a0
	sw 	$t2, 4($t4)		# mem[t4 + 1] <= t2

	addi 	$t0, $t0, 1		# i++
	j 	for
	
End_For:

.data
