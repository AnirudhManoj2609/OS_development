 ORG 0x7c00
bits 16

start:
    jmp main

puts:

    push si
    push ax

.loop:

    lodsb   
    or  al,al
    jz  .done

    mov ah,0x0e
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret

main:

    ;setting up data segment register
    mov ax,0
    mov ds,ax
    mov es,ax

    ;setting up the stack
    mov ss,ax
    mov sp,0x7c00

    mov si,message
    call puts    

    hlt

.halt:
    jmp .halt

message:    db    "Hello World",0

times 510-($-$$) db 0
dw 0xAA55