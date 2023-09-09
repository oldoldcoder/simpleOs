; haribote-ipl
; TAB=4

CYLS	EQU		10				; 声明CYLS=10

		ORG		0x7c00			; 指明程序装载地址

; 标准FAT12格式软盘专用的代码 Stand FAT12 format floppy code

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; 启动扇区名称（8字节）
		DW		512				; 每个扇区（sector）大小（必须512字节）
		DB		1				; 簇（cluster）大小（必须为1个扇区）
		DW		1				; FAT起始位置（一般为第一个扇区）
		DB		2				; FAT个数（必须为2）
		DW		224				; 根目录大小（一般为224项）
		DW		2880			; 该磁盘大小（必须为2880扇区1440*1024/512）
		DB		0xf0			; 磁盘类型（必须为0xf0）
		DW		9				; FAT的长度（必??9扇区）
		DW		18				; 一个磁道（track）有几个扇区（必须为18）
		DW		2				; 磁头数（必??2）
		DD		0				; 不使用分区，必须是0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明（固定）
		DD		0xffffffff		; （可能是）卷标号码
		DB		"HARIBOTEOS "	; 磁盘的名称（必须为11字?，不足填空格）
		DB		"FAT12   "		; 磁盘格式名称（必??8字?，不足填空格）
		RESB	18				; 先空出18字节

; 程序主体

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX
; int 3 to read disk
        mov ax,0x0820
        mov es,ax
        mov ch,0 	;柱面0
        mov dh,0	;磁头0
        mov dh,0	;扇区2
readloop:
        mov si,0	;记录失败次数的寄存器
retry:
        mov ah,0x02	;ah=0x02 读入磁盘
        mov al,1	;1个扇区
        mov bx,0
        mov dl,0x00	;a驱动器
        int 0x13 	;调用磁盘的bios函数
        jnc next	;没有出现进位就说明没出错
        add si,1	;证明出错了一次
        cmp si,5	;比较是否出错次数超过了5次
        jae error	;si>=5,则跳转到error
        mov ah,0x00
        mov dl,0x00
        int 0x13
        jmp retry

next:
        mov ax,es	;把内存地址后移0x200
        add ax,0x0020
        mov es,ax	;重新把数据写回去
        add cl,1	;给柱面+1
        cmp cl,18	;比较cl与18
        jbe readloop	;如果cl<= 18 则跳转到readloop继续读取
        mov cl,1	;重新从第一个扇区开始读取
        add dh,1
        cmp dh,2
        jb	readllop	;如果dh<2，则跳转到readloop
        mov dh,0
        add ch,1
        cmp ch,cyls
        jb readloop	;如果ch<柱面数，就跳转到readloop
; 读取完毕，跳转到haribote.sys执行！
		MOV		[0x0ff0],CH		; IPLがどこまで読んだのかをメモ
		JMP		0xc200

error:
		MOV		SI,msg

putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 给SI加1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示一个文字
		MOV		BX,15			; 指定字符颜色
		INT		0x10			; 调用显卡BIOS
		JMP		putloop

fin:
		HLT						; 让CPU停止，等待指令
		JMP		fin				; 无限循环

msg:
		DB		0x0a, 0x0a		; 换行两次
		DB		"load error"
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 填写0x00直到0x001fe

		DB		0x55, 0xaa