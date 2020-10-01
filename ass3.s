section .rodata
    global format_d_in
    format_d_in: db "%d", 0
    global format_f_in
    format_f_in: db "%f", 0
    global format_d
    format_d: db "%d, ", 0
    global format_f
    format_f: db "%.02lf, ", 0
    global format_f_n
    format_f_n: db "%.02lf ", 10, 0
    global format_d_n
    format_d_n: db "%d", 10, 0 
    global MAX_SHORT
    MAX_SHORT: dd 65535
    global board_bound
    board_bound: dd 100
    global MAX_DEGREE
    MAX_DEGREE: dd 360
    global ONE_TWENTY
    ONE_TWENTY: dd 120
    global SIXTY
    SIXTY: dd 60
    global FIFTY
    FIFTY: dd 50
    global TWO
    TWO: dd 2
    global ONE_EIGHTY
    ONE_EIGHTY: dd 180
    global ZERO
    ZERO: dd 0
    global stack_size
    stack_size: dd 16384
    global str
    str: db "%s", 0         ; format string without \n
    global winner_str1
    winner_str1: db "Drone id <",0
    global winner_str2
    winner_str2: db ">: I am winner",10,0
    
    ; constant offsets for drones_structs
    global X_p
    X_p: dd 0  
    global Y_p
    Y_p: dd 10
    global HEAD_p
    HEAD_p: dd 20
    global score_p
    score_p: dd 30
    
section .data                       ; global read-only variabls
    global N
    N: dd 0                         ; number of drones 
    global T
    T: dd 0                         ; number of targest needed to destroy in order to win the game 
    global K
    K: dd 0                         ; how many drone steps between game board printings 
    global B
    B: dd 0                         ; angle of drone field-of-view
    global d
    d: dd 0                         ; maximum distance that allows to destroy a target 
    global seed
    seed: dd 0                      ; seed for initialization of LFSR shift register
    global numco
    numco: dd 0                     ; number of co-rutines= N+3 (target, printer, scheduler)
    global drones_structs
    drones_structs: dd 0            ; pointer to array of drones struct (x,y,alpha...)
    global target
    target: dd 0                    ; pointer for the target
    global cors
    cors: dd 0                      ; pointer to co-routines array
    global stack_pointers_backup
    stack_pointers_backup: dd 0     ; array of stack pointers , for free after malloc (because when init the stacks we are changing the stack pointer)
    global SPT
    SPT: dd 0                       ; temp stack pointer
    global SPMAIN
    SPMAIN: dd 0                    ; keep esp of main in startCo
    global k_counter
    k_counter: dd 0                 ; counting game steps for printing board
    global curr_id
    curr_id: dd 1                   ; keep courrent drone's id which the scheduler made resume  
    global delta_alpha
    delta_alpha: dt 0.0             ; keep the value of delta alpha in drone's func
    global distance
    distance: dt 0.0                ; keep the distance
    global gamma
    gamma: dt 0.0
    global destroy_flag
    destroy_flag: dd 0              ;
    global power2
    power2: dt 0.0
    global drone_score
    drone_score: dd 0               ; for increment the drone score
   
    
section .text
    global main
    global random
    global scaling_position
    global scaling_head
    global scaling_delta_alpha
    global scaling_distance
    global printer
    global endCo
    global resume
    global do_resume
    global createTarget
    global mayDestroy

    extern free
    extern sscanf
    extern malloc
    extern printf
    extern drone_func
    extern target_func
    extern scheduler_func
    extern printer_func
    
    

; macro for sscanf for the arguments of main
; arg1 = N\T\K\B\d\seed
; arg2 = i - index for cell in argv 
; arg3 = format
%macro args_input 3    
    mov ecx, dword [ebx+4*%2]   ; put in ecx pointer to string of arg1
    push ebx                    ; backup pointer to argv befor sscanf
    push %1                     ; third argument for sscanf for keep result
    push %3                     ; second argument for sscanf
    push ecx                    ; first argument for sscanf
    call sscanf
    add esp, 12                 ; pop arguments from sscanf
    pop ebx                     ; restor argv pointer
%endmacro

; macro for printf for board printing
%macro print_float 0
    push ebx                            ; backup ebx before printf
    push eax                            ; backup eax before printf
    push ecx                            ; backup ecx before printf
    sub esp,8                           ; make place for 8 bytes value in stack
    fstp qword [esp]                    ; push seconed argument for printf to stack, the float number
    push format_f                       ; push first argument for printf
    call printf                         ; print X\Y\head
    add esp, 12                         ; pop arguments for printf
    pop ecx                             ; restore ecx 
    pop eax                             ; restore eax
    pop ebx                             ; restore ebx
%endmacro
    
    
main:
    push ebp
    mov ebp, esp
    pushad
    
    mov edx, dword [ebp+8]                  ; move argc to edx
    cmp edx, 6
    jz end_main
    ; check if there are enugh arguments in input 
    mov ebx, dword [ebp+12]                 ; put the pointer to argv
    args_input N,1,format_d_in              ; call macro for sscanf N
    args_input T,2,format_d_in              ; call macro for sscanf T
    args_input K,3,format_d_in              ; call macro for sscanf K
    args_input B,4,format_d_in              ; call macro for sscanf B
    args_input d,5,format_d_in              ; call macro for sscanf d
    args_input seed,6,format_d_in           ; call macro for sscanf seed
    mov ebx, dword [N]                      ; put in ebx number of drones co-rutine
    add ebx, 3                              ; add 3 for more 3 co-rutines (target, printer, scheduler)
    mov dword [numco], ebx                  ; put in [numco] the number of co-rutines
    call _init
    call startCo                            ; activate scheduler co-routine
    call free_memory
    
    end_main:
    popad
    mov esp, ebp
    pop ebp
    ret
    
    
