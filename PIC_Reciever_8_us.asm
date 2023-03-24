;****************************************************************************
;*                           - Pic Projekt -                                *
;*                                                                          *
;*  PROJEKT ANSV.:  	Jonas Bull Nejmann                                *      
;*  NAVN:           	Radiokommunikation modtager.asm                     *
;*  PROCESSOR:      	PIC16F819                                        *
;*  CLOCK: 	    	Intern Osc - 1 MHz(Op til 8 MHZ m. intern osc.) *
;*  FILE:  	        	Radiokommunikation modtager                     *
;*  WATCHDOGTIMER:  	no                                               *
;*  REVISION:	    	24.01.2023                                      *
;*                                                                          *
;*                                                                          *
;****************************************************************************

;*  PIN CONFIGURATION TIL HARDWAREN:

;*  RA0 = Digital INPUT  
;*  RA1 = Digital INPUT 
;*  RA2 = Digital INPUT 
;*  RA3 = Digital INPUT 
;*  RA4 = Digital INPUT 
;*  RA5 = Digital INPUT  (OBS: RA5 kan kun være input - Vær opmærksom på dette!!!)
;*  RA6 = Digital INPUT 
;*  RA7 = Digital INPUT 

;*  RB0 = Digital Output 
;*  RB1 = Digital Output 
;*  RB2 = Digital Output
;*  RB3 = Digital Output
;*  RB4 = Digital Output 
;*  RB5 = Digital Output
;*  RB6 = Digital Output
;*  RB7 = Digital Output

  

;****************************************************************************
;*								    										*
;*								    										*
;*   		        			EQUATES SECTION		    					*
;*								    										*
;*								    										*
;****************************************************************************


W		EQU		0		; 'direction' flag (target - hvor skal resultatet placeres)
F		EQU		1		; 'direction' flag (target - hvor skal resultatet placeres)


TMR0	EQU 	0x0001	;dvs TMR0  (TIMERO) er filen på adressen 01
						;TIMER0 er en 8-bit timer med 8-bit prescaler
						;  (TIMER1 er 16 bit)

STATUS	EQU		0x0003	;dvs STATUS-reg er file 03 (indeholder bl.a. zerobit)
PORTA   EQU		0x0005	;dvs PORTA  er file 05
PORTB	EQU		0x0006	;dvs PORTB  er file 06

ZEROBIT	EQU   	2   	;Zerobit er bit nr. 2 (i status-registret)

ADCON0	EQU		0x001F	;A/D configurations register nr. 0  (ligger i bank 0) - Se datablad side 81
ADCON1	EQU		0x009F	;A/D configurations register nr. 1  (ligger i bank 1) - Se datablad side 82

ADRESH	EQU		0x001E	;De øverste 8 bit i AD-resultatet placeres i adresse 1E (De 8 mest betydende)
ADRESL	EQU		0x009E	;De nederste 2 bit i AD-resultatet placeres i adresse 9E (De 2 mindst betydende)

TRISA	EQU		0x0085	;Tristate Port A (in/out)
TRISB	EQU		0x0086	;Tristate Port B (in/out)

AN0		EQU		0		;Analog input AN0 er bit nr. 0 (på port A - dvs ben nr. 17)

RA5		EQU		5		;RA5 er bit nr. 5 (på port A - ben 4)

RB0		EQU		0		;RB0 er bit nr. 0 (på port B - ben 6)
RB1		EQU		1		;RB1 er bit nr. 1 (på port B - ben 7)
RB2		EQU		2		;RB2 er bit nr. 2 (på port B - ben 8)
RB3		EQU		3		;RB3 er bit nr. 3 (på port B - ben 9)
RB4		EQU		4		;RB4 er bit nr. 4 (på port B - ben 10)
RB5		EQU		5		;RB5 er bit nr. 5 (på port B - ben 11) 
RB6		EQU		6		;RB6 er bit nr. 6 (på port B - ben 12) 
RB7		EQU		7		;RB7 er bit nr. 7 (på port B - ben 13)


OPTION_R    EQU   	0x0081   	;OptionReg. er fil 81H - altså i bank 1 - (f.eks. prescaler bestemmes her)
CARRYBIT    EQU	  	0			;Carrybit er bit nr. 0 (i status-registret) 

