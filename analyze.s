# PETER EBERHARD

# begin analyse v1

.file "analyze.s"
.section .text
.globl analyze
.type analyze, function

analyze:
# set up stack frame 
pushq %rbp	
movq %rsp, %rbp

# grab pcm data one at a time and convert to energy
# to get to pcm data we have to do pointer math on the value we grab since theres only 1 8 byte pointer in the struct
# move *pcm to %r8
movq 8(%rdi), %r8

# place anergy array adress into rcx
leaq 28(%rdi), %rcx

xorq %r10, %r10
xorq %r11, %r11

# to begin our for loop we need to figure out what count to use
# let %r10d be count
movl $16, %r10d
# move count to a regiuster since we will use twice
movl (%rdi), %r11d
# this compares count - 16
cmpl %r10d, %r11d
cmovs %r11d, %r10d
# new count is now the smallest of 16 and old count
# new count is in %r10d

# 0 out r9 and r11 for future use
xorq %rax, %rax
xorq %r11, %r11

# store original count for use in average later
movl %r10d, %r9d


# begin loop
loop_start:
testl %r10d, %r10d
jz end_of_loop

# grab pcm data, we can reuse r11d since we are done with old count
# TODO check if you can use half registers
# start at r8, move count  number of words so we scale by 2 since words are 2 bytes
# swl suffix because we are sign extending, word to long
movswl (%r8), %r11d
addq $2, %r8
# now we square it
imull %r11d, %r11d
# sign extend even though we will always have positive numbers since they arnt unsigned ints.
# extend so we can add to our total which is 8 bytes
movslq %r11d, %r11
# add energy to total energy
addq %r11, %rax
# now we have to put it back into memory
# write pcm squared to memory at rcx which will update as we increment it
movl %r11d, (%rcx)
addq $4, %rcx

# decrement count
decl %r10d
jmp loop_start

end_of_loop:
# done with loop so add the total energy
movq %rax, 16(%rdi)

# save high threshold in rdx before we divide
# we can overwtie r8 since we dont need pcm data anymore
movq %rdx, %r8

# divide to get average
cqto # sign extend rax
idivq %r9 # divide rax (total) by r10, count. This is the average

logic:
# place average in struct
# treat it as an int because it will likely be small enough
movl %eax, 24(%rdi)

# now mark the fram as valid or not
# this computer average - min threshold
cmpl %esi, %eax
# if we get a negative, min is bigger, so jump to invalid
js invalid
# computes max - average
cmpl %eax, %r8d
# if we get a negative, average is bigger, so jump to invalid
js invalid

# set struct to true
movl $1, 4(%rdi)
# set rax to true
movq $1, %rax
jmp done
invalid:
# set value in struct to false
movl $0, 4(%rdi)
# set rax to false
xorq %rax, %rax

done:
leave
ret
.size analyze, .-analyze


