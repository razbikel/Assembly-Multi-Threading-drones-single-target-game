section .text
    global scheduler_func
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
    extern drone_struct
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
    extern resume
    
scheduler_func:
    mov ebx , dword [curr_id]           ; put in ebx curr_id = which is the drone's co-routine's id of the drone we need to resume
    mov eax, 4                          ; put 4 in eax for multiply curr_id*4
    mul ebx                             ; multiply 4*curr_id , result in eax
    mov ebx, dword [cors]               ; put in ebx the pointer to cors array
    add ebx, eax                        ; put in ebx the address of the curr id stack's cell in cors , before call do_resume
    mov edx, dword [cors]               ; put in edx the pointer to cors array - first cell in cors array (scheduler stack cell), before resume
    call resume                         ; activate curr_id drone's func
    mov ebx, dword [curr_id]            ; put in ebx the curr_id for increment
    cmp ebx, dword [N]                  ; check if we arrived the last drone
    jz round_curr_id                    ; if yes , jump
    inc ebx                             ; increment curr_id
    mov dword [curr_id], ebx            ; put the incremented curr_id in his place
    jmp inc_k_counter
    round_curr_id:                      ; if we arrived here , curr_id = N and we need to put in it 1
    mov ebx, 1              
    mov dword [curr_id], ebx
    inc_k_counter:
    mov ebx, dword [k_counter]          ; put in ebx the k_counter for increment
    inc ebx                             ; increment curr_id
    mov dword [k_counter], ebx          ; put the incremented k_counter in his place
    cmp ebx, dword [K]                  ; check if K  drone steps were done
    jnz scheduler_func                  ; if not, activate curr_id drone's_func
    ; if k_counter = K
    mov ebx, 0                          ; put 0 in ebx for put 0 in k_counter
    mov dword [k_counter], ebx          ; put 0 in k_counter
    mov ebx, dword [N]
    add ebx, 2
    mov eax, 4                          ; put 4 in eax for multiply curr_id*4
    mul ebx                             ; multiply 4*curr_id , result in eax
    mov ebx, dword [cors]               ; put in ebx the pointer to cors array
    add ebx, eax                        ; put in ebx the address of the curr id stack's cell in cors , before call do_resume
    mov edx, dword [cors]               ; put in edx the pointer to cors array - first cell in cors array (scheduler stack cell), before resume
    call resume                         ; activate curr_id drone's func
    jmp scheduler_func                  ; after return from resume it means that printer was doing resume to scheduler co-routine , so we want to activate the next drone's func
