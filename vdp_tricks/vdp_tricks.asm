__VERSION:  equ 1
__RELEASE:  equ 0

CHGCLR:     equ 0x0062                  ; Altera cores do VDP
CHGMOD:     equ 0x005F                  ; Altera modo do VDP
WRTVDP:     equ 0x0047                  ; Escreve em registrador do VDP
WRTVRM:     equ 0x004D                  ; Escreve byte na VRAM
LDIRVM:     equ 0x005C                  ; Copia bloco da RAM para a VRAM

FORCLR:     equ 0xF3E9                  ; Cor do primeiro plano
BAKCLR:     equ 0xF3EA                  ; Cor do segundo plano (fundo)
BDRCLR:     equ 0xF3EB                  ; Cor da borda
JIFFY:      equ 0xFC9E                  ; Contador incrementos de interrupções do VDP

romSize:    equ 8192                    ; tamanho do cartucho em 8KiB
romArea:    equ 0x4000
ramArea:    equ 0xe000
            org romArea
            db "AB"
            dw startCode                ; início da ROM
            db "VDP1"
            db __VERSION+48
            db __RELEASE+65
            ds 6,0

ceiling:    equ ramArea                 ; área da RAM para o padrão do teto
floor:      equ ramArea+65              ; área da RAM para o padrão do chão

startCode:
            ld a,15
            ld (FORCLR),a               ; cor de frente em branco (15)
            xor a
            ld (BAKCLR),a               ; cor do fundo e também
            ld (BDRCLR),a               ; da borda em transparente (0)

            call CHGCLR                 ; troca as cores da tela

            ld a,2
            call CHGMOD                 ; troca o modo de vídeo para SCREEN 2

            ld b,%11100000              ; tabela de atributos com 64 bytes em
                                        ; cada um dos terços da tela

            ld c,3                      ; registrador 3 do VDP
            call WRTVDP                 ; escreve o novo valor

            ld bc,2048                  ; quantidade de bytes para copiar
            ld de,0                     ; endereço inicial da VRAM, 1º terço
            ld hl,ceilingPattern        ; endereço do padrão do teto
            call LDIRVM                 ; copia da RAM para a VRAM

            ld bc,2048                  ; quantidade de bytes para copiar
            ld de,4096                  ; endereço inicial da VRAM, 3º terço
            ld hl,floorPattern          ; endereço do padrão do chão
            call LDIRVM                 ; copia da RAM para a VRAM

            ld hl,6144                  ; início da tabela de nomes do 1º terço
            call organizeChars          ; reorganiza a tabela para ficar "linear"

            ld hl,6144+512              ; início da tabela de nomes do 3º terço
            call organizeChars          ; reorganiza a tabela para ficar "linear"

            ld bc,32                    ; 32 bytes
            ld de,ceiling               ; tabela de atributos do teto na RAM
            ld hl,ceilingAttributes     ; tabela de atributos do teto na ROM
            ldir                        ; copio da ROM para a RAM
            ld bc,32                    ; novamente com 32 bytes
            ld hl,ceilingAttributes     ; tabela de atributos do teto na ROM
            ldir                        ; repito a cópia (DE já está no valor certo)

            ld bc,32                    ; 32 bytes
            ld de,floor                 ; tabela de atributos do chão na RAM
            ld hl,floorAttributes       ; tabela de atributos do chão na ROM
            ldir                        ; copio da ROM para a RAM
            ld bc,32                    ; novamente com 32 bytes
            ld hl,floorAttributes       ; tabela de atributos do chão na ROM
            ldir                        ; repito a cópia (DE já tem o valor correto)

loop:
            ld hl,0
            ld (JIFFY),hl               ; zero o TIMER do sistema
            call animation              ; chamo a rotina de animação
sync:
                ld a,(JIFFY)            ; leio o TIMER do sistema
                cp 2                    ; 2/60 = 1/30s =~0.03s em NTSC
                                        ; 2/50 = 1/25s = 0.04s em PAL
                jr c, sync              ; pule para 'sync' se TIMER<=2

            jr loop                     ; pule para 'loop'

animation:
            proc
            local animationLoop

            ld ix,ceiling               ; IX no começo do teto
            ld a,(ix)                   ; A recebe o primeiro byte do teto
            ld (ix+64),a                ; coloca no final dos atributos do teto

            ld iy,floor+62              ; IY para a penúltima posição do chão
            ld a,(iy+1)                 ; A recebe a última posição do chão
            ld c,a                      ; guarda este valor em C

            ld b,64                     ; número de repetições do laço
animationLoop:
                ld a,(ix+1)             ; A recebe o valor de IX+1
                ld (ix),a               ; o coloco em IX
                inc ix                  ; incrementa IX

                ld a,(iy)               ; A recebe o valor de IY
                ld (iy+1),a             ; o coloco em IY+1
                dec iy                  ; diminuo IY

                djnz animationLoop      ; decremento B, volto para o laço se B>0

            ld a,c                      ; recupero a posição do chão em C
            ld (floor),a                ; e a coloco no começo do chão

            ld bc,64                    ; 64 bytes para transferir
            ld de,8192                  ; começo da tabela de atributos do 1º terço
            ld hl,ceiling               ; tabela de atributos do teto na RAM
            call LDIRVM                 ; copio o novo padrão para a VRAM

            ld bc,64                    ; 64 bytes para transferir
            ld de,12288                 ; começo da tabela de atributos do 3º terço
            ld hl,floor                 ; tabela de atributos do chão na RAM
            call LDIRVM                 ; copio o novo padrão para a VRAM

            ret                         ; sai da rotina
            endp

organizeChars:
            proc
            local loop0, loop1

            ld b,8                      ; número de repetições do 1º lao
            ld a,0                      ; valor inicial de A
loop0:
                push af                 ; salva A
                push bc                 ; salva B
                ld b,32                 ; número de repetições do 2º laço
loop1:
                    call WRTVRM         ; escreve A no endereço HL da VRAM
                    add a,8             ; A=A+8
                    inc hl              ; incrementa HL
                    djnz loop1          ; decremento B, volto para o laço se B>

                pop bc                  ; recupero B
                pop af                  ; recupero A
                inc a                   ; incre3mento A
                djnz loop0              ; decremento B, volto para o laço se B>

            ret                         ; sai da rotina
            endp

ceilingPattern:
            incbin "ceiling.inc"        ; padrão do teto

floorPattern:
            incbin "floor.inc"          ; padrão do chão

ceilingAttributes:
floorAttributes:
            db 0x4f,0x4f,0x4f,0x4f,0x4f,0x4f,0x4f,0x4f
            db 0x4f,0x4f,0x4f,0x4f,0x4f,0x4f,0x4f,0x4f
            db 0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4
            db 0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4,0xf4

romPad:
            ds romSize-(romPad-romArea),0

            end
