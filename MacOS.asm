[org 0x7c00]    

    
    mov ah, 0x0E                ; Teletype mode
    mov bx, msg1                ; Carga mensaje para usuario


printMessage:
	mov al, [bx]                ; puntero a registro al, caracter a desplegar
	cmp al, 0                   ; compara si al == 0
	je exitPrintMessage         ; si son iguales, se sale de la funcion
	int 0x10                    ; sino, pide interrupcion al bios
	inc bx                      ; incrementa bx, cambia a nuevo caracter
	jmp printMessage            ; vuelve a empezar


exitPrintMessage:
    mov bx, fallingMessage      ; mueve el input a bx
    mov cx, [bx]                ; puntero al bx   
    mov cx, 15                  ; Contador. Cuidado con el tama;o del buffer


readInput:
	mov ah, 0                   ; Lee caracter
	int 0x16                    ; Obtiene funcionalidades del teclado

	cmp al, 0xD                 ; Verifica si se oprmio Enter
	je enter                    ; Brinca a label enter                             
	cmp cx, 0                   ; Verifica contador
	je readInput                ; Brinca a readInput   
	mov ah, 0x0E                ; Teletype Mode
	int 0x10                    ; Interrupcion

	mov [bx], al                ; Guarda caracter en buffer
	inc bx                      ; Siguiente campo
	dec cx                      ; Decrementa el contador
	jmp readInput               ; Vuelve a empezar


enter:
	mov ah, 0xE                 ; print new line
	mov al, 0xD                 ; Carriage Return
	int 0x10                    ; Interrupcion

	mov al, 0xA                 ; lf line feed (newline)
	int 0x10                    ; Interrupcion
	mov bx, fallingMessage      ; print the buffer



setVideoMode:                   ; Mode 80x25
    mov  ax, 0003h              ; BIOS SetVideoMode AH=00h, AL= Video Mode Flag (3)
    int  10h                    ; Interrupcion

    mov  bx, 0002h              ; Pagina bh = 0, color bl = 02h (verde)
    mov  cx, 1                  ; Contador de repeticiones cx = 1
    mov  dx, 0000h              ; Row dh = 0 | Column dl = 0


printFallingCode:
    mov  ah, 02h                ; BIOS Set Cursor
    int  10h                    ; Interrupcion
    
    lodsb                       ; Carga byte SI into AL
    cmp al, 0                   ; Verifica si se llego al final del string
    je changeCursorColumn       ; Continua ejecucion en otro lado (changeCursorColumn)
    call delay
    mov  ah, 09h                ; BIOS Display Character AH=09h y caracter en al
    int  10h                    ; interrupcion
    
    cmp dh, 18h                 ; comparar si llega a fila > 24 (24d -> 18h)
    jg newDrop     
    inc  dh                     ; Incrementa fila
    jns  printFallingCode       ; Will stop when DH becomes -1
    

delay:                          ; Crea un delay a la hora de imprimir un caracter
    mov ah, 86h                 ; INT 15h / AH = 86h 
    int 15h                     ; BIOS wait function
    ret                         ; retorna donde lo llamaron


changeCursorColumn:
    mov si, fallingMessage      ; vuelve a cargar el mensaje al registro si
    mov bx, 0002h               ; pagina 0 y color verde
    mov cx, 1                   ; 1 repeticion por caracter
    inc dl                      ; cambia de columna
    jmp printFallingCode


newDrop:                        ; Nueva fila de caracteres cuando la anterior termina
    mov dh, 00h                 ; Fila 0
    jmp printFallingCode        ; Brinca a la funcion que imprime


done:                           
    ret                         ; Para retornar al lugar de la llamada


msg1:
    db "Ingrese un texto, no mas de 15 caracteres:", 0xd, 0xa, 0


fallingMessage:                 ; Buffer para el input
    times 15 db 0
    db 0                        


times 510-($-$$) db 0           ; Para el boot sector
dw 0xAA55                       ; Ultimos numeros indicando que es booteable