; Calculator
COMMENT !
features : Operates 4 digits by default (no decimal) addition/subtraction/multiplication/division
         : You can change the digits up to 10:) but divide only works at 4 digit:<
         : limit only the valid inputs which are numbers and operations
         : Will show error if overflow or any logic error
         : You can do backspace if you made typo
         : You can change the operation if you pressed wrong operation (you won't lose your first input)
         : Press escape to refresh the program
!

; Author : Phyo Thant
; Creation Date : 4/17/2023
; Modify Date : 4/27/2023

INCLUDE Irvine32.inc 

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD

.data
    digits = 4 ; global variable to change digit
    
.code
; //////////////////////////////////////////////////////////////////////////////////////////////
; ////////////////////////////////////// PRINTS ////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////
; // Print function
print_calculator PROC
    .data
        row1 BYTE "-----------", 0Dh, 0Ah, 0
        row2 BYTE "|1|2|3| |+|", 0Dh, 0Ah, 0
        row3 BYTE "|4|5|6| |-|", 0Dh, 0Ah, 0
        row4 BYTE "|7|8|9| |*|", 0Dh, 0Ah, 0
        row5 BYTE "  |0|=| |/|", 0Dh, 0Ah, 0
    .code
        mov dl, 0
        mov dh, 1
        call Gotoxy
        mov edx, OFFSET row1
        call WriteString
        mov edx, OFFSET row2
        call WriteString
        mov edx, OFFSET row3
        call WriteString
        mov edx, OFFSET row4
        call WriteString
        mov edx, OFFSET row5
        call WriteString
    ret
print_calculator ENDP

; // prints the buffer in specific location
print_buffer PROC
    call print_space

    mov dl, 10 - digits
    mov dh, 0
    call Gotoxy
     
    mov edx, OFFSET buffer
    call WriteString
    ret
print_buffer ENDP

; // prints the saved result
print_save PROC
    call print_space

    mov dl, 10 - digits
    mov dh, 0
    call Gotoxy
     
    mov edx, OFFSET save
    call WriteString
    ret
print_save ENDP

; // print error when out of range
print_error PROC
    call print_space

    mov dl, 3
    mov dh, 0
    call Gotoxy

    mov edx, OFFSET error_text
    call WriteString
    ret
print_error ENDP

; // this is for beauty
print_space PROC
    mov edx, 0
    call Gotoxy

    mov edx, OFFSET space_text
    call WriteString
    ret
print_space ENDP

; //////////////////////////////////////////////////////////////////////////////////////////////
; /////////////////////////////////////// CONTROLS /////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////
; // set flag checking al
set_flag PROC uses eax ebx edx
    .IF al == '+'
        mov _add, 1
    .ELSEIF al == '-'
        mov _sub, 1
    .ELSEIF al == '*'
        mov _mul, 1
    .ELSEIF al == '/'
        mov _div, 1
    .ENDIF
    ret
set_flag ENDP

; // clear all _add/_sub/_mul/_div
clear_flags PROC uses eax ebx edx
    mov _add, 0
    mov _sub, 0
    mov _mul, 0
    mov _div, 0
    ret
clear_flags ENDP

; // clear the buffer
clear_buffer PROC
    mov esi, OFFSET buffer
    mov ecx, digits
    
    L6:
        mov BYTE PTR [esi], '0'
        inc esi
    loop L6
    mov count, 0
    ret
clear_buffer ENDP

; // clear the save
clear_save PROC
    mov esi, OFFSET save
    mov ecx, digits
    
    L7:
        mov BYTE PTR [esi], '0'
        inc esi
    loop L7
    mov save_count, 0
    ret
clear_save ENDP

; // clear the y
clear_y PROC
    mov esi, OFFSET y
    mov ecx, digits
    
    L12:
        mov BYTE PTR [esi], 0
        inc esi
    loop L12
    ret
clear_y ENDP

; // clear the res
clear_res PROC
    mov esi, OFFSET res
    mov ecx, digits
    
    L13:
        mov BYTE PTR [esi], 0
        inc esi
    loop L13
    mov temp_count, 0
    ret
clear_res ENDP

; // this function copoies from res(unpack) to save(ascii)
copy_rs PROC
    mov save_count, 0
    mov esi, OFFSET res
    mov edi, OFFSET save
    mov ecx, digits
    L14:
        mov al, BYTE PTR [esi]
        or al, 30h
        .IF al != '0'
            inc save_count
        .ENDIF
        mov BYTE PTR [edi], al
        
        inc esi
        inc edi
    loop L14
    ret
copy_rs ENDP

; // this function copies from save to buffer
copy_sb PROC
    mov ecx, save_count
    mov count, ecx ; copy the size first

    mov esi, OFFSET save
    mov edi, OFFSET buffer
    mov ecx, digits
    L9:
        mov al, BYTE PTR [esi]
        mov BYTE PTR [edi], al
        
        inc esi
        inc edi
    loop L9
    ret
copy_sb ENDP

update_save_count PROC
    mov save_count, 0
    mov esi, OFFSET save
    mov ecx, digits
    L18:
        mov al, BYTE PTR [esi]
        .IF al != '0' && f_temp2 == 1
            mov f_temp2, 0
        .ENDIF
        .IF f_temp2 == 0
            inc save_count
        .ENDIF
        inc esi
    loop L18
    mov f_temp2, 1 ; reset the flag
    ret
update_save_count ENDP
; //////////////////////////////////////////////////////////////////////////////////////////////
; ///////////////////////////// USER INTERFACE AND INPUT PARTS /////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////
; // Gets the user input and call add, sub, mul, div
user_input PROC
    .data
        ; ///////// IMPORTANT VARIABLES ////////////
        buffer BYTE digits DUP('0'), 0
        count DWORD 0
        save BYTE digits DUP ('0'), 0
        save_count DWORD 0
        ; //////////////// FLAGS ///////////////////
        _add BYTE 0
        _sub BYTE 0
        _mul BYTE 0
        _div BYTE 0
        op_error BYTE 0 ; operation error
        f_temp1 BYTE 1 ; flag
        f_temp2 BYTE 1 ; flag
        ; ///////////// TEXT /////////////////////// 
        error_text BYTE "ERROR", 0
        temp_count DWORD 0 ; put it here just in case assembly acts stupid
        space_text BYTE "          ", 0
        ; //////////// OPERATION ///////////////////
        carry BYTE 0
        x BYTE 0
        y BYTE digits DUP(0), 0
        res BYTE digits DUP(0), 0
    .code
         call print_buffer

         L1:
            mov eax, 50
            call Delay

            call ReadKey
            jz L1

            .IF al == '+' || al == '-' || al == '*' || al == '/' ; if these operations were pressed then save the buffer
                call save_buffer
            .ELSEIF al == '=' || dx == VK_RETURN; check the operator flags and see which operation to do
                call operate
            .ELSEIF dx == VK_ESCAPE ; escape will refresh everything including buffer/save/counts/operastor flags
                call refresh
            .ELSE
                call update ; this updates the buffer
            .ENDIF

            jmp L1
    ret
user_input ENDP

; // change buffer
update PROC uses eax ebx edx
    .IF op_error == 1
        jmp opError1
    .ELSEIF _add == 1 || _sub == 1 || _mul == 1 || _div == 1
        mov f_temp1, 0
    .ENDIF
    mov ebx, digits ; this will stores the number of digits
    dec ebx

    cmp dx, VK_BACK
    jne skip
    cmp count, 0
    je done

    dec count
    mov esi, OFFSET buffer
    add esi, ebx ; this will point esi to the last one
    mov ecx, ebx ; this is for the number of loops
    L2:
        mov bl, BYTE PTR [esi - 1]
        mov BYTE PTR [esi], bl
        dec esi
    loop L2
    mov BYTE PTR [esi], '0'

    jmp done

    skip:
    cmp count, ebx; if count is the same as digits than the input is maxed out
    jg done
    cmp al, 48 ; '0'
    jl done
    cmp al, 57 ; '9'
    jg done

    inc count

    mov esi, OFFSET buffer
    mov ecx, ebx
    L1:
        mov bl, BYTE PTR [esi + 1]
        mov BYTE PTR [esi], bl
        inc esi
    loop L1
    mov BYTE PTR [esi], al

    done:
    call print_buffer
    opError1:
    ret
update ENDP

; // this will save the buffer and clear it when user press operation
save_buffer PROC uses eax ebx edx
    .IF op_error == 1 ; after error you can't do any more operation unless you input something
        jmp already
    .ELSEIF _add == 1 || _sub == 1 || _mul == 1 || _div == 1
        .IF f_temp1 == 1
            call clear_flags
            call set_flag
            jmp already ; this means that the buffer is already saved and user decided to do another operation instead
        .ELSE
            call operate
            call clear_flags
            call set_flag
            mov f_temp1, 1
            jmp already
        .ENDIF
    .ENDIF

    call set_flag
    
    mov esi, OFFSET buffer ; src
    mov edi, OFFSET save ; dest
    mov ecx, digits
    
    L3: ; this loop will copy all the buffer string and save it, at the same time clearing the buffer
        mov al, BYTE PTR [esi]
        mov BYTE PTR [esi], '0'
        mov BYTE PTR [edi], al

        inc esi
        inc edi
    loop L3

    mov eax, count ; saving the count
    mov count, 0
    mov save_count, eax

    call print_save
    already:
    ret
save_buffer ENDP

; // This will clear everthing you doing
refresh PROC
    call clear_buffer
    call clear_save
    call clear_flags
    call clear_y
    call clear_res

    mov op_error, 0
    mov f_temp1, 1
    mov f_temp2, 1
    mov carry, 0
    mov x, 0

    call print_buffer
    ret
refresh ENDP

; //////////////////////////////////////////////////////////////////////////////////////////////
; /////////////////////////////////////// MATH PARTS ///////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////
; // this function will determine which operation to do
operate PROC uses eax ebx edx
    .IF op_error == 1
        jmp opError2
    ; .ELSEIF count == 0
        ; call copy_sb ; this is for 2 + = and 2 + 2 ===== case
    .ENDIF

    .IF _add == 1
        call addition
    .ELSEIF _sub == 1
        call subtraction
    .ELSEIF _mul == 1
        call multiplication
    .ELSEIF _div == 1
        call division
    .ENDIF
    opError2:
    ret
operate ENDP

; // Add Function
addition PROC
    mov ecx, digits ; total size of buffer

    dec ecx
    mov esi, OFFSET buffer
    add esi, ecx ; this will point the esi to the last element of buffer
    mov edi, OFFSET save
    add edi, ecx ; this will point the edi to the last element of save

    mov save_count, 0

    inc ecx
    clc
    pushf
    L5:
        popf
        mov ah,  0
        mov al, BYTE PTR [esi] ; ascii digit
        adc al, 0
        add al, BYTE PTR [edi]
        aaa ; ascii to unpack
        pushf
        or ax, 3030h ; this will change to ascii digit
        mov BYTE PTR [edi], al ; save the addition
        
        inc save_count
        dec esi
        dec edi
    loop L5
    popf
    jc carry1
        call print_save
        call clear_buffer
        jmp add_done
    carry1:
        mov op_error, 1
        call print_error
    add_done:
    ret
addition ENDP

; // Sub Function
subtraction PROC
    mov ecx, digits ; total size of buffer

    dec ecx
    mov esi, OFFSET buffer
    add esi, ecx ; this will point the esi to the last element of buffer
    mov edi, OFFSET save
    add edi, ecx ; this will point the edi to the last element of save

    mov save_count, 0

    inc ecx
    clc
    pushf ; this is to prevent pop nothing in the loop for first time
    L8:
        popf ; restore the carry flag
        mov al, BYTE PTR [edi]
        sbb al, 0 ; save - carry flag
        sub al, BYTE PTR [esi] ; save - buffer
        pushf ; save the carry flag
        aas ; will give you the result of subtraction in unpacked
        or al, 30h
        mov BYTE PTR [edi], al ; save the result

        inc save_count
        dec esi
        dec edi
    loop L8
    popf ; popping after the last loop
    jc carry2
        call print_save
        call clear_buffer
        jmp sub_done
    carry2:
        mov op_error, 1
        call print_error
    sub_done:
    ret
subtraction ENDP

; // Mul Function
multiplication PROC
    mov eax, save_count
    add eax, count
    .IF eax > digits + 1
        jmp carry3
    .ENDIF
    mov ecx, digits ; total size of buffer

    dec ecx
    mov esi, OFFSET buffer
    add esi, ecx ; this will point the esi to the last element of buffer
    mov edi, OFFSET save
    add edi, ecx ; this will point the edi to the last element of save
    mov edx, OFFSET y
    add edx, ecx ; this will point the edx to the last element of y

    inc ecx
    L10: ; save * buffer
        .IF op_error == 1
            jmp carry3
        .ENDIF

        push ecx
        push edi
        push edx

        mov al, BYTE PTR [esi] ; this is last save
        and al, 0Fh; you will get unpack
        mov ecx, digits
        mov carry, 0 ; empty the carry first

        L11:
            push eax
            mov bl, BYTE PTR [edi]
            and bl, 0Fh; you will get unpack
            mul bl
            aam ; you will get unpacked in ax

            mov x, ah ; 10th digit
            mov ah, 00h

            or al, 30h ; change it to ascii
            or carry, 30h ; change the carry into ascii
            add al, carry ; add the two ascii
            aaa ; you will get unpack in ax
            add ah, x ; add 10th digit back
            mov x, 0 ; empty the x back

            mov carry, ah ; the carry in unpack
            mov BYTE PTR [edx], al
            dec edi
            dec edx
            pop eax
        loop L11 ; save loop

        call add_yr ; this will add the y came from the inner loop into the res (unpacks)
        pop edx
        pop edi
        pop ecx
        dec esi
    loop L10 ; buffer loop

    call copy_rs ; this will copy unpack res to ascii save
    call clear_res ; clear the res for next use
    call clear_y

    call print_save
    call update_save_count
    call clear_buffer
    jmp mul_done
    carry3:
        mov op_error, 1
        call print_error
    mul_done:
    ret
multiplication ENDP

; // this function will add the two unpacks and if carry then add the carry into the next
; // al will have the unpack
add_yr PROC uses eax ecx edx esi edi
    .IF carry > 0
        jmp carry4
    .ENDIF
    mov ecx, digits ; total size of y
    dec ecx
    mov esi, OFFSET y
    add esi, ecx ; this will point the esi to the last element of y

    sub ecx, temp_count
    mov edi, OFFSET res
    add edi, ecx ; this will point the edi to the subtracted element of res

    inc ecx
    clc
    pushf
    L15:
        mov ah,  0
        mov al, BYTE PTR [esi] ; unpack
        or al, 30h ; ascii
        popf
        adc al, 0
        mov bl, BYTE PTR [edi] ; unpack
        or bl, 30h ; ascii
        add al, bl
        clc ; to prevent carry from or
        aaa ; to unpack
        pushf
        mov BYTE PTR [edi], al ; save the addition
        
        dec esi
        dec edi
    loop L15
    popf
    jc carry4
    call clear_y ; clear y
    inc temp_count

    jmp add_yr_done
    carry4:
        mov op_error, 1
    add_yr_done:
    ret
add_yr ENDP

; // Div Function only works for 4 digits
division PROC
    call div_zero ; check if its divide by zero
    .IF op_error == 1
        jmp carry5
    .ENDIF

    call change_unpack ; return unpack buffer in ebx, unpack save in edx
    call change_hex ; return hex buffer in ebx, hex save in edx
    mov eax, edx ; dividend

    mov edx, 0
    div ebx

    call change_ascii ; edx:eax = remainder:quotient hex to ascii in save

    call print_save
    call clear_buffer
    jmp div_done
    carry5:
        call print_error
    div_done:
    ret
division ENDP

; // check divide by zero
div_zero PROC
    mov esi, OFFSET buffer
    mov ecx, 0

    L16:
        cmp ecx, digits
        jz _L16

        mov al, BYTE PTR [esi + ecx]
        .IF al != '0'
            mov f_temp2, 0 ; non zero
            jmp _L16
        .ENDIF
        inc ecx
        jmp L16
    _L16:
    .IF f_temp2 == 1
        mov op_error, 1
    .ENDIF
    mov f_temp2, 1
    ret
div_zero ENDP

; return unpack buffer in ebx, unpack save in edx
change_unpack PROC
    mov esi, OFFSET buffer
    mov edi, OFFSET save
    mov ecx, 0
    mov ebx, 0 ; buffer
    mov edx, 0 ; save
    L17:
        cmp ecx, digits
        jz _L17

        mov eax, 0
        mov al, BYTE PTR [esi]
        add al, '0'
        aaa ; ascii to unpack
        mov bl, al
        .IF ecx < digits - 1
            shl ebx, 8 ; shift 1 BYTE
        .ENDIF

        mov eax, 0
        mov al, BYTE PTR [edi]
        add al, '0'
        aaa ; ascii to unpack
        mov dl, al
        .IF ecx < digits - 1
            shl edx, 8 ; shift 1 BYTE
        .ENDIF

        inc esi
        inc edi
        inc ecx
        jmp L17
    _L17:
    ret
change_unpack ENDP

; return hex buffer in ebx, hex save in edx
change_hex PROC
    mov eax, edx
    push eax ; unpack save
    push eax ; unpack save
    mov eax, ebx
    push eax ; unpack buffer
    shr eax, 16 ; first 2 unpacks in ax
    aad ; unpack to hex
    mov ecx, 100
    mul ecx
    mov ebx, eax ; move it to ebx

    pop eax ; unpack buffer
    and eax, 0000FFFFh
    aad ; unpack to hex
    add ebx, eax ; ebx is now hex buffer

    pop eax ; unpack save
    shr eax, 16 ; first 2 unpacks in ax
    aad ; unpack to hex
    mov ecx, 100
    mul ecx
    mov edx, eax ; move it to edx

    pop eax ; unpack save
    and eax, 0000FFFFh
    aad ; unpack to hex
    add edx, eax ; edx is now hex save
    ret
change_hex ENDP

; edx:eax = remainder:quotient hex to ascii in save
change_ascii PROC
    mov esi, OFFSET save

    mov edx, 0
    mov ebx, 1000
    div ebx
    or al, 30h
    mov BYTE PTR [esi], al
    inc esi

    mov eax, edx ; change quotient with remainder
    mov edx, 0
    mov ebx, 100
    div ebx
    or al, 30h
    mov BYTE PTR [esi], al
    inc esi

    mov eax, edx ; change quotient with remainder
    mov edx, 0
    mov ebx, 10
    div ebx
    or al, 30h
    mov BYTE PTR [esi], al
    inc esi

    mov eax, edx ; change quotient with remainder
    mov edx, 0
    mov ebx, 1
    div ebx
    or al, 30h
    mov BYTE PTR [esi], al
    inc esi

    call update_save_count
    ret
change_ascii ENDP

; // Operator
operate_calculator PROC
    call print_calculator
    call user_input
    ret
operate_calculator ENDP

main PROC
    call operate_calculator

    INVOKE ExitProcess, 0
main ENDP
END main