OSCCON		EQU		0x008F		;Oscillator kontrol registret ligger på adressen 8F Hex - bank 1 (Se memorymap, databladet side 11) 

TELLER  	EQU		0x20		;Den første bruger-fil ligger på adresse 20 hex (f.eks. til en varibel)
USERFILE2	EQU		0x21		;Den anden bruger-fil ligger på adresse 21 hex (f.eks. til en varibel)
INPUT_BYTE	EQU		0x25
TMR0_COPY	EQU		0x26
BIT_TELLER	EQU		0x27
Kodeord		EQU		0x28
COUNT		EQU		0x29	



;****************************************************************************



		LIST	P=PIC16F819			;angiver PIC-type
		RADIX	hex					;Standard er hex
		ORG		0x0000				;Programmet starter her, 
									;org sætter origin til 0x0000

		GOTO	SETUP				;Gå til setup-delen, så porte defineres og alt bliver nulstillet og klart. Hurra!





;****************************************************************************
;*																			*
;*																			*
;* 	                	CONFIGURATION BITS  								*
;*																			*                       
;*																			*
;****************************************************************************


		__CONFIG 0x3F10				;INTRC-A6 er port I/O
									;WatchDogTimer OFF
									;Power Up Timer ON
									;MCLR er bundet til VDD - RA5 er digital I/O
									;Brown Out Detect OFF
									;Lov Voltage Program. Disabled
									;EE protect disabled
									;Flash Program Write Protection Disabled
									;CCP1 Mux på RB2 (ikke RB3)
									;Code Protection Disabled

;****************************************************************************
;*																			*
;*																			*
;*			             CONFIGURATION SECTION								*
;*																			*
;*																			*
;****************************************************************************



SETUP	BCF		STATUS,6			;Dvs ikke bank 2 eller 3 - hhv 'b'10 og 'b'11 for RP1,RP0

		BSF		STATUS,5			;Gå til Bank 1 (5. bit kaldes også RP0) 
									; - operationen kaldes også "Bank Select"

		MOVLW	B'11110111'			;Hele PORT A er input RA0-RA7 
									;RA5 kan kun være input (Input fra knap)
		MOVWF	TRISA				;Sæt in-out bitmønstret til tris-reg. port A (file 85H)


		MOVLW	B'00000000'			;RB0-RB7 (Hele portB) er output
		MOVWF	TRISB				;Placer informationen i tris-reg. port B (file 86H)


		MOVLW	B'00000110'			;Fortæller at A0 (RA0) er DIGITAL input (se side 170 i bogen
									;"PIC in practice" - eller på side 82 i datablad for 16F818/819)
									; Se RIGISTER 11-2 i databladet
		MOVWF	ADCON1			;Informationen placeres i AD control register nr. 1

		MOVLW	B'01000000'			;Fortæller intern clock skal være 1 MHz (Op til 8 MHz)
									;(Se side 38 i datablad) ,  bit  IOFS=0 
		MOVWF	OSCCON				;OSCCON ligger på adressen 0x8F - altså i bank 1

		
		MOVLW	B'00000001'			;PreScaler er 1:4 -  Dvs. timerens tællehastighed er rimelig hurtig !!!
									; (Bit 7 og 6 SKAL LIGE CHECKES m.h.p. INTERRUPT-KONTROL )
		MOVWF	OPTION_R			;Fortæl om prescaler-tallet til option registret

		BCF		STATUS,5			;Vi hopper tilbage til bank 0. 
									;(Vi er nemlig færdige med at snakke med de filer, som ligger i bank 1)
	
		CLRF	PORTA				;Nulstil portA
		CLRF 	PORTB				;Nulstil portB
	
		CALL	GODAW				;Hop til Godaw
		
		CALL	GODAW
		
		CALL	GODAW
		
		MOVLW	B'00111101'
		MOVWF	Kodeord;
		
		
		GOTO	MAIN				; Hop til main


; SLUT PÅ SETUP. 




COUNT3			NOP
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP
				RETURN				


COUNT2			CALL	COUNT3    		
				CALL	COUNT3
				CALL	COUNT3
				CALL	COUNT3
				RETURN


