;
;  TI-99's PARSEC Demo
;
;  It's not a game or even a draft of a game... I was just studing!
;
;  Copyright 2018 Giovanni dos Reis Nunes <giovanni.nunes@gmail.com>
;
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
;  MA 02110-1301, USA.
;

;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *  All graphics were extracted from Parsec cartridge and TI-99/4A
;  *  system ROM and still could be copyright of Texas Instruments.
;  *  If I'm infringing any copy let me know.
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

INCLUDE		./library/msx1bios.asm
INCLUDE		./library/msx1variables.asm

MAXSTAR:	equ 31					; número máximo de estrelas

			org 0x9000-7
			db $fe
			dw start
			dw stop
			dw exec

start:
exec:
			call TI99BOOT			; "zoeira never end"!

			call DISSCR				; desligo a exibição da tela

			call INITENV
			call PREPSCR

			ld bc,256				; o padrão inicial do solo é...
			ld de,BUFFER0
			ld hl,GROUND0
			ldir

			ld bc,256				; feito por quatro repetições
			ld hl,GROUND0
			ldir

			ld bc,256				; do primeiro quarto do
			ld hl,GROUND0
			ldir

			ld bc,256				; primeiro padrão do solo.
			ld hl,GROUND0
			ldir

			call ENASCR				; religo a exibição da tela

			;
			; Gambiarra só pra ver como fica
			;
			ld hl,6912					; primeiro sprite
			ld a,87						; posição Y
			call ANIMATE0
			ld a,64						; posição X do sprite
			call ANIMATE0
			ld a,4						; padrão do sprite (1)
			call ANIMATE0
			ld a,12						; cor do sprite
			call ANIMATE0

			call NEWGROUND				; sorteia um novo chão

			ld (GROUNDRPT),a			; zero o contador do scroll

ANIMATE:	ld hl,0
			ld (JIFFY),hl				; zero o temporizador

			call STARFIELD				; faz a animação do céu

			call ROTATE					; rotaciona o cenário

			ld b,6
			call WAITASEC

			jr ANIMATE

ANIMATE0:	call WRTVRM
			inc hl
			ret

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  inicializa o ambiente
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
INITENV:	call TURBOMODE				; é um turbo R? pare de sofrer!

			ld a,15						; BRANCO
			ld (FORCLR),a				; cor da frente em branco
			xor a						; TRANSPARENTE
			ld (BAKCLR),a				; cor de fundo
			ld (BDRCLR),a				; cor da borda
			call CHGCLR					; agora mudo as cores da tela

			call INIGRP					; entro na SCREEN2

			ld a,(RG1SAV)				; leio o valor do registro 1
			and 0xec					; mexerei nos bits 0 e 1, salvo o resto
			or 2						; ajusto os sprites para 16x16 sem zoom
			ld b,a						; B=A
			ld c,1
			call WRTVDP					; altero o valor do registro 1

			ret							; sai da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  organiza a tabela de nomes do 3º terço para simular linearidade
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
MAKEGRND:	ld hl,6144+16*32

			ld a,128
			call MAKEGRND0				; primeira linha

			ld a,129
			call MAKEGRND0				; segunda linha

			ld a,130
			call MAKEGRND0				; terceira linha

			ld a,131
			call MAKEGRND0				; quarta linha

			ret							; fim da rotina

MAKEGRND0:	ld c,a						; guaro o caracter inicial em C

			xor a						; zero A

MAKEGRND1:	ld b,a						; salvo A em B

			ld a,c						; recupero A em C

			call WRTVRM					; escrevo na VRAM

			add a,4						; para 4 caracteres depois
			inc hl						; para o próximo caracter

			ld c,a						; salvo A

			ld a,b						; jogo o valor de B em A
			inc a						; incremento A
			cp 32						; é 32?
			jr nz,MAKEGRND1				; senão volto para MAKEGRND1
			ret

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  prepara e desenha o fundo com as estrelas
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
MAKESTAR:	ld a,MAXSTAR			; número de estrelas no céu
			ld de,STARDATA			; posição das estrelas

MAKESTAR0:	push af					; empilho AF
			push de					; empilho DE

			call RANDOM16			; sorteio um número aleatório de 16-bit
			ld a,h					; corta uma parte
			and 0x0f				; (HL and 0x0FFF)
			ld h,a					; e volta para HL

			call RANDOM8			; sorteio um número aleatório de 8-bit
			and 7					; fico com valores de 0 até 7

			sla a					; x2
			sla a					; x2
			sla a					; x2 = x8

			ld b,199				; a segunda parte do opcode
			add a,b
			ld (MAKESTAR1+1),a		; U A U !

			xor a					; zero A