_init:
    push ebp
    mov ebp, esp
    pushad
    
    ;~~~~~~~~~~~~~~~~~cors (co-routines array) initialization~~~~~~~~~~~~~~~~
    mov eax, dword [numco]              ; put in eax the number of co-routines
    mov ebx, 4                          ; put 4 in ebx for multiply
    mul ebx                             ; numco*4 , result in eax
    push eax                            ; argument for malloc
    call malloc                         ; allocate memory for numco array
    mov [cors] , eax                    ; put in cors the pointer to co-routines array which malloc allocated
    add esp,4                           ; pop argument from malloc
    ;~~~~~~~~~~~~~~~~initialize stack_pointers_backup~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mov eax, dword [numco]              ; put in eax the number of co-routines
    mov ebx, 4                          ; put 4 in ebx for multiply
    mul ebx                             ; numco*4 , result in eax
    push eax                            ; argument for malloc
    call malloc                         ; allocate memory for numco array
    mov [stack_pointers_backup] , eax   ; put in stack_pointers_backup the pointer to array of stack pointers, for free them later
    add esp,4                           ; pop argument from malloc
    ;~~~~~~~~~~~~~~~~end of initialize stack_pointers_backup~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~initialize scheduler co-routine's stack~~~~~~~~~~~~~~~~~~~~
    mov ecx, 0                          ; loop counter
    push ecx                            ; argument for the scheduler_co_init - id = N+2
    call scheduler_co_init              ; initialize stack of scheduler co-routine
    add esp, 4                          ; pop argument
    inc ecx                             ; loop counter for drones_cors_loop == 1
    ;~~~~~~~~~~~~~~~~end of initialize scheduler co-routine's stack~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~loop for initialize drones co-rutines stacks~~~~~~~~~~~~~~~~~~~~
    drones_cors_loop:
    push ecx                            ; argument for the drone_co_init - id
    call drone_co_init                  ; initialize stack of drone co-routine
    add esp, 4                          ; pop argument
    inc ecx                             ; increment loop counter
    mov edx, dword [N]                  ; mov edx N for cmp the loop counter to N+1
    inc edx                             ; inc edx to be N+1
    cmp ecx, edx                        ; check if the the loop was done N times
    jnz drones_cors_loop                ; if not , go back to drones_cors_loop
    ;~~~~~~~~~~~~~~end of initialize drones co-rutines stacks~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~initialize target&printer co-routines stacks~~~~~~~~~~~~~~~~~~~~
    push ecx                            ; argument for the target_co_init - id = N+1 (because N was the last drone co-routine id)
    call target_co_init                 ; initialize stack of target co-routine
    add esp, 4                          ; pop argument
    inc ecx                             ; inc id
    push ecx                            ; argument for the printer_co_init - id = N+2
    call printer_co_init                ; initialize stack of printer co-routine
    add esp, 4                          ; pop argument
    ;~~~~~~~~~~~~~~~~end of initialize target&printer co-routines stacks~~~~~~~~~~~~~~~~

    
    ;~~~~~~~~~~~~~~~~~~~~~~target initialization~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mov eax, 20                         ; put 20 in eax for malloc
    push eax                            ; argument for malloc , 20 bytes (X and Y 10 bytes each)
    call malloc                         ; allocate space for target
    add esp, 4                          ; pop argument from malloc
    mov dword [target], eax             ; put in target the adress that malloc was allocating
    call createTarget                   ;
    
    
    ; ~~~~~~~~~~~~~~~~~~~~drones_structs initialization~~~~~~~~~~~~~~~~~~~~~~
    mov eax, dword [N]                  ; put in eax the number of drones for multiply with 4
    mov ebx, 4                          ; put 4 in ebx
    mul ebx                             ; N*4 , result in eax
    push eax                            ; argument for malloc 
    call malloc                         ; allocate memory for N drones    
    mov [drones_structs], eax           ; put the pointer for the array in drones_structs
    add esp,4                           ; pop argument of malloc
    mov ecx, 0                          ; init_drones_loop counter
    init_drones_loop:                   ; initialize every one of the N drone's struct
    push ecx                            ; drone's id - argument for the drone_struct_init
    call drone_struct_init              ; initialize drone numbber id (ecx) 
    pop ecx                             ; pop argument
    inc ecx                             ; increment loop counter
    cmp ecx, dword [N]                  ; check if loop counter equals N (numebr of drones)
    jnz init_drones_loop                ; if not , go back to init_drones_loop
    
    
    popad
    mov esp, ebp
    pop ebp
    ret
