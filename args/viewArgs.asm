;
;    Visualiza a 'tail' dos comandos do MSX-DOS (e CP/M)
;
ASCII_LF:   equ 10                      ; avanço de linha ("line feed")
ASCII_CR:   equ 13                      ; retorno de carro ("carriage return")

BOOT:       equ $00                     ; rotina Boot()
PUTCHAR:    equ $02                     ; rotina PutChar()
PUTSTR:     equ $09                     ; rotina PutString()

zpArgvLen:  equ $0080                   ; tamanho do buffer de argumentos
zpArgvStr:  equ $0081                   ; início da string com os argumentos

macro   ____bdos,BDOS
            ld c,BDOS
            call $0005                  ; chamada à BDOS em MSX-DOS
            endm

macro   ____print,str                   ; macro que simula PRINT "str"
            proc
            local _jump
            local _string
            ld de,_string
        ____bdos PUTSTR
            jp _jump
    _string:
            db str,ASCII_CR,ASCII_LF,"$"
    _jump:
            endp
            endm

            org 0x0100

        ____print "View command line tail"
            ld a,(zpArgvLen)            ; lê o tamanho da string de argumentos
            cp 0                        ; verifica se é igual a zero
            jr nz,hasTail               ; se >0 vai para 'hasTail'

        ____print "*** No arguments!"   ; avisa que não há argumentos
            jp programEnd               ; e sai do programa

hasTail:
        ____print "Command tail:"       ; mensagem de que há argumentos
            ld hl,zpArgvLen             ; 'HL' com a posição do tamanho
            ld b,(hl)                   ; lê novamente o tamanho da string
            inc hl                      ; 'HL' para o começo da string
printLoop:
            ld e,(hl)                   ; lê um caracter da string
            push hl                     ; salva HL na pilha
            push bc                     ; salva BC na pilha
        ____bdos PUTCHAR
            pop bc                      ; restaura BC da pilha
            pop hl                      ; restaura HL da pilha
            inc hl                      ; incrementa 'HL'
            djnz printLoop              ; se 'B' < 0 faz o laço

        ____print "<End>"               ; assinala o final da string

programEnd:
        ____bdos BOOT                   ; retorna ao MSX-DOS (ou CP/M)