MAKESTAR1:	set 0,a					; isto aqui vai mudar :-) 0xcb 0x??

			call WRTVRM				; desenha uma estrela na tela

			pop de					; recupero DE
			pop af					; recupero AF

			ld (MAKESTAR2+1),de		; U A U 2 !

MAKESTAR2:	ld (STARDATA),hl

			inc de
			inc de					; faço DE andar duas casas

			dec a
			cp 0
			jr nz, MAKESTAR0

			ret						; fim da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  sorteia o novo padrão do chão
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
NEWGROUND:	call RANDOM8				; sorteio um número

			and 3						; só quero valores entre 0 e 3

			add a,a						; multiplico por 2 uma vez
			add a,a						; e depois outra vez (faço x4)

			ld e,0						; pronto, multipliquei por 1024!
			ld d,a						; 0x0400, 0x800, 0xC00 e 0x1000

			ld hl,GROUND0				; endereço inicial

			adc hl,de					; somo tudo

			ld bc,1024
			ld de,BUFFER1
			ldir						; copio o padrão para BUFFER1

			ld a,0

			ret							; fim da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  prepara a tela
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
PREPSCR:	ld bc,960					; 30 sprites
			ld de,14336					; início da tabela de sprites
			ld hl,SPRITES				; os padrões dos sprites
			call LDIRVM

			ld hl,8192					; prepara o céu
			call PREPSKY				; primeiro terço da tela
			call PREPSKY				; segundo terço da tela

			call MAKESTAR				; gera o padrão de estrelas

			ld bc,768					; tamanho da fonte, 768 bytes
			ld de,4096+256				; posição (a partir de " ")
			ld hl,SYSFONT1				; dados da fonte de caracteres
			call LDIRVM					; caracteres do 3º terço da tela

			ld bc,768
			ld a,0x71					; COLOR 7,1
			ld hl,8192+4096+256			; cores do 3º terço da tela
			call FILVRM

			ld bc,1024
			ld a,0xa1					; COLOR 10,1
			ld hl,8192+4096+1024		; os caracteres do solo
			call FILVRM

			call MAKEGRND				; produzo o solo

			ld hl,6144+20*32
			ld a,0
PREPCR1:	call WRTVRM
			inc hl
			inc a
			cp 128
			jr nz,PREPCR1

			ret							; fim da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  prepara o céu
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
PREPSKY:	ld c,255					; número de blocos de repetições

PREPSKY0:	ld de,PREPSKY2				; o padrão da cor de cada estrela

			ld b,8						; quantas vezes repetirei
PREPSKY1:	ld a,(de)					; pego a cor da estrela
			call WRTVRM					; gravo na VRAM
			inc hl						; incremento HL
			inc de						; incremento DE
			djnz PREPSKY1				; enquanto B<>0, vou para PREPSKY1

			inc c						; incremento C, foi um bloco
			ld a,c						; coloco C e A
			cp 255						; é 255
			jr nz,PREPSKY0				; senão PREPSKY0

			ret							; fim da rotina

PREPSKY2:	db 0xe1, 0x41, 0x91, 0xa1, 0x71, 0xd1, 0x21, 0x61

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  gerador de números pseudo-aleatórios levemente adaptada do código ori-
;  *  ginal de Milos "baze" Bazelides <baze_at_baze_au_com> e disponível em:
;  *  http://baze.au.com/misc/z80bits.html (versão 8-bit)
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
RANDOM8:	ld a,0						; seed
			ld b,a
			ld a,(JIFFY)				; mas eu tenho outro SEED
			add a,a
			add a,a
			add a,b
			inc a
			ld (RANDOM8+1),a			; guardo o valor

			ret							; fim da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  gerador de números pseudo-aleatórios levemente adaptada do código ori-
;  *  ginal de Milos "baze" Bazelides <baze_at_baze_au_com> e disponível em:
;  *  http://baze.au.com/misc/z80bits.html (versão 16-bit)
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
RANDOM16:	ld	de,0					; seed de 16-bit
			ld	a,d
			ld	h,e
			ld	l,253
			or	a
			sbc	hl,de
			sbc	a,0
			sbc	hl,de
			ld	d,0
			sbc	a,d
			ld	e,a
			sbc	hl,de
			jr	nc,RANDOM160
			inc	hl