; end of _init
    
    
drone_struct_init:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, dword [ebp+8]              ; put in ecx the id of the drone
    push ecx                            ; backup before malloc
    push 34                             ; argument for malloc , 34 bytes for every drone (X and Y and alpha are tb = 10 byte and score 4 byte)
    call malloc                         ;
    add esp, 4                          ; pop argument
    pop ecx                             ; restore after malloc
    mov ebx, dword [drones_structs]     ; put in ebx the pointer to the drones array first cell
    mov [ebx+4*ecx], eax                ; put in ebx the pointer to the right drone cell in the array , for put the strcut adress from the malloc
    ;~~~~~~~~~~~~~~eax points to the begining of the strcut (returned from malloc)~~~~~~~~~~~~~~~~~~~~~~~~ 
    call random                         ; randomize a random 16 bit number into seed
    push eax                            ; argument for scaling_position - pointer to the X position in the drone struct - which has returned from malloc
    call scaling_position               ; scaling the position and put it in the X position in the drone's struct 
    add esp, 4                          ; pop the argument
    call random                         ; randomize a random 16 bit number into seed
    mov ebx, eax                        ; 
    add ebx, dword [Y_p]                ; move ebx to point the Y position in the drone's strcut
    push ebx                            ; argument for scaling_position - pointer to the Y position in the drone struct
    call scaling_position               ; scaling the position and put it in the Y position in the drone's struct
    add esp, 4                          ; pop the argument
    call random                         ; randomize a random 16 bit number into seed
    mov ebx, eax                        ;
    add ebx, dword [HEAD_p]             ; move ebx to point the head (angle) in the drone's strcut
    push ebx                            ; argument for scaling_head - pointer to the head (angle) in the drone struct
    call scaling_head                   ; scaling the angle and put it in the head(angle) in the drone's struct
    add esp, 4                          ; pop argument
    mov ebx, 0                          ; put 0 in ebx for initialize the score
    add eax, dword [score_p]
    mov [eax], dword ebx                ; initialize the score value in the strcut with 0
    
    popad
    mov esp, ebp
    pop ebp
    ret

; function for random number in LFSR method, put the result in [seed]    
random:
    push ebp
    mov ebp, esp
    pushad
    
    mov edx, 16                 ; put counter for the loop in edx 
    random_loop:
    mov ebx, dword [seed]       ; put in ebx seed for bit wise AND with 45 - 101101
    mov ecx, dword [seed]       ; put in ecx seed 
    and ebx, 45                 ; bit wise AND
    jp even_ones                ; if the number of ones in ebx in the first 8 bytes is even
    shr cx, 1                   ; if the number of ones in bx is even , put 0 is the
    add cx, 32768               ; if the number of ones is odd , put 1 in the 16 byte , 32768 = 2^15
    jmp random_result           ; jump for not doing the even_ones case
    even_ones:
    shr cx, 1                   ; if the number of ones in bx is even , put 0 is the
    random_result:
    mov [seed], ecx             ; put in seed the new random number
    dec edx                     ; decrement the counter of the loop
    cmp edx, 0                  ; check if the loop was done 16 times
    jnz random_loop             ; if not go back to random_loop
    
    popad
    mov esp, ebp
    pop ebp
    ret
    
scaling_position:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                 ; load argument - pointer to the right position in the drone struct
    finit                            ; initialize x87 stack
    fild dword [seed]                ; laod into x87 stack the seed to ST0
    fdiv dword [MAX_SHORT]           ; divied seed\MAX_SHORT , and result is in ST0
    fmul dword [board_bound]         ; multiply the result with 100 , store the result in ST0
    fstp tword [ecx]                 ; put the scaling result in the right position in the drone struct (X or Y)

    popad
    mov esp, ebp
    pop ebp
    ret
    
scaling_head:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                ; load argument - pointer to the angle in the drone struct
    finit                           ; initialize x87 stack
    fild dword [seed]               ; laod into x87 stack the seed to ST0
    fdiv dword [MAX_SHORT]          ; divied seed\MAX_SHORT , and result is in ST0
    fmul dword [MAX_DEGREE]         ; multiply the result with 360 , store the result in ST0
    ;~~~~~~~~~~~~convert the degree to radians~~~~~~~~~~~~~~~~
    fldpi                           ; put in ST0 pi , the result of the scaling in ST1
    fmulp                           ; multiply scaling result * pi ( ST0*ST1) , and result in ST0
    fild dword [ONE_EIGHTY]         ; put 180 in ST0 , previus result go to ST1
    fdivp                           ; divied (scaling result * pi) \ 180  - to convert the scaling result to radian
    
    fstp tword [ecx]                ; put the scaling result by radians in the head(alpha) in drone's strcut
    
    popad
    mov esp, ebp
    pop ebp
    ret
    
scaling_delta_alpha:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                ; load argument - pointer to the delta alpha
    finit                           ; initialize x87 stack
    fild dword [seed]               ; laod into x87 stack the seed to ST0
    fidiv dword [MAX_SHORT]          ; divied seed\MAX_SHORT , and result is in ST0
    fimul dword [ONE_TWENTY]         ; multiply the result with 120 , store the result in ST0
    fisub dword [SIXTY]             ; sub 60 from the result so the range of angle will be between [-60,60]
     ;~~~~~~~~~~~~convert the degree to radians~~~~~~~~~~~~~~~~
    fldpi                           ; put in ST0 pi , the result of the scaling in ST1
    fmulp                           ; multiply scaling result * pi ( ST0*ST1) , and result in ST0
    fild dword [ONE_EIGHTY]         ; put 180 in ST0 , previus result go to ST1
    fdivp                           ; divied (scaling result * pi) \ 180  - to convert the scaling result to radian
    
    fstp tword [ecx]                ; put the scaling result in distance
    
    popad
    mov esp, ebp
    pop ebp
    ret

