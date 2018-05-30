;.TITLE	'STOPER'
;Authors: Przemys³aw Fyk, Gennadii Genin, Damian G³os
;============================

STOS	EQU	60H		;wartoœæ wskaŸnika stosu w RAMie

SEG_ON	EQU	P1.6		;linia wygaszania wyœwietlacza

;Pamiêæ wyœwietlacza
DISPLAY	EQU	30H
LEDS	EQU	DISPLAY+6
DOTS	EQU	LEDS+1
NEXT	EQU	DOTS+1



;Timer 0 przegl¹danie wskaŸników
;uaktywniany co ok. 1ms - ni¿szy priorytet
;1ms =~30 * 32 cykli
;Mod 0 - starszy bajt liczy do 30
 
;Timer 1 odliczanie czasu 10 ms
;10ms = 36*256 cykli
;Mod 1 - przestawiam tylko starszy bajt

TMOD_SET	EQU	00010000B
TH0_SET		EQU	256-30
TH1_SET		EQU	256-36
IE_SET		EQU	10001010B	;przerwania T0 i T1
IP_SET		EQU	00001000B	;wy¿szy priorytet T1
TCON_SET	EQU	00010000B	;start timer T0
;(setb TR1 - start Timer 1)

BANK0	MACRO
	CLR	RS0
	MACEND

BANK1	MACRO
	SETB	RS0
	MACEND



	LJMP	START

	ORG	0BH
;przerwanie Timer 0
	PUSH	ACC
	PUSH	PSW
	BANK1
	MOV	TH0,#TH0_SET
	AJMP	CONT_INTT0

	ORG	1BH
;przerwanie Timer 1
	PUSH	ACC
	PUSH	PSW
	
	MOV	TH1,#TH1_SET

	INC	DISPLAY
	MOV	A,#10
	CJNE	A,DISPLAY,INTT1_END
	MOV	DISPLAY,#0

	INC	DISPLAY+1
	MOV	A,#10
	CJNE	A,DISPLAY+1,INTT1_END
	MOV	DISPLAY+1,#0

	INC	DISPLAY+2
	MOV	A,#10
	CJNE	A,DISPLAY+2,INTT1_END
	MOV	DISPLAY+2,#0

	INC	DISPLAY+3
	MOV	A,#6
	CJNE	A,DISPLAY+3,INTT1_END
	MOV	DISPLAY+3,#0

	INC	DISPLAY+4
	MOV	A,#10
	CJNE	A,DISPLAY+4,INTT1_END
	MOV	DISPLAY+4,#0

	INC	DISPLAY+5
	MOV	A,#6
	CJNE	A,DISPLAY+5,INTT1_END
	MOV	DISPLAY+5,#0

INTT1_END:
	POP	PSW
	POP	ACC
	RETI



CONT_INTT0:
	MOV	R0,#CSDB	;R0 - adres bufora wyswietlaczy

	SETB	SEG_ON
	MOV	A,@R1
	CJNE	R1,#LEDS,D7SEG

;wyœwietlenie Ledów
	SJMP	DISP_SET	
D7SEG:
	ACALL	CODE7_GET

;dodanie kropki
	PUSH	ACC
	CLR	C
	MOV	A,R2
	ANL	A,DOTS
	JZ	DOT_NO
	SETB	C
DOT_NO:
	POP	ACC
	MOV	ACC.7,C

DISP_SET:
	MOVX	@R0,A

	MOV	A,R2		;kolejny wskaŸnik
	MOV	R0,#CSDS	;R0 - adres wyboru wskaŸnika
	MOVX	@R0,A

	CLR	SEG_ON

	RL	A
	MOV	R2,A
	INC	R1
	CJNE	R1,#DOTS,NEXT_SEG

;ustaw segment 0
	MOV	R2,#1
	MOV	R1,#DISPLAY	;wskaŸnik na pamiêæ wyœwietlacza

NEXT_SEG:
	POP	PSW
	POP	ACC
	RETI



	ORG	100H
START:
	MOV	SP,#STOS	;wskaŸnik stosu

	ACALL	STOPPER_CLEAR

	MOV	TMOD,#TMOD_SET
	MOV	TH0,#TH0_SET
	MOV	TH1,#TH1_SET
	MOV	TL1,#0
	MOV	IE,#IE_SET
	MOV	IP,#IP_SET
	MOV	TCON,#TCON_SET


	BANK1
	MOV	R2,#1		;wybór wskaŸnika - 0 (kod 1 z 7)
	MOV	R1,#DISPLAY	;wskaŸnik na pamiêæ wyœwietlacza
	BANK0

LOOP:
	LCALL	LCD_CLR
	MOV	DPTR,#TEXT1
	LCALL	WRITE_TEXT

	LCALL	WAIT_ENTER_NW
;start timer
	SETB	TR1
	MOV	LEDS,#10H

	LCALL	LCD_CLR
	MOV	DPTR,#TEXT2
	LCALL	WRITE_TEXT

	LCALL	WAIT_ENTER_NW

;stop timer
	CLR	TR1
	MOV	LEDS,#20H

	AJMP	LOOP	


CODE7_GET:
	INC	A
	MOVC	A,@A+PC
	RET

	DB	03FH	;0
	DB	006H	;1
	DB	05BH	;2
	DB	04FH	;3
	DB	066H	;4
	DB	06DH	;5
	DB	07DH	;6
	DB	007H	;7
	DB	07FH	;8
	DB	06FH	;9
	DB	077H	;A
	DB	07CH	;b
	DB	039H	;C
	DB	05EH	;d
	DB	079H	;E
	DB	071H	;F


STOPPER_CLEAR:
	CLR	A
	MOV	DISPLAY,A
	MOV	DISPLAY+1,A
	MOV	DISPLAY+2,A
	MOV	DISPLAY+3,A
	MOV	DISPLAY+4,A
	MOV	DISPLAY+5,A
	MOV	LEDS,#20H
	MOV	DOTS,#00010100B
	RET


TEXT1:
	DB	'ENTER -> START  '
	DB	'RESET RAM->CLR ',0
TEXT2:
	DB	'ENTER -> STOP',0
