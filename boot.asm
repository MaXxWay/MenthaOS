bits 16
org 0x7C00
start:
    call clear_screen
    call move_cursor
    mov si, msg
    call print_string
.loop:
    call read_key

    cmp al, 27  ; esc
    je .done
    cmp al, 8   ; backspace
    je .backspace
    cmp al, 13  ; enter
    je .enter

    mov ah, 0x0e
    int 0x10
    call buf_add
    jmp .loop

.backspace:
    mov ah, 0x0e
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    call buf_del
    jmp .loop

.enter:
    mov bx, [buf_pos]
    mov si, buffer
    add si, bx
    mov byte [si], 0

    mov ah, 0x0e
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

    mov si, buffer
    call print_string

    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

    call buf_reset
    jmp .loop
    
.done:
    jmp $
clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10
    ret

move_cursor:
    mov ah, 0x02
    mov bh, 0
    mov dx, 0x0000
    int 0x10
    ret

read_key: 
    mov ah, 0x00
    int 0x16
    ret
print_string:
    lodsb 
    test al, al 
    jz .done
    int 0x10
    jmp print_string
.done:
    ret
buf_add:
    mov bx, [buf_pos]       
    mov si, buffer          
    add si, bx             
    mov [si], al            
    inc word [buf_pos]      
    ret
buf_del:
    cmp word [buf_pos], 0
    je .empty
    dec word [buf_pos]
    mov bx, [buf_pos]
    mov si, buffer
    add si, bx
    mov byte [si], 0
.empty:
    ret

buf_reset:
    mov word [buf_pos], 0
    ret
msg: db "Mentha OS", 13, 10, 13, 10, 13, 0
buffer: times 64 db 0
buf_pos: dw 0

    times 510-($-$$) db 0
    dw 0xaa55