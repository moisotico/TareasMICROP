;#################################################################
;
;
;               Tarea 4
;               Eduardo Alfaro Gonzalez
;               B50203
;               Lectura teclado matricial
;               Ultima vez modificado 15/10/19
;
;
;#################################################################
#include registers.inc



;#################################################################
;               Definicion de estructuras de datos


CR:             equ $0D
LF:             equ $0A
FIN:            equ $0

                org $1000
MAX_TCL:        db 5
TECLA:          ds 1
TECLA_IN:       ds 1
CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
BANDERAS:       ds 1
puertoA:        ds 1


NUM_ARRAY:      ds 6
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E


                org $1200
MESS1:          fcc "Numero: %i"
                db CR,LF,CR,LF,FIN
                
                
                org $3E70
                dw INIT_ISR
                org $3E4C
                dw PTH0_ISR

;################################################
;       Programa principal
                org $2000

;################################################
;       Definicion de hardware

                bset PIEH, $01          ;habilitar interrupciones PH0
                bset PIFH, $01
                movb #$49, RTICTL       ;FIXME, esto lo pone en 9.26 ms
                bset CRGINT, $80        ;habilitar interrupciones rti
                movb #$F0, DDRA
                bset PUCR, $01          ;Super importante habilitar resistencia de pullup
;                bclr RDRIV, $01
                cli



;################################################
;       Programa

                lds #$3BFF
                movb #$FF, TECLA
                movb #$FF, TECLA_IN
                movb #$00, CONT_REB
                bclr BANDERAS,$07      ;Poner las banderas en 0
                ldaa MAX_TCL
                ldx #NUM_ARRAY
LoopCLR:        movb #$FF,A,X          ;iniciar el arreglo en FF
                dbne A,LoopCLR
mainL:          brset BANDERAS,$04,mainL
                jsr TAREA_TECLADO
                bra mainL
;################################################
;       Subrutinas
;################################################
;       Subrutinas Generales


;       Subrutina Tarea Teclado
TAREA_TECLADO:  loc
                tst CONT_REB
                bne return`
                jsr MUX_TECLADO
                ldaa TECLA
                cmpa #$FF
                beq checkLista`
                brset BANDERAS,$02,checkLeida`        ;revision de bandera Tecla leida
                movb TECLA,TECLA_IN
                bset BANDERAS,$02
                movb #$A,CONT_REB                       ;iniciar contador de rebotes
                bra return`
checkLeida`     cmpa TECLA_IN                           ;Comparar Tecla con tecla_in
                bne Diferente`
                bset BANDERAS,$01
                bra return`
Diferente`      movb #$FF,TECLA
                movb #$FF,TECLA_IN
                bra return`
checkLista`     brclr BANDERAS,$01,return`
                bclr BANDERAS,$03
                jsr FORMAR_ARRAY
return`         rts

;       Subrutina MUX_TECLADO
MUX_TECLADO:    loc
                ldab #0
                movb #0,PATRON
                ldx #TECLAS
mainloop`       tst PATRON
                bne p1
                movb #$EF,PORTA
                bra READ
p1:             ldaa #1
                cmpa PATRON
                bne p2
                movb #$DF,PORTA
                bra READ
p2:             inca                    ;A=2
                cmpa PATRON
                bne p3
                movb #$BF,PORTA
                bra READ
p3:             inca                    ;A=3
                cmpa PATRON             ;Se detecta cual patron se debe usar en la salida
                bne nk
                movb #$7F,PORTA
read:           brclr PORTA,$01, treturn`       ;se leen las entradas para encontrar la tecla presionada
                incb
                brclr PORTA,$02, treturn`
                incb
                brclr PORTA,$04, treturn`
                incb
                inc PATRON
                bra mainloop`
nk              movb #$FF,TECLA                 ;Se guarda la tecla o se retorna FF
                bra return`
treturn`        movb PORTA,puertoA
                movb B,X,TECLA
return`         rts
;       Subrutina formar array

FORMAR_ARRAY:   ldab TECLA_IN
                pshb
		ldaa #00
		psha
		ldd #MESS1
                ldx #$0
                jsr [Printf,X]
                leas 2,SP
                rts

;################################################
;       Subrutinas de proposito especifico


;        subrutina de PHO

                loc
PTH0_ISR:       bset PIFH, $01
                bclr BANDERAS, $04
;FIXMe
returnPH0:      rti

;       subrutina de rti
                loc
INIT_ISR:       bset CRGFLG, $80
                tst CONT_REB
                beq return`
                dec CONT_REB
return`         rti