scaling_distance:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                ; load argument - pointer to the distance
    finit                           ; initialize x87 stack
    fild dword [seed]               ; laod into x87 stack the seed to ST0
    fdiv dword [MAX_SHORT]          ; divied seed\MAX_SHORT , and result is in ST0
    fmul dword [FIFTY]              ; multiply the result with 50 , store the result in ST0
    
    fstp tword [ecx]                ; put the scaling result by radians in delta_alpha
    
    popad
    mov esp, ebp
    pop ebp
    ret

printer:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                    ; load argument - pointer to the right position in the drone struct
    push ecx
    ;~~~~~~~~~~~~~~~~~~~~~~~~~print target~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mov ecx, dword [target]             ; put in ecx pointer to target
    finit
    fld tword [ecx]                     ; load in ST0 the X of the target
    push ecx                            ; backup ecx before printf
    sub esp, 8                          ; make place for 8 bytes value in stack
    fstp qword [esp]                    ; push seconed argument for printf to stack, the float number
    push format_f                       ; push first argument for printf
    call printf                         ; print X of target
    add esp, 12                         ; pop arguments of printf
    pop ecx                             ; restore ecx
    add ecx, 10                         ; mov ecx to point Y of the target
    fld tword [ecx]                     ; load in ST0 the Y of the target
    sub esp, 8                          ; make place for 8 bytes value in stack
    fstp qword [esp]                    ; push seconed argument for printf to stack, the float number
    push format_f_n                     ; push first argument for printf
    call printf                         ; print Y of target
    add esp, 12                         ; pop arguments of printf
    
    
    pop ecx
    ;~~~~~~~~~~~~~~~~~~~~~~~~~print drones_structs~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mov eax, 0                          ; loop counter
    mov ecx, dword [drones_structs]     ; put in ecx pointer to drones_structs array
    printer_loop:
    mov ebx, dword [ecx+eax*4]          ; put in ebx the pointer to the current drone_struct
    inc eax                             ; increment the loop counter
    push ebx                            ; backup ebx before printf
    push ecx                            ; backup ecx before printf
    push eax                            ; second argument for printf - the drone's id
    push format_d                       ; first argument for printf - the format
    call printf                         ; print drone's id
    add esp, 4                          ; pop arguments of printf
    pop eax                             ; pop argument after printf
    pop ecx                             ; restore ecx
    pop ebx                             ; restore ebx
    
    finit
    fld tword [ebx]                     ; load to x87 stack the ten byte X float value
    print_float                         ; call macro for print X
    
    mov edx, dword ebx                  ; put in edx the pointer to the current drone_struct
    add edx, dword [Y_p]                ; put edx to point to Y 
    finit
    fld tword [edx]                     ; load to x87 stack the ten byte Y float value
    print_float                         ; call macro for print Y 
    
    mov edx, dword ebx                  ; put in edx the pointer to the current drone_struct
    add edx, dword [HEAD_p]             ; put edx to point to head
    finit
    ;~~~~~~~~~~~~~~~~~~~~convert head (angle) from radians to degree for printing~~~~~~~~~~~~~~~~~~~~~~~~~
    fld tword [edx]                     ; load [edx] (the angle in radians)
    fild dword [ONE_EIGHTY]             ; put 180 in ST0 , previus result go to ST1
    fmulp                               ; multiply angle * 180
    fldpi                               ; put in ST0 pi , 180*[ebx]  in ST1
    fdivp                               ; divied (180*[ebx])\pi
    ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~end of converting~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    print_float                         ; call macro for printing head
    
    mov edx, dword ebx                  ; put in edx the pointer to the current drone_struct
    add edx, dword [score_p]            ; put edx to point to score
    mov edx, dword [edx]                ; put in edx the score value
    push ecx                            ; backup ecx before printf
    push eax                            ; backup eax before printf
    push edx                            ; second argument for printf - score
    push format_d_n                     ; first argument for printf - the format
    call printf                         ; print drone's score
    add esp, 8                          ; pop arguments of printf
    pop eax                             ; restore eax 
    pop ecx                             ; restore ecx
    
    cmp eax, dword [N]                  ; check if the loop was done N times
    jnz printer_loop                    ; if not , go back to printer_loop
    
    popad
    mov esp, ebp
    pop ebp
    ret