RANDOM160:	ld (RANDOM16+1),hl

			ret

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  rotaciona a tela
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;

ROTATE:		ld hl,BUFFER0
			ld de,BUFFER0+32
			ld bc,2048

ROTATE0:	push bc						; salvo BC

			ld a,(hl)					; leio o primeiro byte

			add a,a						; rotaciono XXXXXXX.
			add a,a						; rotaciono xxxxxx..

			ld b,a						; guardo o resultado

			ld a,(de)					; pego na próxima coluna
			and 0xC0					; faço AND com XX........

			rlc a						; e desloco os dois bits para
			rlc a						; o outro lado do byte

			or b						; junto os dois valores

			ld (hl),a					; atualizo o novo padrão

			inc de						; incremento DE
			inc hl						; incremento HL

			pop bc						; volto o BC original

			dec bc						; decremento BC

			xor a
			or b						; se tudo for zero, então zero
			or c						; será o resultado disto aqui

			cp 0						; é zero?
			jr nz,ROTATE0				; senão volte para ROTATE0

			ld a,(GROUNDRPT)
			inc a

			cp 127						; é zero?
			call z,NEWGROUND

			ld (GROUNDRPT),a			; "zero" o contador e armazeno

			ld bc,1024
			ld de,4096+1024
			ld hl,BUFFER0
			call LDIRVM					; conteúdo para a VRAM

			ret

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  movimenta as estrelas do céu
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
STARFIELD:	ld bc,STARDATA				; aponto para as estrelas

			ld a,0

STARFIELD0:	ld (STARFIELD1+1),bc		; código auto-modificável!
			ld (STARFIELD4+1),bc		; código auto-modificável!

			push af						; guardo AF

STARFIELD1:	ld hl,(STARDATA)
			call RDVRM					; leio a posição da estrela
			add a,a						; faço-a andar um ponto para esquerda

			cp 0						; passou de 128?
			jr nz,STARFIELD3			; senão vá para STARFIELD3

			ld a,0
			call WRTVRM					; apago a estrela

			ld de,8
			sbc hl,de					; desloco para a nova posição

			ld a,l
			and 0xf8
			cp 0						; estou na coluna 0?
			jr nz,STARFIELD2			; senão vá para STARFIELD2

			ld a,248					; de volta ao lado direito
			add a,l
			ld l,a

STARFIELD2:	ld a,1						; e claro, a estrela!

STARFIELD3:	call WRTVRM					; redesenha a estrela

STARFIELD4:	ld (STARDATA),hl			; salva o novo valor

			pop af						; recupero AF

			inc bc
			inc bc

			inc a						; incremento o contador

			cp MAXSTAR					; acabou?
			jr nz,STARFIELD0			; senão volto para STARFIELD0

			ret							; fim da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  Tela de boot do TI-99 4/A, esta rotina é só zoação!
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TI99BOOT:	call DISSCR					; desligo a exibição da tela

			call ERAFNK					; desliga as teclas de função

			ld a,1						; PRETO
			ld (FORCLR),a				; cor da frente em branco
			ld a,7						; CIANO
			ld (BAKCLR),a				; cor de fundo
			ld (BDRCLR),a				; cor da borda
			call CHGCLR					; agora mudo as cores da tela

			call INIT32					; entro na SCREEN1

			ld bc,512
			ld de,256
			ld hl,SYSFONT0				; copia a fonte 0 do TI na VRAM
			call LDIRVM

			ld bc,80
			ld de,768
			ld hl,SYSTILOGO				; copio o logo da TI e o (C)
			call LDIRVM

			ld bc,16
			ld de,8192+16
			ld hl,TI99BOOTA
			call LDIRVM					; copia o padrão de cores das barras

			ld de,6144
			call TI99CBAR				; desenha a primeira barra

			ld de,6144+32*18
			call TI99CBAR				; desenha a segunda barra

TI99BOOT0:	ld de,TI99BOOTB				; aponto a string a escrever

			ld a,(de)					; faço um "ld hl,(de)", um
			ld l,a						; opcode que não existe no
			inc de						; Z80...
			ld a,(de)
			ld h,a						; sim, tudo isto!

