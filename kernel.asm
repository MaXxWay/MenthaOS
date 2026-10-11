bits 16
org 0x1000

start:
    mov [boot_drive], dl

    mov ax, 0x0003
    int 0x10

    call clear_screen
    mov si, prompt
    call print_string

.loop:
    mov ah, 0x00
    int 0x16

    cmp al, 27
    je .done
    cmp al, 8
    je .backspace
    cmp al, 13
    je .enter

    mov ah, 0x0E
    int 0x10
    call buf_add
    jmp .loop

.backspace:
    cmp word [buf_pos], 0
    je .loop
    mov ah, 0x0E
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

    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

    mov si, buffer
    mov di, cmd_help
    call cmd_match
    jz .cmd_help

    mov si, buffer
    mov di, cmd_ver
    call cmd_match
    jz .cmd_ver

    mov si, buffer
    mov di, cmd_cls
    call cmd_match
    jz .cmd_cls

    mov si, buffer
    mov di, cmd_echo
    call cmd_match
    jz .cmd_echo

    mov si, buffer
    mov di, cmd_reboot
    call cmd_match
    jz .cmd_reboot

    mov si, msg_unknown
    mov bl, 0x04
    call print_color
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    jmp .prompt

.cmd_help:
    mov si, msg_help_hdr
    call print_string

    mov bl, 0x03
    mov si, msg_help1
    call print_color
    mov si, msg_help1d
    call print_string

    mov bl, 0x03
    mov si, msg_help2
    call print_color
    mov si, msg_help2d
    call print_string

    mov bl, 0x03
    mov si, msg_help3
    call print_color
    mov si, msg_help3d
    call print_string

    mov bl, 0x03
    mov si, msg_help4
    call print_color
    mov si, msg_help4d
    call print_string

    mov bl, 0x03
    mov si, msg_help5
    call print_color
    mov si, msg_help5d
    call print_string

    jmp .prompt

.cmd_ver:
    mov si, msg_ver
    call print_string
    jmp .prompt

.cmd_cls:
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    jmp $

.cmd_echo:
    cmp byte [si], ' '
    jne .no_space
    inc si
.no_space:
    call print_string
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    jmp .prompt

.cmd_reboot:
    mov si, msg_reboot
    call print_string
    int 0x19
    jmp $

.prompt:
    mov word [buf_pos], 0
    mov si, prompt
    call print_string
    jmp .loop

.done:
    jmp $

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    xor dx, dx
    mov bh, 0
    int 0x10
    ret

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; SI = строка, BL = цвет
; Поддерживает CR (13) и LF (10)
print_color:
    mov bh, 0
.next:
    lodsb
    test al, al
    jz .done
    cmp al, 13
    je .cr
    cmp al, 10
    je .lf
    mov ah, 0x09
    mov cx, 1
    int 0x10
    mov ah, 0x03
    int 0x10
    inc dl
    cmp dl, 80
    jb .set
    mov dl, 0
    inc dh
.set:
    mov ah, 0x02
    int 0x10
    jmp .next
.cr:
    mov ah, 0x03
    int 0x10
    mov dl, 0
    mov ah, 0x02
    int 0x10
    jmp .next
.lf:
    mov ah, 0x03
    int 0x10
    inc dh
    mov ah, 0x02
    int 0x10
    jmp .next
.done:
    ret

cmd_match:
    push si
    push di
.loop:
    mov al, [di]
    test al, al
    jz .prefix_ok
    cmp al, [si]
    jne .no
    inc si
    inc di
    jmp .loop
.prefix_ok:
    mov al, [si]
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
.no:
    pop di
    pop si
    or al, 1
    ret
.yes:
    pop di
    add sp, 2
    xor al, al
    ret

buf_add:
    mov bx, [buf_pos]
    cmp bx, 127
    jae .full
    mov si, buffer
    add si, bx
    mov [si], al
    inc word [buf_pos]
.full:
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

boot_drive:  db 0
prompt:      db "Mentha> ", 0
cmd_help:    db "help", 0
cmd_ver:     db "ver", 0
cmd_cls:     db "cls", 0
cmd_echo:    db "echo", 0
cmd_reboot:  db "reboot", 0

msg_help_hdr:   db "Commands:", 13, 10, 0
msg_help1:      db "  help    ", 0
msg_help1d:     db "- show this help", 13, 10, 0
msg_help2:      db "  ver     ", 0
msg_help2d:     db "- show version", 13, 10, 0
msg_help3:      db "  cls     ", 0
msg_help3d:     db "- shutdown", 13, 10, 0
msg_help4:      db "  echo    ", 0
msg_help4d:     db "- print text", 13, 10, 0
msg_help5:      db "  reboot  ", 0
msg_help5d:     db "- reboot system", 13, 10, 0

msg_ver:     db "Mentha OS v0.1", 13, 10, 0
msg_reboot:  db "Rebooting...", 13, 10, 0
msg_unknown: db "Unknown command", 0
buffer:      times 128 db 0
buf_pos:     dw 0