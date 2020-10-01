global drone_func
extern format_d_in
extern format_f_in
extern format_d
extern format_f
extern format_f_n
extern format_d_n
extern MAX_SHORT
extern board_bound
extern MAX_DEGREE
extern ONE_TWENTY
extern SIXTY
extern FIFTY
extern TWO
extern ONE_EIGHTY
extern ZERO
extern stack_size
extern str
extern winner_str1 
extern winner_str2
extern X_p
extern Y_p
extern HEAD_p
extern score_p
extern N
extern T
extern K
extern B
extern d
extern seed
extern numco
extern drones_structs
extern target
extern cors
extern stack_pointers_backup
extern SPT
extern SPMAIN
extern k_counter
extern curr_id
extern delta_alpha
extern distance
extern gamma
extern destroy_flag
extern power2
extern drone_score
extern random
extern scaling_delta_alpha
extern scaling_distance
extern mayDestroy
extern printf
extern endCo
extern resume

section .text
    



drone_func:
    call random                         ; randomize a random 16 bit number into seed
    push dword delta_alpha              ; argument for scaling_delta_alpha
    call scaling_delta_alpha            ; put in delta_alpha the randomize angle between [-60,60] in radians
    add esp, 4
    call random                         ; randomize a random 16 bit number into seed
    push dword distance                 ; argument for scalling distance
    call scaling_distance               ; put in distance the randomize distance between [0,50]
    add esp, 4
    mov ebx, dword [curr_id]            ; put in ebx the curr_id
    dec ebx                             ; decrement ebx becuse curr_id drone placed in (curr_id-1) cell in drones_structs
    mov eax,4                           ; put 4 in eax for multiply
    mul ebx                             ; multiply (curr_id-1)*4 , result in eax
    mov ebx, dword [drones_structs]     ; put the pointer to drones_structs in ebx
    add ebx, eax                        ; put ebx to point on the curr_id cell in drones_structs
    mov ebx, [ebx]                      ; put ebx to point the struct's drone (X,Y,head,score)
    push ebx                            ; backup the adress of the begining of the drone
    add ebx, dword [HEAD_p]             ; put ebx to point head
    finit
    fld tword [ebx]                     ; put head in ST0
    fld tword [delta_alpha]             ; put delta alpha in ST0, head in ST1
    faddp                               ; add head+delta_alpha , result in ST0
    ;~~~~~~~~~~~~~~~~~~convert delta_alpha+head to degrees~~~~~~~~~~~~~~~~~~~~~  
    fild dword [ONE_EIGHTY]             ; put 180 in ST0 , previus result go to ST1
    fmulp                               ; multiply angle * 180
    fldpi                               ; put in ST0 pi , 180*[ebx]  in ST1
    fdivp                               ; divied (180*[ebx])\pi
    ;~~~~~~~~~~~~~~~~~~end of converting - delta_alpha+head in degrees in ST0~~~~~~~~~~~~~~~
    fild dword [MAX_DEGREE]             ; load to ST0 360
    fcomip                              ; check if ST0>ST1 (if  360 > delta_alpha+head)
    ja check_zero_head                  ; if  head+delta < 360 , we dont need to scall , we want to jump the scalling part
    ;~~~~~~~~~~~~~~~~~~scaling delta_alpha+head between [0,360]~~~~~~~~~~~~~~~~~~~~~~~
    fild dword [MAX_DEGREE]
    fsubp
    ;fidiv dword [MAX_SHORT]              ; divied delta_alpha+head\MAX_SHORT , and result is in ST0
    ;fimul dword [MAX_DEGREE]             ; multiply the result with 360 , store the result in ST0
    jmp end_of_scalling                 ;
    ;~~~~~~~~~~~~convert the degree to radians~~~~~~~~~~~~~~~~
    check_zero_head:
    fild dword [ZERO]                   ; load in ST0 0 to check if delta_alpha+head > 0 , in ST1 delta_alpha+head
    fcomip                              ; check if ST0>ST1 (if  0 > delta_alpha+head)
    jb end_of_scalling                  ; if  head+delta < 0 , we dont need to scall , we want to jump the scalling part
    fild dword [MAX_DEGREE]             ; put in ST0 360 to add to delta_alpha+head , in ST1 delta_alpha+head
    faddp                               ; put in ST0 delta_alpha+head+360
    end_of_scalling:
    fldpi                               ; put in ST0 pi , the result of the scaling in ST1
    fmulp                               ; multiply scaling result * pi ( ST0*ST1) , and result in ST0
    fild dword [ONE_EIGHTY]             ; put 180 in ST0 , previus result go to ST1
    fdivp                               ; divied (scaling result * pi) \ 180  - to convert the scaling result to radian
    ;~~~~~~~~~~~~~~~~~~~~~end_of_scalling~~~~~~~~~~~~~~~~~~~~~~~~~~
    fstp tword [ebx]                    ; put the scaling result by radians in the head(alpha) in drone's strcut
    ;~~~~~~~~~~~~~~~~~~~~calculate X~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    pop ebx                             ; put ebx back to point on X of the drone
    finit
    fld tword [ebx]                     ; put in ST0 X that we want to change
    push ebx                            ; backup the adress of the begining of the drone
    add ebx, dword [HEAD_p]             ; put in ebx the ponter to head (angle) of the drone
    fld tword [ebx]                     ; put in ST0 the head , X in ST1 
    fcos                                ; put in ST0 the result of cos(head) , X in ST1
    fld tword [distance]                ; put in ST0 the distance , cos(head) in ST1 , X in ST2
    fmulp                               ; put in ST0 the result of distance*cos(head), X in ST1
    faddp                               ; put in ST0 the result of [distance*cos(head)] + X
    fild dword [board_bound]            ; put in ST0 100 to check if the new X is in board board_bound , in ST1 the new X
    fcomip                              ; check if ST0>ST1 (if  100 > new X) 
    ja check_zero_X                     ; if new X < 100 jump to check if new X < 0
    fild dword [board_bound]            ; load to ST0 100 to add to new X , in ST1 new X
    fsubp                               ; put in ST0 the new X - 100
    jmp X_in_bound                      ;
    check_zero_X:                         ;
    fild dword [ZERO]                   ; put in ST0 0 to check if the new X is in board board_bound , in ST1 the new X
    fcomip                              ; check if ST0>ST1 (if 0 > new X) 
    jb X_in_bound                       ; if new X > 0 jump to X_in_bound
    fild dword [board_bound]            ; load to ST0 100 to dec from new X , in ST1 new X
    faddp                               ; put in ST0 the new X + 100
    X_in_bound:
    pop ebx                             ; restor in ebx the adress of the begining of the drone (point to the X)
    fstp tword [ebx]                    ; put in X place in the drone the new X value
    ;~~~~~~~~~~~~~~~~~end calculate X~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ;~~~~~~~~~~~~~~~~~~calculate Y~~~~~~~~~~~~~~~~~~~~~~~~~~
    push ebx                            ; backup the adress of the begining of the drone
    add ebx, dword [Y_p]                ; put ebx the adress of the Y in the drone
    finit   
    fld tword [ebx]                     ; put in ST0 Y that we want to change
    pop ebx                             ; restor in ebx the adress of the begining of the drone (point to the X)
    push ebx                            ; backup the adress of the begining of the drone
    add ebx, dword [HEAD_p]             ; put in ebx the ponter to head (angle) of the drone
    fld tword [ebx]                     ; put in ST0 the head , Y in ST1 
    fsin                                ; put in ST0 the result of sin(head) , Y in ST1
    fld tword [distance]                ; put in ST0 the distance , sin(head) in ST1 , Y in ST2
    fmulp                               ; put in ST0 the result of distance*sin(head), Y in ST1
    faddp                               ; put in ST0 the result of [distance*sin(head)] + Y
    fild dword [board_bound]            ; put in ST0 100 to check if the new Y is in board board_bound , in ST1 the new Y
    fcomip                              ; check if ST0>ST1 (if  100 > new Y) 
    ja check_zero_Y                     ; if new Y < 100 jump to check if new Y < 0
    fild dword [board_bound]            ; load to ST0 100 to add to new Y , in ST1 new Y
    fsubp                               ; put in ST0 the new Y - 100
    jmp Y_in_bound                      ;
    check_zero_Y:                         ;
    fild dword [ZERO]                   ; put in ST0 0 to check if the new Y is in board board_bound , in ST1 the new Y
    fcomip                              ; check if ST0>ST1 (if 0 > new Y) 
    jb Y_in_bound                       ; if new Y > 0 jump to Y_in_bound
    fild dword [board_bound]            ; load to ST0 100 to dec from new Y , in ST1 new Y
    faddp                               ; put in ST0 the new Y + 100
    Y_in_bound:
    pop ebx                             ; restor in ebx the adress of the begining of the drone (point to the X)
    push ebx                            ; backup the adress of the begining of the drone
    add ebx, dword [Y_p]                ; put ebx the adress of the Y in the drone
    fstp tword [ebx]                    ; put in Y place in the drone the new Y value
    ;~~~~~~~~~~~~~~~~~~end calculate Y~~~~~~~~~~~~~~~~~~~~~~~
    pop ebx                            ; restor in ebx the adress of the begining of the drone (point to the X)
    call mayDestroy                    ; check if the drone can destroy the target , if yes destroy_flag = 1 , if not 0
    cmp dword [destroy_flag], 1        ; check if we need to destroy the target
    jnz not_destroy                    ; if not , jump
    ; if we are arrived here we need to destroy the target
    mov dword [destroy_flag], 0        ; put in destroy_flag 0 again after the target was destroy
    add ebx, dword [score_p]           ; put ebx to point the score of the drone
    mov edx, dword [ebx]               ; put in edx the score of the drone for increment
    inc edx                            ; increment the drone score
    mov dword [ebx], edx               ; put in the drone's score his previus score incremented
    mov edx, dword [T]                 ; put in edx the number of targets that need to destroy to win , to check if the drone wins
    cmp dword [ebx], edx               ; check if the number of targets the drone destroied is >= T
    jb not_winner                      ; if number of targets the drone has destroied < T , jump to not_winner
    ; if we arrived here , the drone is winner 
    push winner_str1                   ; push seconed argument for printf
    push str                           ; push first argument for printf
    call printf                        ; print "Drone id <"
    add esp,8                          ; "make pop" for the printf arguments
    mov edx, dword [curr_id]           ; put in edx the drone's curr id 
    push edx                           ; push second argument for printf
    push format_d_in                   ; push first argument for printf
    call printf                        ; print the winner drone's id
    add esp,8                          ; "make pop" for the printf arguments
    push winner_str2                   ; push seconed argument for printf
    push str                           ; push first argument for printf
    call printf                        ; print ">: I am winner"
    add esp,8                          ; "make pop" for the printf arguments
    ; now we need to stop the game:
    call endCo
    not_winner:                        ; we destroy a target but the drone did not won the game , so we resume target co-routine to create new target
    mov ebx, dword [curr_id]           ; put in ebx the drone's curr id 
    mov eax, 4                         ; put in eax 4 for multiply
    mul ebx                            ; multiply (curr_id)*4 , result in eax
    mov edx, dword [cors]              ; put in edx the pointer to cors array
    add edx, eax                       ; put in edx the pointer to the current drone's stack cell in cors , before call resume 
    push edx                           ; back up edx , we now need to find the adress of target co-routine and put in ebx before call resume
    mov ebx, dword [N]                 ; put in ebx N
    inc ebx                            ; put in ebx N+1 = target co-routine id
    mov eax, 4                         ; put 4 for multiply (N+1)*4
    mul ebx                            ; multiply (N+1)*4
    mov edx, dword [cors]              ; put in edx the pointer to cors array
    add edx, eax                       ; put in edx the pointer to the target's stack cell in cors 
    mov ebx, edx                       ; put in ebx the pointer to the target's stack cell in cors , before call resume 
    pop edx                            ; restore in edx the pointer to the current drone's stack cell in cors , before call resume 
    call resume                        ;
    jmp drone_func                     ;
    
    
    
    not_destroy:                       ; we didnt destroy the target so we need to switch back to scheduler
    mov ebx, dword [curr_id]           ; put in ebx the drone's curr id 
    mov eax, 4                         ; put in eax 4 for multiply
    mul ebx                            ; multiply (curr_id)*4 , result in eax
    mov edx, dword [cors]              ; put in edx the pointer to cors array
    add edx, eax                       ; put in edx the pointer to the current drone's stack cell in cors , before call resume 
    mov ebx, dword [cors]              ; put in ebx the pointer to cors array - first cell in cors array (scheduler stack cell), before do_resume
    call resume                        ;
    jmp drone_func                     ; 