TI99BOOT1:	inc de
			ld a,(de)					; leio o caracter à escrever
			cp 0						; é 0
			jr z,TI99BOOT2				; é hora de uma nova linha
			cp 1						; é 1?
			jr z,TI99BOOT3				; então é o fim da rotina
			call WRTVRM					; escreve na VRAM
			inc hl						; incrementa HL
			jr TI99BOOT1				; faz o laço

TI99BOOT2:	inc de
			ld (TI99BOOT0+1),de			; atualizo o ponteiro de linha

			jr TI99BOOT0				; vou para a escrita na tela

TI99BOOT3:	call ENASCR					; religo a tela

			call BEEP					; emito um beep!

TI99BOOT4:	ld a,0
			call GTTRIG					; espaço foi pressionado?
			cp 0
			jr z,TI99BOOT4

			ret							; sai da rotina

TI99BOOTA:	db 0x66,0x22,0x11,0xbb,0xcc,0xdd,0xff,0x44
			db 0x22,0xdd,0x88,0xee,0x55,0x99,0xaa,0x66

TI99BOOTB:	dw 6144+5*32+15				; (15,5)
			db "`ab",0

			dw 6144+6*32+15				; (15,6)
			db "cde",0

			dw 6144+7*32+15				; (15,7)
			db "fgh",0

			dw 6144+9*32+8				; (8,9)
			db "TEXAS INSTRUMENTS",0

			dw 6144+11*32+10			; (10,11)
			db "HOME COMPUTER",0

			dw 6144+16*32+3				; (3,16)
			db "READY-PRESS SPACE TO BEGIN",0

			dw 6144+22*32+7				; (7,22)
			db "i2018  CRUNCHWORKS",0

			db 1						; <EOF>

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  As barras coloridas da tela de boot do TI-99 4/A
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TI99CBAR:	ld b,3						; número de repetições

TI99CBAR0:	push bc						; guardo BC
			push de						; guardo DE

			ld bc,32					; número de bytes a copiar
			ld hl,TI99CBAR1				; bytes na RAM
			call LDIRVM					; copio da RAM para a VRAM

			pop de						; recupero DE
			pop bc						; recupero BC

			ld a,32
			add a,e
			ld e,a						; e para a próxima linha

			djnz TI99CBAR0

			ret

TI99CBAR1:	db 0x80,0x84,0x88,0x8c,0x90,0x94,0x98,0x9c
			db 0xa0,0xa4,0xa8,0xac,0xb0,0xb4,0xb8,0xbc
			db 0xc0,0xc4,0xc8,0xcc,0xd0,0xd4,0xd8,0xdc
			db 0xe0,0xe4,0xe8,0xec,0xf0,0xf4,0xf8,0xfc

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  habilita o modo R800 ROM se eu estiver rodando em um turbo R, rotina de
;  *  Timo Nyyrikki -- http://www.msx.org/wiki/R800_Programming#BIOS_routines
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
TURBOMODE:  ld a,(0x002d)				; byte de ID do MSX
			cp 3						; é turbo R?
			ret nz						; se não for vai embora

			ld a,(0x0180)				; rotina CHGCPU
			cp 0C3h

			;ld a,0x82					; modo R800 DRAM
			ld a,0x81					; modo R800 ROM

			call z,0x0180

			ret							; sai da rotina

;
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  *
;  *  gera uma espera de 'B' ciclos do VDP (não se esqueça de zerar JIFFY) - OK
;  *
;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
WAITASEC:   ld a,(JIFFY)
			cp b
			ret nc
			jr WAITASEC

;  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

SYSFONT0:	INCBIN "TI-99_4A_SystemFont0.inc"

SYSFONT1:	INCBIN "TI-99_4A_SystemFont1.inc"

SYSTILOGO:	INCBIN "TI-99_4A_TextasInstrumentsLogo.inc"

SPRITES:	INCBIN "Parsec_Sprites.inc"

GROUND0:	INCBIN "Parsec_Ground_0.inc"

GROUND1:	INCBIN "Parsec_Ground_1.inc"

GROUND2:	INCBIN "Parsec_Ground_2.inc"

GROUND3:	INCBIN "Parsec_Ground_3.inc"

GROUNDRPT:	db 0						; Número de repetições

STARDATA:	rept MAXSTAR
			dw 0						; A posição de uma estrela
			endm

BUFFER0:	rept 1024
			db 0
			endm

BUFFER1:	rept 1024
			db 0
			endm

;
; MSX rulez a lot!
;
stop:
