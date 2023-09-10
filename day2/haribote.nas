; haribote-os
; TAB=4
    org 0xc200
    mov al,0x13 ;vga显卡，320*200*8位色彩
    mov ah,0x00
    int 0x10