drone_co_init:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                                ; load argument - drone's id
    mov eax, 4                                      ; put 4 in eax for multiply in cell id 
    mov ebx, ecx                                    ; put in ebx the cell id
    mul ebx                                         ; multiply (cell id)*4 for finding the current cell adress
    mov ebx, dword [cors]                           ; put in ebx the cors array adress
    add ebx, dword eax                              ; put in ebx the pointer to current cell in cors
    mov edx, dword [stack_pointers_backup]          ; put in edx the address of stack_pointers_backup
    add edx, dword eax                              ; put in edx the pointer to current cell in stack_pointers_backup
    push ebx                                        ; backup before malloc 
    push edx                                        ; backup before malloc
    push dword [stack_size]                         ; argument for malloc
    call malloc                                     ; allocate memory for co-routine stack
    add esp, 4                                      ; pop argument 
    pop edx                                         ; restore after malloc
    pop ebx                                         ; restore after malloc
    mov dword [edx], eax                            ; put in the current cell in stack_pointers_backup the adress of the stack
    add eax, dword [stack_size]                     ; put eax to point on the top of stack (the allocated from malloc stack)
    mov dword [ebx], eax                            ; put in the current cell in cors the adress of the top stack
    mov dword [SPT], esp                            ; backup esp
    mov esp , eax                                   ; put esp to point on the top of the stack (the adress from malloc + stack_size)
    push drone_func                                 ; put in co-routine stack the address of drone_func
    pushfd                                          ; put in co-routine stack the flags
    pushad                                          ; put in co-routine stack the registers
    mov dword [ebx], esp                            ; change the co_routine stack pointer to esp
    mov esp, dword [SPT]                            ; put esp back from backup
        
    popad
    mov esp, ebp
    pop ebp
    ret

target_co_init:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                                ; load argument - drone's id
    mov eax, 4                                      ; put 4 in eax for multiply in cell id 
    mov ebx, ecx                                    ; put in ebx the cell id
    mul ebx                                         ; multiply (cell id)*4 for finding the current cell adress
    mov ebx, dword [cors]                           ; put in ebx the cors array adress
    add ebx, dword eax                              ; put in ebx the pointer to current cell in cors
    mov edx, dword [stack_pointers_backup]          ; put in edx the address of stack_pointers_backup
    add edx, dword eax                              ; put in edx the pointer to current cell in stack_pointers_backup
    push ebx                                        ; backup before malloc 
    push edx                                        ; backup before malloc
    push dword [stack_size]                         ; argument for malloc
    call malloc                                     ; allocate memory for co-routine stack
    add esp, 4                                      ; pop argument 
    pop edx                                         ; restore after malloc
    pop ebx                                         ; restore after malloc
    mov dword [edx], eax                            ; put in the current cell in stack_pointers_backup the adress of the stack
    add eax, dword [stack_size]                     ; put eax to point on the top of stack (the allocated from malloc stack)
    mov dword [ebx], eax                            ; put in the current cell in cors the adress of the top stack
    mov dword [SPT], esp                            ; backup esp
    mov esp , eax                                   ; put esp to point on the top of the stack (the adress from malloc + stack_size)
    push target_func                                ; put in co-routine stack the address of drone_func
    pushfd                                          ; put in co-routine stack the flags
    pushad                                          ; put in co-routine stack the registers
    mov dword [ebx], esp                            ; change the co_routine stack pointer to esp
    mov esp, dword [SPT]                            ; put esp back from backup
        
    popad
    mov esp, ebp
    pop ebp
    ret
    
printer_co_init:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                                ; load argument - drone's id
    mov eax, 4                                      ; put 4 in eax for multiply in cell id 
    mov ebx, ecx                                    ; put in ebx the cell id
    mul ebx                                         ; multiply (cell id)*4 for finding the current cell adress
    mov ebx, dword [cors]                           ; put in ebx the cors array adress
    add ebx, dword eax                              ; put in ebx the pointer to current cell in cors
    mov edx, dword [stack_pointers_backup]          ; put in edx the address of stack_pointers_backup
    add edx, dword eax                              ; put in edx the pointer to current cell in stack_pointers_backup
    push ebx                                        ; backup before malloc 
    push edx                                        ; backup before malloc
    push dword [stack_size]                         ; argument for malloc
    call malloc                                     ; allocate memory for co-routine stack
    add esp, 4                                      ; pop argument 
    pop edx                                         ; restore after malloc
    pop ebx                                         ; restore after malloc
    mov dword [edx], eax                            ; put in the current cell in stack_pointers_backup the adress of the stack
    add eax, dword [stack_size]                     ; put eax to point on the top of stack (the allocated from malloc stack)
    mov dword [ebx], eax                            ; put in the current cell in cors the adress of the top stack
    mov dword [SPT], esp                            ; backup esp
    mov esp , eax                                   ; put esp to point on the top of the stack (the adress from malloc + stack_size)
    push printer_func                               ; put in co-routine stack the address of drone_func
    pushfd                                          ; put in co-routine stack the flags
    pushad                                          ; put in co-routine stack the registers
    mov dword [ebx], esp                            ; change the co_routine stack pointer to esp
    mov esp, dword [SPT]                            ; put esp back from backup
        
    popad
    mov esp, ebp
    pop ebp
    ret

