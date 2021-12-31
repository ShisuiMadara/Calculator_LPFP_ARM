.text

.data
    num1: .word 0x4003B500
    num2: .word 0X40049C00

.global _start

@we need to convert the given values into the ldfd format because its value in ldfd format will be different from the one in normal 
convert_num_1:
    PUSH {r0}
    PUSH {r2-r9}
    ldr r1, =num1
    ldr r0, [r1]   @ Load actual number 
    mov r8, r0     @ Save original
    bic r0, r0, #0x80000000 @10000000000000000000000000000000  Clears out first bit
    ldr r1, =0x40000000	  @01000000000000000000000000000000 Loads initial pos to check
    mov r3, #1                           @  ; Incrementer to get sig bit pos

loop_until_find_sig_1:
	and r2, r1, r0  @sign bit
	cmp r2, r1                 
	mov r1, r1, lsr #1     @ Moves the sig bit to the right
	add r3, r3, #1         @ increaments position
	bne loop_until_find_sig_1  

    @r3 -> position of bit
    mov r1, #16               
    sub r1, r1, r3  @ Subtract from 16 (mantissa) the pos value 

    mov r5, #16384   @bias
    sub r5,r5,#1 @16384 cannot be included directly
check_against:
	cmp r1, #14      
	blt calc_mantissa_if_less_1           
	bgt calc_mantissa_if_greater_1       
	beq calc_bias_1                
calc_mantissa_if_less_1:
	mov r4, #14
	add r5, r5, r1    @  Calculate bias as 16383 - exponent
	sub r1, r4, r1                     
	mov r0, r0, lsl r1                   
	bl finalize_mantissa_1
calc_mantissa_if_greater_1:
	add r5, r5, r1                      @ Calculate bias as 16383 + exponent
	sub r1, r1, #14                   @ Do exponent - 14 to get shift amt
	mov r0, r0, lsr r1                  
	bl finalize_mantissa_1
calc_bias_1:
	add r5, r5, #14                       @ Calculate bias as 16383 + 14
finalize_mantissa_1:
	ldr r4, =0x000FFFF    @00000000000000001111111111111111   To get 16 bits
	and r0, r4, r0

mov r5, r5, lsl#16
add r0, r0, r5


ldr r6, =0x80000000 @10000000000000000000000000000000
and r6, r8, r6
orr r0, r6, r0
mov r1, r0 @the actual number is in r1
mov r10, r1

POP {r0}
POP {r2-r9}

b step2


convert_num_2:
    PUSH {r0-r1}
    PUSH {r3-r9}
    ldr r1, =num2
    ldr r0, [r1]  
    mov r8, r0                         
    bic r0, r0, #0x80000000 @10000000000000000000000000000000    
    ldr r1, =0x40000000	  @01000000000000000000000000000000      
    mov r3, #1                         

loop_until_find_sig_2:
	and r2, r1, r0                    
	cmp r2, r1                        
	mov r1, r1, lsr #1                  
	add r3, r3, #1                      
	bne loop_until_find_sig_2          


mov r1, #16                         
sub r1, r1, r3                        

mov r5, #16384                 
sub r5,r5,#1
check_against_2:
	cmp r1, #14                           
	blt calc_mantissa_if_less_2          
	beq calc_bias_2                 
calc_mantissa_if_less_2:
	mov r4, #14
	add r5, r5, r1                   
	sub r1, r4, r1                      
	mov r0, r0, lsl r1                   
	bl finalize_mantissa_2
calc_mantissa_if_greater_2:
	add r5, r5, r1                      
	sub r1, r1, #14                  
	mov r0, r0, lsr r1                 
	bl finalize_mantissa_2
calc_bias_2:
	add r5, r5, #14                   
finalize_mantissa_2:
	ldr r4, =0x000FFFF    @00000000000000001111111111111111 To get 16 bits
	and r0, r4, r0

mov r5, r5, lsl#16
add r0, r0, r5

ldr r6, =0x80000000 @10000000000000000000000000000000
and r6, r8, r6
orr r0, r6, r0
mov r2, r0 

POP {r0-r1}
POP {r3-r9}
MOV r1,r10

b then_add


LPFPadd:
    PUSH {r0-r11}

    ldr r10, =0x7FFF0000  @binary 01111111111111110000000000000000
    and r4, r1, r10       @exponent of num1
    and r5, r2, r10       @exponent of num2
    cmp r4, r5

    movlo r3, r1
    movlo r1, r2 
    movlo r2, r3               @swap r1 with r2 if r2 has the higher exponent
    andlo r4, r1, r10 
    andlo r5, r2, r10          @update exponents if swapped

    mov r4, r4, lsr #16
    mov r5, r5, lsr #16        @ move exponents to least significant position

    sub r3, r4, r5             @ get shift amount
    ldr r10, =0xFFFF  @00000000000000001111111111111111
    and r5, r1, r10            @  num1 fractional part
    and r6, r2, r10           @   num2 fractional part
    ldr r10, =0x10000 
    orr r5, r5, r10           @ add  1 to first fractional part
    orr r6, r6, r10            @ add  1 to second fractional part
    mov r6, r6, lsr r3         @  shift r6 to the right by the difference in exponents

    ldr r10, =0x80000000 @10000000000000000000000000
    ands r0, r1, r10           @ check msb for negative bit
    movne r0, r5               
    stmnefd sp!, {lr}
    blne twos_complement       @ twos complement fractional first number if its supposed to be negative
    ldmnefd sp!, {lr}
    movne r5, r0

    ands r0, r2, r10            @ check msb for negative bit
    movne r6, r0

    add r5, r5, r6              @ add the fractional portions

    ands r0, r5, r10            @ check msb to see if the result is negative
    movne r5, r0
    ldrne r0, =0x80000000      @  put a 1 as results msb if the result was negative
    moveq r0, #0               @ put a 0 as result msb if the result was positive

    mov r3, #0
    ldr r10, =0x80000000

count_sigbit_loop:
    cmp r10, r5
    addhi r3, r3, #1
    movhi r10, r10, lsr #1
    bhi count_sigbit_loop     

    cmp r3, #15                
    subhi r3, r3, #15         
    movhi r5, r5, lsl r3       @ shift as needed
    subhi r4, r4, r3           @subtract shift amount from exponent to reflect shift
    movcc r10, #15
    subcc r3, r10, r3          @ if shifting right
    movcc r5, r5, lsr r3       @ shift as needed
    addcc r4, r4, r3           @ add shift amount to exponent to relfect shift

    mov r4, r4, lsl #16        @  shift 
    orr r0, r0, r4            
    ldr r10, =0xFFFF
    and r5, r5, r10            @ get rid of implied 1 in fraction
    orr r0, r0, r5             @ attach fractional part
    POP {r0-r11}
    b add_complete
   


twos_complement:
    mvn r0, r0                 @negate r0
    add r0, r0, #1            @ add 1
    mOV pc, lr                @ Return 



LPFPmultiply:
    PUSH {r0-r11}

    and r3, r1, #0x80000000  @binary 10000000000000000000000000000000       
    and r4, r2, #0x80000000  @binary 10000000000000000000000000000000      

    eor r0, r3, r4                  @ get the new sign bit

    ldr r9, =0x7FFF0000 @01111111111111110000000000000000
    and r3, r1, r9               
    and r4, r2, r9                

    mov r3, r3, lsr #16
    mov r4, r4, lsr #16
    sub r3, r3, #16384    @ remove bias
    add r3,r3,#1
    sub r4, r4, #16384
    add r4,r4,#1

    add r5, r3, r4          

    ldr r9, =0xFFFF @00000000000000001111111111111111
    and r3, r1, r9                 @ extract fraction
    and r4, r2, r9                 @extract fraction
    orr r3, r3, #0x10000    @00000000000000010000000000000000    
    orr r4, r4, #0x10000     @00000000000000010000000000000000    


    stmfd sp!, {r3-r4, r8-r9}            
    mov r6, #0
    mov r7, #0                      
    mov r9, #0                   @emptying for result

mul:
    ands r8, r3, #1               
    beq no_add                     

    adds r7, r7, r4
    adc r6, r6, r9                 @ Add r4 to the low significance register if the LSB in r3 is a 1

no_add:
    mov r9, r9, lsl #1
    movs r4, r4, lsl #1
    adc r9, r9, #0                @Shift r4 to the left, move carry bit and add overflow into r9

    movs r3, r3, lsr #1            @ Shift r3 to the right and set flags
    bne mul                         

    ldmfd sp!, {r3-r4, r8-r9}     


creatfraction:
    ands r8, r6, #0x00008000   @00...01000000000000000  check to see if bit 16 of the hi bits 
    
   
    addne r5, r5, #1       
    movne r6, r6, lsl #16    
    movne r7, r7, lsr #16     
    
    
    moveq r6, r6, lsl #17     
    moveq r7, r7, lsr #15    
    
    
    orr r6, r6, r7           @put the fraction halves together
    mov r6, r6, lsr #15      @ make the fraction only use 15 bits
    bic r6, r6, #0x10000   @00000000000000010000000000000000     ; clear the implied 1 from the fraction

done:
    add r5, r5, #16384     @ re-add bias to the exponent
    sub r5,r5,#1
    mov r5, r5, lsl #16  
    orr r0, r0, r5          @ merge exponent into the result
    orr r0, r0, r6         @ merge fraction into the result 
    mov r1, r0
    POP {r2-r11}
    b finish


_start:
    b convert_num_1
    step2:
        b convert_num_2
    then_add:
        b LPFPadd
    add_complete:
        b LPFPmultiply
    finish:
        @done
        
    