COUNT1			CALL 	COUNT2
				CALL 	COUNT2
				CALL 	COUNT2
				CALL 	COUNT2
				RETURN


PAUSE			CALL 	COUNT1		
				CALL 	COUNT1
				CALL 	COUNT1
				CALL	COUNT1
				CALL 	COUNT1
				CALL 	COUNT1
				CALL	COUNT1
				RETURN

GODAW			MOVLW	b'11111111'  ; Godaw får alle 8 LED til at blinke EN gang
				MOVWF	PORTB
				CALL	PAUSE
				CALL	PAUSE
				CLRF 	PORTB
				CALL	PAUSE
				CALL	PAUSE
				CALL	PAUSE
				RETURN 

PAUSE_500MS		
				CLRF	TMR0
LOOP1			MOVFW	TMR0
				SUBLW	d'141'			
				BTFSS	STATUS,ZEROBIT
				GOTO	LOOP1
				CLRF	TMR0
LOOP2			MOVFW	TMR0
				SUBLW	d'141'			
				BTFSS	STATUS,ZEROBIT
				GOTO	LOOP2			
				RETURN






VENT_PAA_STARTBIT BTFSS PORTA,0 	; Vent her så længe input er lavt
				GOTO 	VENT_PAA_STARTBIT
				CLRF 	TMR0
LOOP5 			BTFSC 	PORTA,0 	; Vent her så længe input er højt
				GOTO 	LOOP5
				MOVFW 	TMR0 		; Gem indholdet af TMR0, da værdien
 									; skal testes flere gange i det
 									; kommende
				MOVWF 	TMR0_COPY 	; TMR0 er nu kopieret
				BTFSS 	TMR0_COPY,7 ; Test om MSB er sat. Det er den,
									; hvis der er modtaget en startbit
				GOTO 	VENT_PAA_STARTBIT
				BTFSC 	TMR0_COPY,5
				GOTO 	VENT_PAA_STARTBIT
				BTFSS 	TMR0_COPY,4
				GOTO 	VENT_PAA_STARTBIT

				RETURN 				; Returnér, når der er modtaget en
 									; puls, hvor TMR0 >= 128			

