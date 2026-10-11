bits 16
org 0x7C00

KERNEL_SECTORS  equ 32
KERNEL_ADDR     equ 0x1000

start: 
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl
    mov si, msg_loading 
    call print_string

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, KERNEL_ADDR
    int 0x13
    jc .disk_error

    mov dl, [boot_drive]
    jmp KERNEL_ADDR
    
.disk_error:
    mov si, msg_err
    call print_string
    jmp $
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

boot_drive: db 0
msg_loading: db "Loading Mentha...", 13, 10, 0
msg_ok:      db "OK", 13, 10, 0
msg_err:     db "Disk error!", 13, 10, 0

    times 510-($-$$) db 0
    dw 0xAA55