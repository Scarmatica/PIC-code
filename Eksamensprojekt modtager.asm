;****************************************************************************
;*                           - Pic Projekt -                                *
;*                                                                          *
;*  PROJEKT ANSV.:  	Jonas Bull Nejmann og Nikolaj Erhardsen H�gh        *      
;*  NAVN:           	Radiokommunikation modtager.asm                     *
;*  PROCESSOR:      	PIC16F819                                           *
;*  CLOCK: 	    	Intern Osc - 1 MHz(Op til 8 MHZ m. intern osc.)         *
;*  FILE:  	        	Radiokommunikation modtager                  	    *
;*  WATCHDOGTIMER:  	no                                            	    *
;*  REVISION:	    	24.04.2023                                    		*
;*                                                                          *
;*                                                                          *
;****************************************************************************

;*  PIN CONFIGURATION TIL HARDWAREN:

;*  RA0 = Digital INPUT  
;*  RA1 = Digital INPUT 
;*  RA2 = Digital INPUT 
;*  RA3 = Digital INPUT 
;*  RA4 = Digital Output
;*  RA5 = Digital INPUT  (OBS: RA5 kan kun v�re input - V�r opm�rksom p� dette!!!)
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


TMR0	EQU 	0x0001	;dvs TMR0  (TIMERO) er filen p� adressen 01
						;TIMER0 er en 8-bit timer med 8-bit prescaler
						;  (TIMER1 er 16 bit)

STATUS	EQU		0x0003	;dvs STATUS-reg er file 03 (indeholder bl.a. zerobit)
PORTA   EQU		0x0005	;dvs PORTA  er file 05
PORTB	EQU		0x0006	;dvs PORTB  er file 06

ZEROBIT	EQU   	2   	;Zerobit er bit nr. 2 (i status-registret)

ADCON0	EQU		0x001F	;A/D configurations register nr. 0  (ligger i bank 0) - Se datablad side 81
ADCON1	EQU		0x009F	;A/D configurations register nr. 1  (ligger i bank 1) - Se datablad side 82

ADRESH	EQU		0x001E	;De �verste 8 bit i AD-resultatet placeres i adresse 1E (De 8 mest betydende)
ADRESL	EQU		0x009E	;De nederste 2 bit i AD-resultatet placeres i adresse 9E (De 2 mindst betydende)

TRISA	EQU		0x0085	;Tristate Port A (in/out)
TRISB	EQU		0x0086	;Tristate Port B (in/out)

AN0		EQU		0		;Analog input AN0 er bit nr. 0 (p� port A - dvs ben nr. 17)

RA5		EQU		5		;RA5 er bit nr. 5 (p� port A - ben 4)

RB0		EQU		0		;RB0 er bit nr. 0 (p� port B - ben 6)
RB1		EQU		1		;RB1 er bit nr. 1 (p� port B - ben 7)
RB2		EQU		2		;RB2 er bit nr. 2 (p� port B - ben 8)
RB3		EQU		3		;RB3 er bit nr. 3 (p� port B - ben 9)
RB4		EQU		4		;RB4 er bit nr. 4 (p� port B - ben 10)
RB5		EQU		5		;RB5 er bit nr. 5 (p� port B - ben 11) 
RB6		EQU		6		;RB6 er bit nr. 6 (p� port B - ben 12) 
RB7		EQU		7		;RB7 er bit nr. 7 (p� port B - ben 13)


OPTION_R    EQU   	0x0081   	;OptionReg. er fil 81H - alts� i bank 1 - (f.eks. prescaler bestemmes her)
CARRYBIT    EQU	  	0			;Carrybit er bit nr. 0 (i status-registret) 

OSCCON		EQU		0x008F		;Oscillator kontrol registret ligger p� adressen 8F Hex - bank 1 (Se memorymap, databladet side 11) 

TELLER  	EQU		0x20		;Den f�rste bruger-fil ligger p� adresse 20 hex (f.eks. til en varibel)
USERFILE2	EQU		0x21		;Den anden bruger-fil ligger p� adresse 21 hex (f.eks. til en varibel)
INPUT_BYTE	EQU		0x25
TMR0_COPY	EQU		0x26
BIT_TELLER	EQU		0x27
OUTPUT_FIL	EQU		0x28


