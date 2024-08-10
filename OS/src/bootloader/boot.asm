ORG 0x7c00
bits 16

;FAT12 header(Jumps so that we do not execute BDP that is not code)
jmp short start
nop
;boot records!
bdb_oem:                    db  "MSW1N4.1"  ;8 bytes
bdb_bytes_per_sector:       dw  512
bdb_sectors_per_cluseter:   db  1
bdb_reserved_sectors:       dw  1
bdb_fat_count:              db  2
bdb_dir_entries_count:      dw  0E0h
bdb_total_sectors:          dw  2880        ;2880*512=1.44mb
bdb_media_descriptor_type:  db  0F0h
bdb_sectors_per_fat:        dw  9
bdb_sectors_per_track:      dw  18
bdb_heads:                  dw  2
bdb_hidden_sectors:         dd  0
bdb_large_sector_count:     dd  0

;extended boot record
ebr_drive_number:           db  0           ;0x00 floppy,0x80 hdd
                            db  0           ;reserved
ebr_signature:              db  29h
ebr_volume_id:              db  12h,34h,56h,78h
ebr_volume_label:           db  "NANOBYTE OS";11 bytes
ebr_system_id:              db  "FAT12   "   ;8 bytes

;code goes here

start:
    jmp     main

puts:

    push    si
    push    ax

.loop:

    lodsb   
    or      al,al
    jz      .done

    mov     ah,0x0e
    int     0x10

    jmp     .loop

.done:
    pop     ax
    pop     si
    ret

main:

    ;setting up data segment register
    mov     ax,0
    mov     ds,ax
    mov     es,ax

    ;setting up the stack
    mov     ss,ax
    mov     sp,0x7c00

    ;read something from floppy ddisk
    ;BIOS should set DL to drive number
    mov     [ebr_drive_number],dl

    mov     ax,1    ;LBA=1 second sector from disk
    mov     cl,1    ;1 sector to read
    mov     bx,0x7E00   ;data should be after bootloader
    call    disk_read

    mov     si,message
    call    puts    
    cli
    hltwh
floppy_error:
    mov     si,error_msg
    call    puts
    jmp     wait_key_and_reboot

wait_key_and_reboot:
    mov     ah,0
    int     16h     ;wait for keypress
    jmp     0FFFFh:0    ;jump to beginning of BIOS,should reboot
.halt:
    
    hlt
;Converts LBS address to CHS address
;Parameters:
;   ax: LBA address
;Returns:
;   cx(bits 0-5):sector number
;   cx(bits 6-15):cylinder
;   dh:head

lba_to_chs:

    push    ax
    push    dx

    xor     dx,dx   ;dx = 0
    div     word    [bdb_sectors_per_track] ;ax=LBA/SectorsPerTrack
                                            ;dx=LBA%SectorsPerTrack
    inc     dx      ;sector=dx=LBA%SectorsPerTrack + 1
    mov     cx,dx   ;cx=sector

    xor     dx,dx
    div     word    [bdb_heads] ;ax=(LBA/SectorsPerTrack)/Heads=Cylinder
                                ;dx=(LBA/SectorsPerTrack)%Heads=head
    mov     dh,dl               ;dh=head
    mov     ch,al               ;ch=Cylinder(lower 8 bits)
    shl     ah,6                
    ;causes 0 for 0-5 bits of al allowing for cx(0-5) bits to retain its value
    or      cl,ah
;you are probably wondering how this arrangement makes sense but thats how int 13h works here
    pop     ax
    mov     dl,al   ;since we cannot move 8 bit values into stack  here
    ;we do this so that dh value is not replaced
    pop     ax

    ret


;reads from disk
;parameters:
;   ax:LBA address
;   cl:Number of sectors to read(upto 128)
;   dl:drive number
;   es:bx:memory where to store read data
disk_read:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    push    cx  ;temporarily save cl
    call    lba_to_chs  ;compute chs
    pop     ax  ;al=number of sectors to read
    mov     ah,02h  ;reading sectors from the disk
    mov     di,3    ;retry count

.retry:
    pusha       ;push all registers to stack
    stc         ;set carry flag
    int     13h     ;interrupt to interact with disk drives
    ;carry flag cleared=success
    jnc     .done

    ;read failed
    popa
    call    disk_reset

    dec     di
    test    di,di   ;bitwise AND and sets the flag
    ;will set zero flag only if di=0
    jnz     .retry 

.fail:
    jmp     floppy_error

.done:
    popa

    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret

disk_reset:
    pusha   
    mov     ah,0    ;resetting disk system
    stc
    int     13h
    jc      floppy_error
    popa
    ret

message:    db    "Hello World",0
error_msg:  db    "Read from disk failed",0

times 510-($-$$) db 0
dw 0xAA55