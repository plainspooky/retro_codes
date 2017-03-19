;
;   Interpreta a 'tail' dos comandos do MSX-DOS (e CP/M)
;
ASCII_LF:   equ 10                      ; avanço de linha ("line feed")
ASCII_CR:   equ 13                      ; retorno de carro ("carriage return")

BOOT:       equ $00                     ; rotina Boot()
PUTCHAR:    equ $02                     ; rotina PutChar()
PUTSTR:     equ $09                     ; rotina PutString()

zpArgvLen:  equ $0080                   ; tamanho do buffer de argumentos
zpArgvStr:  equ $0081+1                 ; início da string com os argumentos (corrigido)

macro   ____bdos,BDOS
            ld c,BDOS
            call $0005                  ; faz a chamada à BDOS
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

        ____print "Test command line tail"
            ld a,(zpArgvLen)            ; Lê o conteúdo do endereço $80 da Zero page
            cp 0                        ; verifica se é zero
            jr nz,hasTail               ; se >0 vai para 'hasTail'

        ____print "*** No arguments!"   ; avisa que não há argumentos
            jp endProgram               ; e sai do programa

;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

macro   ____test,param,option           ; chama a rotina de lookup
            ld c,param
            call lookup
            jp z,option
            endm

hasTail:
            ld hl,zpArgvLen             ; inicio da string

            call getFilename            ; recupera o nome do arquivo (até 8 caracteres)

            ld (paramIdx),hl            ; guarda o início dos parâmetros
            ld a,(zpArgvLen)            ; tamanho da string
            sub c                       ; retira o que foi utilizado
            ld (paramLen),a             ; guarda este novo tamanho

        ____test "H", printHelp1        ; Busca por "/H"

        ____test "h", printHelp2        ; Busca por "/h"

            ld a,(filename)             ; foi recuperado um nome de arquivo?
            cp "$"
            jr z,endProgram             ; sai se não for inserido nome de arquivo

            ld de,filename
        ____bdos PUTSTR                 ; imprime o nome de arquivo

            jr endProgram               ; sai do programa

printError:
        ____print "Ilegal parameter"    ; caso os parâmetros não sejam entendidos

endProgram:
        ____bdos BOOT                   ; retorna ao MSX-DOS (ou CP/M)

;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

printHelp1:
            ld de,mensa1                ; mensagem 1
            jr printHelp
printHelp2:
            ld de,mensa2                ; mensagem 2
printHelp:
        ____bdos PUTSTR                 ; imprime a mensagem na tela
            jr endProgram               ; e sai do programa

mensa1:
            db "Use:",ASCII_CR,ASCII_LF
            db "testargs <filename> [/H] [/h]",ASCII_CR,ASCII_LF
            db "Parameters:",ASCII_CR,ASCII_LF
            db "    /H : This help",ASCII_CR,ASCII_LF
            db "    /h : Another help",ASCII_CR,ASCII_LF,"$"
mensa2:
            db "Use:",ASCII_CR,ASCII_LF
            db "testargs <filename> [/H] [/h]",ASCII_CR,ASCII_LF
            db "Parameters:",ASCII_CR,ASCII_LF
            db "    /H : Another help",ASCII_CR,ASCII_LF
            db "    /h : This help",ASCII_CR,ASCII_LF,"$"

;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

macro   ____abort,char
            cp char
            jr z,endLoop
            endm

getFilename:
            proc
            local loop
            local endLoop

            ld b,12                     ; tamanho máximo da string
            ld c,1                      ; começa com 1, não 0
            ld de,filename              ; variável com o nome do arquivo
            ld hl,zpArgvStr             ; 'HL' no começo da string
    loop:
            ld a,(hl)                   ; lê um caracter
        ____abort "/"                   ; sai da rotina se for "/"
        ____abort " "                   ; sai da rotina se for " "
            ld (de),a                   ; copia o caracter para a variável
            inc c                       ; contador de caracteres
            inc de                      ; incrementa o ponteiro de destino
            inc hl                      ; incrementa o ponteiro de origem
            djnz loop                   ; enquanto 'B'>0 faz o laço
    endLoop:
            ret                         ; sai da rotina
            endp

paramIdx:   dw 0
paramLen:   db 0
filename:   ds 13,"$"                   ; só servirá para imprimir, pode ser "$"

;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

lookup:
            proc
            local command
            local endLoop
            local switch

            ld a,(paramLen)             ; 'A' com o novo tamanho da string
            ld b,a                      ; 'B' com o valor em 'A'
            ld ix,(paramIdx)            ; 'IX' começa depois do nome do arquivo
    switch:
            ld a,(ix)                   ; lê um caracter da string
            cp "/"                      ; procura pelo início de um parâmetro
            jr z,command                ; é "/" verifica se há um comando
            inc ix                      ; incrementa 'IX'
            djnz switch                 ; enquanto B>0 faz o laço
            jr endLoop                  ; vai para o final da rotina

    command:
            ld a,(ix+1)                 ; lê o caracter seguinte
            cp c                        ; compara com 'C'
            ret z                       ; sai se for zero
            inc ix                      ; incrementa 'IX'
            djnz switch                 ; enquanto B>0 faz o laço
    endLoop:
            neg                         ; nega 'A' (força "NÃO ZERO")
            ret                         ; sai da rotina
            endp