MODTAG_EN_BYTE 	MOVLW 	b'00001000' ; Flyt tallet 8 til W
				MOVWF 	BIT_TELLER	; Læg tallet i bit-teller
									; (bit-teller filen skal holde styr på,
									; hvor mange bits, der er modtaget,
									; idet den når ned til 0, når der
									; er modtaget 8 bits).
									; Bit-teller decrementeres i rutinerne
									; GEM_1 og GEM_0 (når der er
									; accepteret og modtaget en
									; gyldig bit.
				BCF 	STATUS,CARRYBIT ; Carrybitten cleares
LOOP_8_GANGE 	CALL 	MODTAG_EN_BIT ; Modtag en bit
				MOVF 	BIT_TELLER 	; Hvis 8 bit modtaget bliver bit-
									; teller nu 0.
									; MOVF-kommandoen flytter ikke
									; noget her, men skal bare påvirke
									; flag (i dette tilfælde zero-bit)
 				BTFSS 	STATUS,ZEROBIT
 				GOTO 	LOOP_8_GANGE
 				RETURN			 	; Returnér


MODTAG_EN_BIT 	BTFSS 	PORTA,0 	; Vent til input går høj
				GOTO 	MODTAG_EN_BIT
				CLRF 	TMR0 		; Nulstil timeren
LOOP_HOJ 		BTFSC 	PORTA,0 	; Vent til input går lav igen
				GOTO	LOOP_HOJ
				MOVFW 	TMR0 		; Aflæs timer
				MOVWF 	TMR0_COPY 	; Gem indholdet af timer
				BTFSC 	TMR0_COPY,5 ; Test om bit 5 var sat
 									; Bit 5 vil være et ”1-tal”, hvis der
 									; er tale om en ”0-bit” eller
 									; en ”1-bit” – ellers returneres!
				CALL 	HVILKEN_BIT ; Hvis ja: 0 eller 1 ??
				RETURN 				; Returnér

HVILKEN_BIT 	BTFSS 	TMR0_COPY,6 ; Test om bit 6 er clear
 				CALL 	TEST_0 		; test om det er et 0
 				BTFSS 	TMR0_COPY,4 ; Test om bit 4 er clear
 				CALL 	TEST_1 		; Test om det er et 1
 				RETURN 				; Returnér


TEST_0 			BTFSS 	TMR0_COPY,6 ;Test om det er et 0
 				CALL 	GEM_0
				RETURN

TEST_1 			BTFSS 	TMR0_COPY,4 ;Test om det er et 1
 				CALL 	GEM_1
 				RETURN



GEM_0 			RLF 	INPUT_BYTE 	; Roter input-filen, så den er klar
 				BCF 	INPUT_BYTE,0 ; Gem et ”0” i bit nr. 0
 				DECF 	BIT_TELLER 	; Tæl bit-tælleren én ned
 									; (Bit-tæller holder styr på, om der
 									; er modtaget 8 bit = en hel byte)
 				RETURN ; Returnér


GEM_1 			RLF 	INPUT_BYTE 	; Roter input-filen, så den er klar
 				BSF 	INPUT_BYTE,0 ; Gem et ”1” i bit nr. 0
 				DECF 	BIT_TELLER 	; Tæl bit-tælleren én ned
 									; (Bit-tæller holder styr på, om der
 									; er modtaget 8 bit = en hel byte)
 				RETURN 				; Returnér
	


PAUSE_800_US	CLRF	TMR0 			; Timer0 nulstilles
LOOP6			MOVFW	TMR0 			; Flyt indholdet af TMR0 til W-registret
				SUBLW	d'47'
				BTFSS	STATUS,ZEROBIT 	; Tjek om det gav nul. Hvis ja: hop ud af lÃ¸kken
				GOTO	LOOP6			; Hvis nej: bliv i lÃ¸kken (gÃ¥ til LOOP1-label)
				RETURN 					; Forlad subrutinen
				



PAUSE_2s 		BCF 	STATUS,6
				BSF 	STATUS,5
				MOVLW 	B'00000111' ;Prescaler is /256
				MOVWF 	OPTION_R 	;TIMER is 1/32 secs.
				BCF 	STATUS,5 		;Return to Bank0.
				CLRF	COUNT		
				MOVLW 	d'8' 		;put 120 in W
				MOVWF 	COUNT 		;load COUNT with 120
LOOP7			CALL 	DELAY_51_ms	;Wait 0.25 seconds
				CALL 	DELAY_51_ms	;
				CALL 	DELAY_51_ms	;
				CALL 	DELAY_51_ms	;
				CALL 	DELAY_51_ms	;
				DECFSZ 	COUNT 		;Subtract 1 from COUNT
				GOTO 	LOOP7 		;Count is not zero.
				BSF 	STATUS,5
				MOVLW 	B'00000001' ;Prescaler is /256
				MOVWF 	OPTION_R 	;TIMER is 1/32 secs.
				BCF 	STATUS,5
				RETURN


DELAY_51_ms		CLRF 	TMR0 		;START TMR0.
LOOP8			MOVFW	TMR0 			; Flyt indholdet af TMR0 til W-registret
				SUBLW	d'47'
				BTFSS	STATUS,ZEROBIT 	; Tjek om det gav nul. Hvis ja: hop ud af lÃ¸kken
				GOTO	LOOP8			; Hvis nej: bliv i lÃ¸kken (gÃ¥ til LOOP1-label)
				Return







;*********************************************************************************************
;      
;		MAIN 
;
;*********************************************************************************************


MAIN 	CLRF 	PORTB 			; Sluk alle 8 LED på port B
		CALL 	VENT_PAA_STARTBIT ; Loop her indtil der modtages en puls på 2,4 ms
		CALL 	MODTAG_EN_BYTE 	; Modtag de 8 bit
		MOVFW 	INPUT_BYTE 		; Flyt de 8 bit fra INPUT_BYTE registret
		MOVWF 	PORTB 			; og ud på port B
		MOVFW	Kodeord			;
		SUBWF 	INPUT_BYTE,W 	; Input - Kodeord
		BTFSS 	STATUS,ZEROBIT 	; Check om der er match 
		GOTO 	MAIN
		BSF		PORTA,3			;aktiver relæ
		CALL 	PAUSE_2s
		BCF		PORTA,3
		
 		GOTO 	MAIN 			; Gentag
END