;****************************************************************************



		LIST	P=PIC16F819			;angiver PIC-type
		RADIX	hex					;Standard er hex
		ORG		0x0000				;Programmet starter her, 
									;org s�tter origin til 0x0000

		GOTO	SETUP				;G� til setup-delen, s� porte defineres og alt bliver nulstillet og klart. Hurra!





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
									;CCP1 Mux p� RB2 (ikke RB3)
									;Code Protection Disabled

;****************************************************************************
;*																			*
;*																			*
;*			             CONFIGURATION SECTION								*
;*																			*
;*																			*
;****************************************************************************



SETUP	BCF		STATUS,6			;Dvs ikke bank 2 eller 3 - hhv 'b'10 og 'b'11 for RP1,RP0

		BSF		STATUS,5			;G� til Bank 1 (5. bit kaldes ogs� RP0) 
									; - operationen kaldes ogs� "Bank Select"

		MOVLW	B'11101111'			;Hele PORT A er input RA0-RA7 udover RA4, der er output 
									;RA5 kan kun v�re input (Input fra knap)
		MOVWF	TRISA				;S�t in-out bitm�nstret til tris-reg. port A (file 85H)


		MOVLW	B'00000000'			;RB0-RB7 (Hele portB) er output
		MOVWF	TRISB				;Placer informationen i tris-reg. port B (file 86H)


		MOVLW	B'00000110'			;Fort�ller at A0 (RA0) er DIGITAL input (se side 170 i bogen
									;"PIC in practice" - eller p� side 82 i datablad for 16F818/819)
									; Se RIGISTER 11-2 i databladet
		MOVWF	ADCON1			;Informationen placeres i AD control register nr. 1

		MOVLW	B'01000000'			;Fort�ller intern clock skal v�re 1 MHz (Op til 8 MHz)
									;(Se side 38 i datablad) ,  bit  IOFS=0 
		MOVWF	OSCCON				;OSCCON ligger p� adressen 0x8F - alts� i bank 1

		
		MOVLW	B'00000001'			;PreScaler er 1:4 -  Dvs. timerens t�llehastighed er rimelig hurtig !!!
									; (Bit 7 og 6 SKAL LIGE CHECKES m.h.p. INTERRUPT-KONTROL )
		MOVWF	OPTION_R			;Fort�l om prescaler-tallet til option registret

		BCF		STATUS,5			;Vi hopper tilbage til bank 0. 
									;(Vi er nemlig f�rdige med at snakke med de filer, som ligger i bank 1)
	
		CLRF	PORTA				;Nulstil portA
		CLRF 	PORTB				;Nulstil portB
	
		CALL	GODAW				;Hop til Godaw
		
		CALL	GODAW
		
		CALL	GODAW
		
		GOTO	MAIN				; Hop til main


; SLUT P� SETUP. 




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

GODAW			MOVLW	b'11111111'  ; Godaw f�r alle 8 LED til at blinke EN gang
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






VENT_PAA_STARTBIT BTFSS PORTA,5 	; Vent her s� l�nge input er lavt
				GOTO 	VENT_PAA_STARTBIT
				CLRF 	TMR0
LOOP5 			BTFSC 	PORTA,5 	; Vent her s� l�nge input er h�jt
				GOTO 	LOOP5
				MOVFW 	TMR0 		; Gem indholdet af TMR0, da v�rdien
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

				RETURN 				; Return�r, n�r der er modtaget en
 									; puls, hvor TMR0 >= 128			

