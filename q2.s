#
#   QUESTION 2
#       Applies prim's algorithm to a graph that's defined with its arcs as string.
#               Example arc: "node1_id node2_id arc_weight"
#
#   Info
#       It supports ids and weights up to 11 characters
#       Memory allocation is not dynamic, even the simplest graphs will use the same space as complex ones
#       Maximum number of nodes is limited
#
#       50 nodes max
#
#       Node
#           12b for id
#           4b for arc_arr_length
#           392b for arcs(49 arcs max per node)
#       Arc
#           4b for address it points to
#           4b for weight
#

        .data
buf:    .space 20000                    # buffer that will store the input string

comp:   .space 12                       # buffer for string comparison
visit:  .byte 0:64                      # which nodes are visited, 0 initialized
search: .word -1:64                     # search for small weight in this array of indexes, -1 initialized

str1:   .asciiz "Enter the graph: "
str2:   .asciiz "\nMinimum Spanning Tree:\n"
str3:   .asciiz "Total weight is "
str4:   .asciiz "Starting node: "
nextl:  .asciiz "\n"

        .text
        .globl main
main:
        addi $sp, $sp, -52              # reserve space for registers about to be saved
        sw $s0, 0($sp)
        sw $s1, 4($sp)
        sw $s2, 8($sp)
        sw $s3, 12($sp)
        sw $s4, 16($sp)
        sw $s5, 20($sp)
        sw $s6, 24($sp)
        sw $s7, 28($sp)
        sw $a0, 32($sp)
        sw $a1, 36($sp)
        sw $a2, 40($sp)
        sw $a3, 44($sp)
        sw $ra, 48($sp)                 # register values from former procedure is pushed onto stack, must reverted at the end of execution

        li $v0, 4
        la $a0, str1                    # print first string
        syscall                         # execute print_string

        addi $sp, $sp, -20400           # total memory reserved for node array, (49*8+12+4) * 50
        sw $zero, -4($sp)               # total weight is stored here

        add $s0, $zero, $zero           # l = 0, s0 is where we keep the current length of node array
        add $s1, $zero, $zero           # i = 0
        add $s2, $zero, $zero           # j = 0
        add $s3, $zero, $zero           # k = 0
        add $t8, $zero, $zero           # node1 address
        add $t9, $zero, $zero           # node2 address


        li $v0, 8                       # select read_string mode
        li $a1, 32000                   # max string length to be read is 32000
        la $a0, buf                     # save read input into buf
        syscall                         # execute read_string

        li $v0, 4
        la $a0, nextl                   # print nextline
        syscall

        la $s4, buf                     # s4 = &buf
        la $s5, comp                    # s5 = &comp
        add $s6, $zero,$zero            # mode = 0, possible values are (0, 1, 2)
        add $t7, $zero, $zero


parse:
        add $t0, $s4, $s1               # t0 = &buf[i]
        addi $s1, $s1, 1                # i++, this incremented before the branch, because in the next iteration we want to start from the character that comes after space
        add $t1, $s5, $s2               # t1 = &comp[j]
        lb $t0, 0($t0)                  # t0 = buf[i-1]
        addi $t2, $zero, 32             # decimal value of space in ascii encoding, t2 = 32
        addi $t3, $zero, 10             # decimal value of newline in ascii encoding, t2 = 10
        beq $t0, $t3, graph_done        # branch if we reached the end of input string and apply prim's algorithm
        beq $t0, $t2, proc_init         # branch if encountered with space
        sb $t0, 0($t1)                  # comp[j] = buf[i-1]
        addi $s2, $s2, 1                # j++
        j parse

graph_done:
        addi $t7, $zero, 1              # t7 = 1, we set this to signal that all graph data is now in memory

proc_init:
        sb $zero, 0($t1)                # add null byte to the end of string in comp
        addi $t2, $zero, 2              # t2 = 2
        beq $s6, $t2, str2int           # if (mode == 2) branch, if not this means mode is 0 or 1 and we are currently reading first or second node id
        add $s2, $zero, $zero           # j = 0
        add $s3, $zero, $zero           # k = 0

