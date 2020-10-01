section .text
    global target_func
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
    extern createTarget
    
target_func:
    call createTarget                   ; create X and Y and put in target
    mov ebx, dword [N]                  ; put in ebx N
    inc ebx                             ; put in ebx N+1 = target co-routine id
    mov eax, 4                          ; put 4 for multiply (N+1)*4
    mul ebx                             ; multiply (N+1)*4
    mov edx, dword [cors]               ; put in edx the pointer to cors array
    add edx, eax                        ; put in edx the pointer to the target's stack cell in cors , before call resume 
    mov ebx, dword [cors]               ; put in ebx the pointer to cors array - first cell in cors array (scheduler stack cell), before do_resume
    call resume                         ; 
    jmp target_func                     ; after return from resume it means that drone was doing resume to target co-routine , so we want to create a new target
