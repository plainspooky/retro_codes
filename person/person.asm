;
;   montar com o PASMO -- http://pasmo.speccy.org/
;   $ pasmo -d - v person.asm person.com
;
BOOT:       equ $00
MSXDOS:     equ $0005
PUTSTR:     equ $09

ramArea:    equ $c000

            org $0100

            call initialize_giovanni    ; inicializa o objeto 'giovanni'
            call initialize_fulano      ; inicializa o objeto 'fulano'

            ld de,input1                ; minha entrada de dados
            call store_name_of_giovanni ; chama o método que armazena o
                                        ; atributo 'nome' de 'giovanni'

            ld de,input2                ; minha entrada de dados
            call store_name_of_fulano   ; armazena 'nome' de 'fulano'

            ld a,43                     ; entrada de dados
            ld (age_of_giovanni),a      ; atributo público, acesso direto

            call print_name_of_giovanni ; escreve o valor do atributo na tela
            call print_name_of_fulano

            ld c,BOOT
            call MSXDOS                 ; volta para o MSX-DOS

macro   ____Person, object, pointer
            proc
            local name_of_ ## object
            public age_of_ ## object

            name_of_ ## object : equ pointer
            age_of_ ## object : equ pointer+49

            initialize_ ## object
                ld de,age_of_ ## object
                ld hl,name_of_ ## object
                jp person_initialize

            print_name_of_ ## object
                ld de,name_of_ ## object
                jp person_print_string

            increase_age_of_ ## object
                ld hl,age_of_ ## object
                inc (hl)
                ret

            store_name_of_ ## object
                ld hl,name_of_ ## object
                jp person_store_value
            endp
        endm

person_initialize:                      ; método construtor da classe
            proc
            ld a,"$"
            ld (hl),a                   ; armazena "$" no começo da string
            inc hl
            xor a
            ld (hl),a                   ; e NULL no endereço seguinte
            ld (de),a                   ; aproveita e zera 'age'
            ret
            endp

person_store_value:                     ; método que armazena o atributo 'name'
            proc
            ld a,(de)                   ; DE aponta a string a ser copiada
            cp 0
            ret z                       ; sai da rotina se encontra NULL
            ld (hl),a
            inc de
            inc hl
            jr person_store_value
            endp

person_print_string:                    ; escreve o valor do atributo 'name'
            proc
            local new_line
            ld c,PUTSTR                 ; DE já aponta para a string a imprimir
            call MSXDOS
            ld de,new_line              ; aponta para CR+LF
            ld c,PUTSTR
            call MSXDOS
            ret
    new_line:
            db 13,10,"$"                ; CR+LF
            endp

        ____Person giovanni, ramArea    ; instancia a classe
        ____Person fulano, ramArea+50   ; instancia a classe

input1:
            db "Giovanni dos Reis Nunes$",0
input2:
            db "Fulano de Tal$",0

end