proc:                                   # processing cached piece of string before reading the next one
        beq $s3, $s0, add_new_node      # are we at the end of node array, if we are, exit loop(proc) and add new node
        addi $t1, $zero, 408            # space used by an element of node array, n = 408
        mult $t1, $s3
        mflo $t1                        # distance between current node and sp, t1 = k*n
        add $t1, $sp, $t1               # address of current node, t1 = sp + k*n, t1 = &node_arr[k]

        add $t2, $t1, $s2               # t2 = address of j'th byte from &node_arr[k]
        add $t3, $s5, $s2               # t3 = address of j'th byte of comp
        lb $t2, 0($t2)                  # t2 = j'th byte from &node_arr[k]
        lb $t3, 0($t3)                  # t3 = j'th byte of comp

        or $t4, $t2, $t3                # t4 can be 0 iff both bytes are 0, if t4 is 0, this means that we are at the end of both ids and there hasn't been any char mismatch
        beq $t4, $zero, id_match        # jump to id_match if (t4 == 0), this branch is one of the two possible exits from this loop(proc)

        addi $s2, $s2, 1                # j++

        # if (chr1 == chr2)
        beq $t2, $t3, proc              # chars are same, jump back to proc to continue comparing chars
        # else
        add $s3, $s3, 1                 # k++, char mismatch occurred between node ids, continue comparing from next node
        add $s2, $zero, $zero           # j = 0
        j proc

str2int:
        # should be t0 = weight at the end
        # s2 is index that shows null byte end of comp string rn

        add $t0, $zero, $zero           # t0 = 0
        addi $t1, $zero, 1              # t1 = 1, multiplier
        addi $t3, $zero, 0              # t3 = 0, needed to check if we pass the head of string
        addi $t4, $zero, 10             # t4 = 10

str2int_loop:
        beq $s2, $t3, save              # if all chars read, integer value of weight should be at $t0, jump and add arcs to nodes
        addi $s2, $s2, -1               # j--
        add $t2, $s5, $s2               # t2 = &comp[j]
        lb $t2, 0($t2)                  # t2 = comp[j]
        addi $t2, $t2, -48              # ascii to integer
        mult $t2, $t1
        mflo $t2                        # t2 = comp[j] * multiplier
        add $t0, $t0, $t2               # t0 = t0 + t2
        mult $t1, $t4
        mflo $t1                        # multiplier = multiplier * 10
        j str2int_loop

add_new_node:
                                        # j is 0 right now!
        addi $t0, $zero, 408            # n = 408
        mult $t0, $s0
        mflo $t0                        # t0 = n*l
        add $t0, $t0, $sp               # t0 = sp + n*l, end of the node_arr, this is where we add the next node
        addi $s0, $s0, 1                # l++, add 1 to length of node_arr
        addi $t3, $zero, 12             # constant 12 needed for exit control of loop(write_new_id)
        sw $zero, 12($t0)               # initialize arc_arr length with 0

write_new_id:
        add $t1, $s5, $s2               # t1 = address of j'th element of comp
        lb $t1, 0($t1)                  # t1 = j'th element of comp
        add $t2, $t0, $s2               # t2 = address of j'th byte from start of new node
        sb $t1, 0($t2)                  # byte stored in id section of new node
        addi $s2, $s2, 1                # j++
        beq $s2, $t3, save              # exit loop(write_new_id) if 12 chars written to id section of new node
        j write_new_id

id_match:
        # ids are matched save node address to $t0

        addi $t0, $zero, 408            # t0 = 408
        mult $t0, $s3
        mflo $t0                        # t0 = k*408
        add $t0, $t0, $sp               # t0 = k*408 + sp



save:
        add $s2, $zero, $zero           # j = 0, it needs to be 0 in the next iteration
        add $s3, $zero, $zero           # k = 0, next time we search for an id, we should start from beginning of node_arr
        beq $s6, $zero, save0           # if (mode == 0), save node_arr index as first node, store in $t8
        addi $t2, $zero, 1              # t2 = 1
        beq $s6, $t2, save1             # if (mode == 1), save node_arr index as second node, store  in $t9
        addi $t2, $t2, 1                # t2 = 2
        beq $s6, $t2, save2             # if (mode == 2), add arc to nodes, arc weight stored in $t8


save0:                                  # save first node address
        add $t8, $t0, $zero             # t8 = first node address
        addi $s6, $s6, 1                # mode++
        j parse

save1:                                  # save second node address
        add $t9, $t0, $zero             # t9 = second node address
        addi $s6, $s6, 1                # mode++
        j parse

save2:                                  # add arcs
        # t0 = weight
        # t8 = &first_node
        # t9 = &second_node

        addi $t1, $zero, 12             # t1 = 12, space of node_id string
        addi $t3, $zero, 8              # t3 = 8, space of an element of arc_arr
        addi $t4, $zero, 4              # t4 = 4, space of arc_arr_length
        add $t1, $t1, $t8               # address of arc_arr_length of first node
        lw $t2, 0($t1)                  # load arc_arr_length
        mult $t3, $t2
        mflo $t5                        # t5 = 8*arc_arr_length
        add $t6, $t5, $t1               # t6 = 8*arc_arr_length + 12
        add $t6, $t6, $t4               # t6 = 8*arc_arr_length + 12 + 4, this is where we add new arc data (&second_node, weight)
        sw $t9, 0($t6)                  # &second_node saved
        sw $t0, 4($t6)                  # weight saved
        addi $t2, $t2, 1                # arc_arr_length++
        sw $t2, 0($t1)                  # update old arc_arr_length value
                                        # arc data added to first node


        addi $t1, $zero, 12             # t1 = 12
        add $t1, $t1, $t9               # address of arc_arr_length of second node
        lw $t2, 0($t1)                  # load arc_arr_length
        mult $t3, $t2
        mflo $t5                        # t5 = 8*arc_arr_length
        add $t6, $t5, $t1               # t6 = 8*arc_arr_length + 12
        add $t6, $t6, $t4               # t6 = 8*arc_arr_length + 12 + 4, this is where we add new arc data (&first_node, weight)
        sw $t8, 0($t6)                  # &second_node saved
        sw $t0, 4($t6)                  # weight saved
        addi $t2, $t2, 1                # arc_arr_length++
        sw $t2, 0($t1)                  # update old arc_arr_length value
                                        # arc data added to second node

        add $s6, $zero, $zero           # mode = 0

        bne $t7, $zero, prim            # if (t7 != 0) all graph data obtained, begin solving
        j parse


prim:
        # At this point all the node and arc data are in the stack (from sp to sp + s0*408)
        # s0 = length of node_arr
        # visit = flag array, once a node visited its flag will be set
        # we will search for the smallest weighted arc over ALL visited nodes

        # this version of mips/spim might not support it at all(syscall 30, 41, 42 raises unknown error)

        # lehmer pseudorandom number generator (it will possibly give different numbers for different graphs)
        # x_n+1 = (x_n*a + c) mod m

        addi $t0, $sp, -300             # some place in stack
        lw $t0, 0($t0)
        div $t0, $s0
        mfhi $t0                        # remainder of t0/s0, will be used as seed (x_0)
        addi $t1, $zero, 5              # t1 = 5, iteration count
        add $t2, $zero, $zero           # t2 = 0, loop counter
        addi $t3, $zero, 16807          # t3 = 16807, a = 7**5
        addi $t4, $zero, 1331           # t4 = 1331, c = 11**3
        addi $t5, $zero, 71             # t5 = 71, m

prng:
        beq $t2, $t1, prng_exit
        mult $t0, $t3
        mflo $t0                        # t0 = x_n * a
        add $t0, $t0, $t4               # t0 = x_n * a + c
        div $t0, $t5
        mfhi $t0                        # t0 = (x_n * a + c) mod m
        addi $t2, $t2, 1                # t2++
        j prng

prng_exit:
        div $t0, $s0
        mfhi $t0                        # t0 = (t0) mod s0, random number must be between 0 and s0

        addi $t1, $zero, 408            # t1 = 408
        mult $t0, $t1
        mflo $t1                        # t1 = 408*t0
        add $t1, $t1, $sp               # t1 = sp + 408*t0

        li $v0, 4
        la $a0, str4                    # print starting node string
        syscall

        add $a0, $zero, $t1             # a0 = address of random node's id
        syscall                         # print starting node id

        la $a0, nextl
        syscall                         # print nextline

        la $a0, str2                    # print min span tree text
        syscall

        addi $s0, $s0, -1               # s0 was indirectly pointing to the end(just outside) of the array, by subtracting 1, we make the equation on the right valid (&last_node = sp + 408*s0)
        la $s5, search                  # we no longer need address of comp, s5 = &search

        la $s7, visit                   # s7 = &visit
        add $t0, $s7, $t0               # t0 = &visit + q
        addi $t1, $zero, 1              # t1 = 1
        sb $t1, 0($t0)                  # visit[q] = 1
                                        # random node selected

next_step:                              # we need to reset counters between iterations
        add $s1, $zero, $zero           # i = 0
        add $s2, $zero, $zero           # j = 0
        add $s3, $zero, $zero           # k = 0
        addi $t1, $zero, 1              # t1 = 1
        addi $t3, $zero, 60             # t3 = 60, parse visit array to find visited nodes till j hits 60
        addi $t7, $zero, -1             # t7 = -1

parse_visit:
        add $t0, $s7, $s2               # t0 = &visit[j]
        lb $t0, 0($t0)                  # t0 = visit[j]

        beq $s2, $t3, begin_search      # if (j == 60) begin searching for the smallest weight
        beq $t0, $t1, add_to_search     # if (visit[j] == 1) we add it's index(j) to search array
        addi $s2, $s2, 1                # j++
        j parse_visit

add_to_search:
        add $t2, $s5, $s3               # t2 = &search[k]
        sw $s2, 0($t2)                  # j value stored in search array
        addi $s3, $s3, 4                # k++
        addi $s2, $s2, 1                # j++
        j parse_visit

begin_search:
        # actual searching part
        # we should only search for arcs that points from "visited nodes to unvisited nodes"
        # t0-9, s0-4, s6 is free now

        add $s2, $zero, $zero           # j = 0
        add $s3, $zero, $zero           # k = 0

        # start of parsing search array. every node will be processed until -1 encountered, k is search array index, outer loop

        j skip_inc_k

next_node:
        addi $s3, $s3, 4                # k++

skip_inc_k:
        add $t0, $s5, $s3               # t0 = &search[k]
        lw $t0, 0($t0)                  # t0 = search[k]

        slt $t1, $t0, $zero             # if (search[k] < 0) we parsed all nodes in search array
        bne $t1, $zero, search_res_init # jump to reset search array and proceed to next iteration of prim

        addi $t1, $zero, 408            # t1 = 408
        mult $t1, $t0
        mflo $t1                        # t1 = 408*search[k]
        add $t1, $t1, $sp               # t1 = sp + 408*search[k]
        addi $t1, $t1, 12               # t1 = sp + 408*search[k] + 12
        lw $t2, 0($t1)                  # t2 = arc_arr_length of node search[k]
        addi $t1, $t1, 4                # t1 = sp + 408*search[k] + 12 + 4, start of arc_arr of node search[k], &arc_arr[0]

        # address and length of arc_arr found, t2 length, t1 address, start parsing arc_arr, l is arc_arr index, inner loop

        add $s0, $zero, $zero           # l = 0
        j skip_inc_l

next_arc:
        addi $s0, $s0, 1                # l++

skip_inc_l:

        beq $s0, $t2, next_node

        addi $t3, $zero, 8              # t3 = 8
        mult $t3, $s0
        mflo $t3                        # t3 = 8*l

        add $t3, $t1, $t3               # t3 = &arc_arr[8*l]
        lw $t4, 0($t3)                  # t4 = arc_arr[8*l][0], where the arc points to
        sub $t5, $t4, $sp               # t5 = t4 - sp, space between sp and pointed node
        addi $t6, $zero, 408            # t6 = 408
        div $t5, $t6
        mflo $t5                        # t5 = index of pointed node

        # index found, check if visited

        add $t6, $s7, $t5               # t6 = &visit[l]
        lb $t6, 0($t6)                  # t6 = visit[l]
        bne $t6, $zero, next_arc        # if (visit[l] != 0), if branch taken, means that pointed node already visited, therefore it's not valid, check next_arc
        lw $t4, 4($t3)                  # else, t4 = arc_weight, pointed node is valid

        slt $t8, $t7, $zero             # t8 = t7 < 0 ? 1 : 0, if t7 is negative its the first arc we found
        beq $t8, $zero, no_init         # skip initialize min
        add $t7, $t4, $zero             # t7 = t4, min_w = arc_weight

no_init:
        slt $t8, $t4, $t7               # t8 = t4 < min_w ? 1 : 0
        beq $t8, $zero, next_arc        # if (arc_weight >= min), check next_arc
        add $t7, $zero, $t4             # else, min_w = t4

        # data for output saved to stack, this data will be overwritten in case arc with smaller weight is found, will be converted to ascii at the end of iteration

        sw $t0, -8($sp)                 # store index of first node, already visited
        sw $t5, -12($sp)                # store index of second node, will be visited next
        sw $t7, -16($sp)                # store weight of chosen arc
        j next_arc

