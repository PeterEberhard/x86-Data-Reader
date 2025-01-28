# Peter Eberhard

.file "search.s"
.section .rodata
print_line_valid:
.string "search found a valid frame with %d samples\n"
print_line_invalid:
.string "search found a invalid frame with %d samples\n"
print_line_highest_average:
.string "search found the high frame has %d avg energy\n"
print_line_lowest_average:
.string "search found the low frame has %d avg energy\n"
print_line_no_lowest_average:
.string "search found no valid low frame\n"
print_line_no_highest_average:
.string "search found no valid high frame \n"
.section .text
.globl search
.type search, function


search:

# set up stack frame
pushq %rbp	
movq %rsp, %rbp


# count is in %rdi

# save rbx
pushq %rbx

# make rbx the adress of the first dataset struct
movq %rsi, %rbx

# save count so it doesnt get destroyed
pushq %r12 # keeps us 16 byte aligned
movl %edi, %r12d


# save another callee saved for highest average energy
pushq %r13
movl $-1, %r13d # 0 as max since its small and easy to detect
# save for lowest average energy
pushq %r14
movl $10000000, %r14d # 1 million as min since we want a really big value to get overwritten

# save r15 for frame pointer 
pushq %r15
xorq %r15, %r15

# 16 byte boundary fix
subq $8, %rsp

# set up loop for datasets
top_of_loop:
testl %r12d, %r12d # set z flag if count is 0
jz end_of_loop

# decrement count
decl %r12d

# grab address the loops correct dataset and put it in rax temporarily
movq (%rbx, %r12, 8), %rax

# set up second and third parameter
movl (%rax), %esi # place min from frame into second parameter
movl 4(%rax), %edx # place max from frame into third parameter

# put adress of dataset frme into first parameter
leaq 8(%rax), %rdi

# call a_shim
call a_shim

# start loading parameters into print here
movl (%rbx, %r12, 8), %r11d # move adress of correct dataset
# grab average energy from frame
movl 32(%r11d), %esi # 32 because 8 from dataset to get to f and then 24 to get to average energy

# temporarily use eax to determine if its valid or not since eax was the reutnr value of ashim
testl %eax, %eax

# fill the correct print statement
jz invalid # if valid is 0 we are invalid so jum
valid:


# since we know its valid, change maxes and mins
# now we need if our statement
# if average is greater than max, replace it
cmpl %esi, %r13d
# if max - average < 0 then average > max and we replace max with average
cmovs %esi, %r13d

# calculate adress of frame
leaq 8(%r11d), %rdi
cmovs %rdi, %r15 # if we picked a new max, replace our pointer with the new pointer

# if average is smaller than min, replace min
cmpl %r14d, %esi
cmovs %esi, %r14d

movq $print_line_valid, %rdi # add valid line to print parmeter

jmp end_of_if # skip else condition
invalid:
movq $print_line_invalid, %rdi # add invalid line to parameter
end_of_if:


# resuse esi since we are done
movl 8(%r11d), %esi # move sample count into second parameter


# parameters are set up so we call
call print



jmp top_of_loop # always jump to top to test condition again
end_of_loop:


# print out max

# first check if we have a valid max
testl %r13d, %r13d
jns valid_highest # if our max is negative, we never changed it so do invalid case
movq $print_line_no_highest_average, %rdi # set up invalid parameters
jmp ready_to_print_highest # skip valid case
valid_highest:
movq $print_line_highest_average, %rdi # set up valid parameters
movl %r13d, %esi # set up sample count
ready_to_print_highest:
call print # actually print

# print out min
movl $9999999, %edi
cmpl %edi, %r14d # if this number isnt negative, we never changed min so its invalid
jns invalid_lowest
movq $print_line_lowest_average, %rdi # set up valid print line
movl %r14d, %esi # set up sample count
jmp ready_to_print_lowest # skip else case
invalid_lowest:
movq $print_line_no_lowest_average, %rdi # set up invalid print line
ready_to_print_lowest:
call print


# return frame point
movq %r15, %rax

# replace callee saved
addq $8, %rsp
popq %r15
popq %r14
popq %r13
popq %r12
popq %rbx


leave
ret
.size search, .-search