scheduler_co_init:
    push ebp
    mov ebp, esp
    pushad
    
    mov ecx, [ebp+8]                                ; load argument - drone's id
    mov eax, 4                                      ; put 4 in eax for multiply in cell id 
    mov ebx, ecx                                    ; put in ebx the cell id
    mul ebx                                         ; multiply (cell id)*4 for finding the current cell adress
    mov ebx, dword [cors]                           ; put in ebx the cors array adress
    add ebx, dword eax                              ; put in ebx the pointer to current cell in cors
    mov edx, dword [stack_pointers_backup]          ; put in edx the address of stack_pointers_backup
    add edx, dword eax                              ; put in edx the pointer to current cell in stack_pointers_backup
    push ebx                                        ; backup before malloc 
    push edx                                        ; backup before malloc
    push dword [stack_size]                         ; argument for malloc
    call malloc                                     ; allocate memory for co-routine stack
    add esp, 4                                      ; pop argument 
    pop edx                                         ; restore after malloc
    pop ebx                                         ; restore after malloc
    mov dword [edx], eax                            ; put in the current cell in stack_pointers_backup the adress of the stack
    add eax, dword [stack_size]                     ; put eax to point on the top of stack (the allocated from malloc stack)
    mov dword [ebx], eax                            ; put in the current cell in cors the adress of the top stack
    mov dword [SPT], esp                            ; backup esp
    mov esp , eax                                   ; put esp to point on the top of the stack (the adress from malloc + stack_size)
    push scheduler_func                             ; put in co-routine stack the address of drone_func
    pushfd                                          ; put in co-routine stack the flags
    pushad                                          ; put in co-routine stack the registers
    mov dword [ebx], esp                            ; change the co_routine stack pointer to esp
    mov esp, dword [SPT]                            ; put esp back from backup
        
    popad
    mov esp, ebp
    pop ebp
    ret
    
    
startCo:
    pushad                                ; backup registers
    mov dword [SPMAIN], esp               ; backup esp of main 
    mov ebx, dword [cors]                 ; put in ebx the pointer to cors array - first cell in cors array (scheduler stack cell), before do_resume
    jmp do_resume
    
    endCo:
    mov esp, [SPMAIN]
    popad
    ret
    
; edx = pointer to the suitable cell (the stack which we want to save) in cors    
resume:
    pushfd                                ; backup flags
    pushad                                ; backup registers
    mov dword [edx], esp                  ; put in the in suitable stack pointer esp

; ebx = pointer to suitable cell (the stack which we want to activate his func) in cors
do_resume:
    mov esp, dword [ebx]                  ; put esp to point the current location of the co-routine stack where we have stopped 
    popad                                 ; restore registers
    popfd                                 ; restore flags
    ret

createTarget:
    push ebp
    mov ebp, esp
    pushad
    
    call random                         ; randomize a random 16 bit number into seed
    mov eax, dword [target]             ; put in eax the pointer to target
    push eax                            ; argument for scaling_position
    call scaling_position               ; scalling the X of the target, and put it in target
    pop eax                             ; pop argument of scaling_position
    add eax, 10                         ; move eax to point on the Y location of the target
    call random                         ; randomize a random 16 bit number into seed
    push eax                            ; argument for scaling_position
    call scaling_position               ; scalling the Y of the target, and put it in target
    add esp, 4                          ; pop argument of scaling_position
    
    popad
    mov esp, ebp
    pop ebp
    ret