MODTAG_EN_BYTE 	MOVLW 	b'00001000' ; Flyt tallet 8 til W
				MOVWF 	BIT_TELLER	; L�g tallet i bit-teller
									; (bit-teller filen skal holde styr p�,
									; hvor mange bits, der er modtaget,
									; idet den n�r ned til 0, n�r der
									; er modtaget 8 bits).
									; Bit-teller decrementeres i rutinerne
									; GEM_1 og GEM_0 (n�r der er
									; accepteret og modtaget en
									; gyldig bit.
				BCF 	STATUS,CARRYBIT ; Carrybitten cleares
LOOP_8_GANGE 	CALL 	MODTAG_EN_BIT ; Modtag en bit
				MOVF 	BIT_TELLER 	; Hvis 8 bit modtaget bliver bit-
									; teller nu 0.
									; MOVF-kommandoen flytter ikke
									; noget her, men skal bare p�virke
									; flag (i dette tilf�lde zero-bit)
 				BTFSS 	STATUS,ZEROBIT
 				GOTO 	LOOP_8_GANGE
 				RETURN			 	; Return�r


MODTAG_EN_BIT 	BTFSS 	PORTA,5 	; Vent til input g�r h�j
				GOTO 	MODTAG_EN_BIT
				CLRF 	TMR0 		; Nulstil timeren
LOOP_HOJ 		BTFSC 	PORTA,5 	; Vent til input g�r lav igen
				GOTO	LOOP_HOJ
				MOVFW 	TMR0 		; Afl�s timer
				MOVWF 	TMR0_COPY 	; Gem indholdet af timer
				BTFSC 	TMR0_COPY,5 ; Test om bit 5 var sat
 									; Bit 5 vil v�re et �1-tal�, hvis der
 									; er tale om en �0-bit� eller
 									; en �1-bit� � ellers returneres!
				CALL 	HVILKEN_BIT ; Hvis ja: 0 eller 1 ??
				RETURN 				; Return�r

HVILKEN_BIT 	BTFSS 	TMR0_COPY,6 ; Test om bit 6 er clear
 				CALL 	TEST_0 		; test om det er et 0
 				BTFSS 	TMR0_COPY,4 ; Test om bit 4 er clear
 				CALL 	TEST_1 		; Test om det er et 1
 				RETURN 				; Return�r


TEST_0 			BTFSS 	TMR0_COPY,6 ;Test om det er et 0
 				CALL 	GEM_0
				RETURN

TEST_1 			BTFSS 	TMR0_COPY,4 ;Test om det er et 1
 				CALL 	GEM_1
 				RETURN



GEM_0 			RLF 	INPUT_BYTE 	; Roter input-filen, s� den er klar
 				BCF 	INPUT_BYTE,0 ; Gem et �0� i bit nr. 0
 				DECF 	BIT_TELLER 	; T�l bit-t�lleren �n ned
 									; (Bit-t�ller holder styr p�, om der
 									; er modtaget 8 bit = en hel byte)
 				RETURN ; Return�r


GEM_1 			RLF 	INPUT_BYTE 	; Roter input-filen, s� den er klar
 				BSF 	INPUT_BYTE,0 ; Gem et �1� i bit nr. 0
 				DECF 	BIT_TELLER 	; T�l bit-t�lleren �n ned
 									; (Bit-t�ller holder styr p�, om der
 									; er modtaget 8 bit = en hel byte)
 				RETURN 				; Return�r
	




;*********************************************************************************************
;      
;		MAIN 
;
;*********************************************************************************************


MAIN	CALL 	VENT_PAA_STARTBIT 	; Loop her indtil der modtages en puls p� 2,4 ms
		CALL 	MODTAG_EN_BYTE 		; Modtag de 8 bit
		MOVFW 	INPUT_BYTE 			; Flyt de 8 bit fra INPUT_BYTE registret til W registret
 		SUBLW	b'10010110'			; Den byte, der skulle sendes tr�kkes fra W registret
		BTFSS	STATUS,ZEROBIT		; Der tjekkes for ZEROBIT
		GOTO	MAIN
		COMF	OUTPUT_FIL			; OUTPUT_FIL komplementeres, s� outputtet skifter hver gang den mtodtager et nyt signal.
		BTFSS	OUTPUT_FIL,0		; Der testes om OUTPUT_FIL's 0. bit er h�j
		BCF		PORTA,4				; Hvis den 0. bit er lav, s� skal PORTA's 4. bit g�res lav
		BTFSC	OUTPUT_FIL,0		; Der testes om OUTPUT_FIL's 0. bit er lav
		BSF		PORTA,4				; Hvis den 0. bit er h�j, s� skal PORTA's 4. bit g�res h�j
		CALL	PAUSE_500MS
		GOTO 	MAIN 				; Gentag
END
