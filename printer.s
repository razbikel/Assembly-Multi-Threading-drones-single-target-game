section .text
    global printer_func
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
    extern printer
    
    
printer_func:
    call printer
    mov ebx, dword [N]                  ; put in ebx N
    add ebx, 2                          ; put in ebx N+2 - id of the printer co-routine in cors
    mov eax, 4                          ; put 4 for multiply (N+2)*4
    mul ebx                             ; multiply (N+2)*4
    mov edx, dword [cors]               ; put in edx the pointer to cors array
    add edx, eax                        ; put in edx the pointer to the printer's stack cell in cors , before call resume 
    mov ebx, dword [cors]               ; put in ebx the pointer to cors array - first cell in cors array (scheduler stack cell), before do_resume
    call resume                         ; 
    jmp printer_func                    ; after return from resume it means that scheduler was doing resume to printer co-routine , so we want to print the board