mayDestroy:
    push ebp
    mov ebp, esp
    pushad
    
    ;~~~~~~~~~~~~~~~~~~~~~find gama~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~~~~calculate Ytarget-Ydrone~~~~~~~~~~~~~~~~~~~~~~ 
    mov ebx, dword [target]             ; put in ebx the adress of target
    add ebx, 10                         ; move ebx to point the Y of the target
    finit
    fld tword [ebx]                     ; put in ST0 the Y of the target
    mov ecx, dword [drones_structs]     ; put in ecx the adress of drones_structs
    mov ebx, dword [curr_id]            ; put in ebx the current drone's id
    dec ebx                             ; decrement ebx becuse curr_id drone placed in (curr_id-1) cell in drones_structs
    mov eax, 4                          ; put 4 in eax for multiply
    mul ebx                             ; put in eax (curr_id-1)*4
    add ecx, eax                        ; put in ecx the adress of the current cell in drones_structs
    mov ecx, dword [ecx]                ; put ecx to point the begining of the drone struct
    push ecx                            ; backup the adress of the begining of the drone struct (point on the X)
    add ecx, dword [Y_p]                ; put ecx to point the Y of the drone
    fld tword [ecx]                     ; load in ST0 the Y of the drone, in ST1 the y of the target
    fsubp                               ; put in ST0 the Ytarget-Ydrone
    ;~~~~~~~~~~~~~~~~~~~end of calculate Ytarget-Ydrone~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~~calculate Xtarget-Xdrone~~~~~~~~~~~~~~~~~~~~~~
    pop ecx                             ; restore in ecx the adress of the begining of the struct
    push ecx                            ; backup the adress of the begining of the drone struct (point on the X)
    mov ebx, dword [target]             ; put in ebx the pointer to the X of the target
    fld tword [ebx]                     ; put in ST0 the X of the target , in ST1 Ytarget-Ydrone
    fld tword [ecx]                     ; put in ST0 the X of the drone, in ST1 the X of the target, in ST2 Ytarget-Ydrone
    fsubp                               ; put in ST0 the Xtarget-Xdrone, in ST1 Ytarget-Ydrone
    ;~~~~~~~~~~~~~~~~~~end of calculate Xtarget-Xdrone~~~~~~~~~~~~~~~~~
    fpatan                              ; put in ST0 the result of arctan(ST1\ST0) = arctan(Ytarget-Ydrone\Xtarget-Xdrone)
    fstp tword [gamma]                  ; put in gamma arctan2(y2-y1, x2-x1)
    ;~~~~~~~~~~~~~~~~~~end of finding gamma~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~calculate (abs(alpha-gamma) < beta)~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~calculate |alpha-gamma|~~~~~~~~~~~~~~~~~~~~~~~~~~~
    pop ecx                             ; restore in ecx the adress of the begining of the struct
    add ecx, dword [HEAD_p]             ; put ecx to point the head(angle) of the drone
    fld tword [ecx]                     ; put in ST0 the head
    fld tword [gamma]                   ; put in ST0 gamma, in ST1 head of drone
    fsubp                               ; put in ST0 head-gamma
    fabs                                ; put in ST0 |head-gamma|
    ;~~~~~~~~~~~~~~~~~check if |alpha-gamma|>pi~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    fldpi                               ; put in ST0 pi , |head-gamma| in ST1
    fcomip                              ; check if ST0>ST1 (if  pi > |head-gamma| )
    ja dont_change                      ; if pi > |head-gamma| we want to let |head-gamma| stay ass is , and jump to dont_change 
    ;~~~~~~~~~~~~~~~~end check if |alpha-gamma|>pi~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~end of calculate |alpha-gamma|~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~change alpha\gamma (add 2*pi to the smaller angle)~~~~~~~~~~~~~~~~~
    finit
    fld tword [ecx]                     ; put in ST0 the head
    fld tword [gamma]                   ; put in ST0 gamma, in ST1 head of drone
    fcomip                              ; check if ST0>ST1 (if gamma>head)
    ja change_head                      ; if gamma > head we want to add 2*pi to head
    ;if not we want to add 2*pi to gamma
    finit
    fld tword [ecx]                     ; put in ST0 the head
    fld tword [gamma]                   ; put in ST0 gamma, in ST1 head of drone
    fldpi                               ; put in ST0 pi , in ST1 gamma , in ST2 head
    fild dword [TWO]                     ; put in ST0 2, in ST1 pi , in ST2 gamma , in ST3 head
    fmulp                               ; put in ST0 2*pi, in ST1 gamma , in ST2 head
    faddp                               ; put in ST0 (2*pi+gamma) , in ST1 head
    fsubp                               ; put in ST0 head - (2*pi+gamma)
    fabs                                ; put in ST0 |head - (2*pi+gamma)|
    jmp dont_change                      ; we dont want to change head too, so we jump above it
    change_head:
    finit
    fld tword [ecx]                     ; put in ST0 the head
    fldpi                               ; put in ST0 pi , in ST1 head
    fld dword [TWO]                     ; put in ST0 2, in ST1 pi , in ST2 head
    fmulp                               ; put in ST0 2*pi, in ST1 head
    faddp                               ; put in ST0 (2*pi+head)
    fld tword [gamma]                   ; put in ST0 gamma, in ST1 (2*pi+head)
    fsubp                               ; put in ST0 (2*pi+head) - gamma
    fabs                                ; put in ST0 |(2*pi+head) - gamma|
    dont_change:
    fild dword [B]                      ; put in ST0 B in degrees , in ST1 |head-gamma|
    ;~~~~~~~~~~~~convert Beta from degree to radians~~~~~~~~~~~~~~~~
    fldpi                               ; put in ST0 pi , Beta in ST1 , in ST2 |head-gamma|
    fmulp                               ; multiply Beta * pi (ST0*ST1) , and result in ST0, in ST1 |head-gamma|
    fild dword [ONE_EIGHTY]             ; put 180 in ST0 , previus result go to ST1 , in ST2 |head-gamma|
    fdivp                               ; divied (Beta * pi) \ 180  - to convert the Beta to radian
    ;~~~~~~~~~~~~~~~~~~~~~end_of_convert Beta to radians~~~~~~~~~~~~~~~~~~~~~~~~~~
    fcomip                              ; check if ST0>ST1 (if  Beta > |head-gamma| )
    jbe end_may_destroy                 ; if Beta <= |head-gamma| dont change the destroy_flag to 1 , and jump to end_may_destroy
    ;~~~~~~~~~~~~~~~~~~end calculate (abs(alpha-gamma) < beta)~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~~~~~calculate sqrt((ytarget-ydrone)^2+(xtarget-xdrone)^2) < d~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~~~~~~~~calculate (ytarget-ydrone)^2~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mov ebx, dword [target]             ; put in ebx the adress of target
    add ebx, 10                         ; move ebx to point the Y of the target
    finit
    fld tword [ebx]                     ; put in ST0 the Y of the target
    mov ecx, dword [drones_structs]     ; put in ecx the adress of drones_structs
    mov ebx, dword [curr_id]            ; put in ebx the current drone's id
    dec ebx                             ; decrement ebx becuse curr_id drone placed in (curr_id-1) cell in drones_structs
    mov eax, 4                          ; put 4 in eax for multiply
    mul ebx                             ; put in eax (curr_id-1)*4
    add ecx, eax                        ; put in ecx the adress of the current cell in drones_structs
    mov ecx, dword [ecx]                ; put ecx to point the begining of the drone struct
    push ecx                            ; backup the adress of the begining of the drone struct (point on the X)
    add ecx, dword [Y_p]                ; put ecx to point the Y of the drone
    fld tword [ecx]                     ; load in ST0 the Y of the drone, in ST1 the y of the target
    fsubp                               ; put in ST0 the Ytarget-Ydrone
    fstp tword [power2]                 ; pop the y2-y1 into power2
    fld tword [power2]                  ; put in ST0 Ytarget-Ydrone 
    fld tword [power2]                  ; put in ST0 Ytarget-Ydrone , and in ST1 also Ytarget-Ydrone
    fmulp                               ; put in ST0 (y2-y1)^2
    ;~~~~~~~~~~~~~~~~~~~~~~~~~end calculate (ytarget-ydrone)^2~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~~calculate (Xtarget-Xdrone)^2~~~~~~~~~~~~~~~~~~~~~~
    pop ecx                             ; restore in ecx the adress of the begining of the struct
    mov ebx, dword [target]             ; put in ebx the pointer to X of the target
    fld tword [ebx]                     ; put in ST0 the X of the target , in ST1 (Ytarget-Ydrone)^2
    fld tword [ecx]                     ; put in ST0 the X of the drone, in ST1 the X of the target, in ST2 (Ytarget-Ydrone)^2
    fsubp                               ; put in ST0 the Xtarget-Xdrone, in ST1 (Ytarget-Ydrone)^2
    fstp tword [power2]                 ; pop the X2-X1 into power2, in ST0 (Ytarget-Ydrone)^2
    fld tword [power2]                  ; put in ST0 Xtarget-Xdrone, in ST1 (Ytarget-Ydrone)^2 
    fld tword [power2]                  ; put in ST0 Xtarget-Xdrone , and in ST1 also Xtarget-Xdrone, in ST2 (Ytarget-Ydrone)^2
    fmulp                               ; put in ST0 (X2-X1)^2, in ST1 (Ytarget-Ydrone)^2
    ;~~~~~~~~~~~~~~~~~~end of calculate (Xtarget-Xdrone)^2~~~~~~~~~~~~~~~~~
    faddp                               ; put in ST0 (ytarget-ydrone)^2+(xtarget-xdrone)^2
    fsqrt                               ; put in ST0 sqrt((ytarget-ydrone)^2+(xtarget-xdrone)^2)
    fild dword [d]                      ; put in ST0 the distance , in ST1 the result of sqrt((ytarget-ydrone)^2+(xtarget-xdrone)^2)
    fcomip                              ; check if ST0>ST1 (if  distance > sqrt((ytarget-ydrone)^2+(xtarget-xdrone)^2) )
    ;~~~~~~~~~~~~~~~~~~~~~~end calculate sqrt((ytarget-ydrone)^2+(xtarget-xdrone)^2) < d~~~~~~~~~~~~~~~~~~~~~~~~~
    jbe end_may_destroy                 ; if distance <= sqrt((ytarget-ydrone)^2+(xtarget-xdrone)^2) dont change the destroy_flag to 1 , and jump to end_may_destroy
    mov dword [destroy_flag], 1         ; if we arrived here , both conditions are true and we may destroy the target , so flag = 1
    end_may_destroy:
    
    popad
    mov esp, ebp
    pop ebp
    ret
    