search_res_init:

        slt $t8, $t7, $zero             # t8 = t7 < 0 ? 1 : 0
        bne $t8, $zero, exit            # if t7 still negative after an iteration, there is no arc left to follow

        add $s2, $zero, $zero           # j = 0

        # now we must set visit[l] to 1, save arc info to buffer and add weight to total weight

        lw $t0, -8($sp)                 # t0 = node1_index
        lw $t5, -12($sp)                # t5 = node2_index
        add $t4, $s7, $t5               # t4 = &visit[l]
        addi $t6, $zero, 1              # t6 = 1
        sb $t6, 0($t4)                  # visit[l] = 1

        lw $t6, -4($sp)                 # t6 = total_weight
        lw $t4, -16($sp)                # t4 = new_weight
        add $t6, $t6, $t4               # t6 = total_weight + new_weight
        sw $t6, -4($sp)                 # store total_weight again

        la $s0, buf                     # s0 = &buf

        addi $s3, $zero, 408            # k = 408
        mult $t0, $s3
        mflo $t0                        # t0 = node1_index * 408
        add $t0, $t0, $sp               # t0 = &node1_id, sp + node1_index * 408
        mult $t5, $s3
        mflo $t5                        # t5 = node2_index * 408
        add $t5, $t5, $sp               # t5 = &node2_id, sp + node2_index * 408

node_copy1:
        add $t1, $s0, $s1               # t1 = &buf[i]
        add $t2, $t0, $s2               # t2 = &node1_id[j]
        lb $t2, 0($t2)                  # t2 = node1_id[j]
        beq $t2, $zero, end_copy1       # if t2 is null, then we are at the end of node1_id
        sb $t2, 0($t1)                  # else buf[i] = node1_id[j]
        addi $s1, $s1, 1                # i++
        addi $s2, $s2, 1                # j++
        j node_copy1

end_copy1:
        addi $t3, $zero, 32             # t3 = 32
        sb $t3, 0($t1)                  # add space next to node1_id
        addi $s1, $s1, 1                # i++
        add $s2, $zero, $zero           # j = 0

node_copy2:
        add $t1, $s0, $s1               # t1 = &buf[i]
        add $t2, $t5, $s2               # t2 = &node2_id[j]
        lb $t2, 0($t2)                  # t2 = node2_id[j]
        beq $t2, $zero, end_copy2       # if t2 is null, then we are at the end of node2_id
        sb $t2, 0($t1)                  # else buf[i] = node2_id[j]
        addi $s1, $s1, 1                # i++
        addi $s2, $s2, 1                # j++
        j node_copy2

end_copy2:
        addi $t3, $zero, 32             # t3 = 32, ascii value of space character
        sb $t3, 0($t1)                  # add space next to node2_id
        addi $t1, $t1, 1                # t1++
        sb $zero, 0($t1)                # add null byte after node ids

        li $v0, 4                       # load print_string
        la $a0, buf                     # print buf
        syscall                         # execute print_string, now we just printed "node1_id node2_id ", still need to print weight

        li $v0, 1                       # select print_int
        add $a0, $t4, $zero             # print new_weight
        syscall                         # execute print_int, still need to print nextl

        li $v0, 4
        la $a0, nextl                   # print nextl
        syscall                         # now we printed ids and arc weight

        # for next iteration
        add $s1, $zero, $zero           # i = 0
        add $s2, $zero, $zero           # j = 0

        # initialize some values to reset search array
        add $s3, $zero, $zero           # k = 0, loop counter
        addi $t4, $zero, -1             # t4 = -1, will be used to reset every value of search array
        addi $t5, $zero, 240            # t5 = 240, reset values till counter hits 240

search_reset:
        add $t6, $s5, $s3               # t6 = &search[k]
        sw $t4, 0($t6)                  # search[k] = -1
        addi $s3, $s3, 4                # k++
        bne $s3, $t5, search_reset      # if (k != 60) continue
        j next_step

exit:
        li $v0, 4
        la $a0, str3                    # print last string
        syscall                         # execute print_string

        li $v0, 1
        lw $a0, -4($sp)                 # address of total_weight
        syscall                         # execute print_int

        li $v0, 4
        la $a0, nextl                   # print nextline
        syscall

        # return registers and stack space

        addi $sp, $sp, 20300            # space that hold graph data

        lw $s0, 0($sp)
        lw $s1, 4($sp)
        lw $s2, 8($sp)
        lw $s3, 12($sp)
        lw $s4, 16($sp)
        lw $s5, 20($sp)
        lw $s6, 24($sp)
        lw $s7, 28($sp)
        lw $a0, 32($sp)
        lw $a1, 36($sp)
        lw $a2, 40($sp)
        lw $a3, 44($sp)
        lw $ra, 48($sp)                 # register values from former procedure back in register
        addi $sp, $sp, 52               # stack space returned

        li $v0, 10
        syscall                         # end procedure