free_memory:
    push ebp
    mov ebp, esp
    pushad
    
    push dword [target]                    ; push arg for free - pointer to target
    call free                              ; free target
    add esp,4                              ; pop argument after free
    
    push dword [cors]                      ; push arg for free - pointer to cors
    call free                              ; free cors
    add esp,4                              ; pop argument after free
    
    mov ebx, dword [stack_pointers_backup] ; mov to ebx the pointer to stack_pointers_backup
    mov eax, 0                             ; counter fot loop
    free_stack_loop:   
    mov ecx, dword [ebx+4*eax]             ; mov to ecx the pointer to the current stack we want to free
    push ebx                               ; backup pointer to stack_pointers_backup before free
    push eax                               ; backup loop counter
    push ecx                               ; push arg for free - pointer to the current stack we want to free
    call free                              ; free current stack
    add esp,4                              ; pop argument after free
    pop eax                                ; restore loop counter
    pop ebx                                ; restore pointer to stack_pointers_backup after free
    inc eax                                ; increment loop counter
    cmp eax, dword [numco]                 ; compare loop counter with number of co rutines
    jnz free_stack_loop                    ; if not jmp to free_stack_loop
    push ebx                               ; if yes, we want to free the [stack_pointers_backup], we push it ass arg
    call free                              ; free stack_pointers_backup
    add esp, 4                             ; pop argument after free
    
    mov ebx, dword [drones_structs]        ; mov to ebx the pointer to drones_structs
    mov eax, 0                             ; counter fot loop
    free_structs_loop:
    mov ecx, dword [ebx+4*eax]             ; mov to ecx the pointer to the current drone drone_struct we want to free
    push ebx                               ; backup pointer to drones_structs before free
    push eax                               ; backup loop counter
    push ecx                               ; push arg for free - pionter to the current drone_struct we want to free
    call free                              ; free current drone_struct
    add esp,4                              ; pop argument after free
    pop eax                                ; restore loop counter
    pop ebx                                ; restore pointer to drones_structs after free
    inc eax                                ; increment loop counter
    cmp eax, dword [N]                     ; compare loop counter with number of drones
    jnz free_structs_loop                  ; if not jmp to free_structs_loop
    push ebx                               ; if yes, we want to free the [drones_structs], we push it ass arg
    call free                              ; free drones_structs
    add esp,4                              ; pop argument after free
    
    popad
    mov esp, ebp
    pop ebp
    ret
