;****************************************************************************
;*                           - Pic Projekt -                                *
;*                                                                          *
;*  PROJEKT ANS V.:  	Jonas Bull Nejman og Nikolaj Høgh            		*      
;*  NAVN:           	Hello world SIMPLE                               	*
;*  PROCESSOR:      	PIC16F819                                        	*
;*  CLOCK: 	    		Intern Osc - 31 kHz(Op til 8 MHZ m. intern osc.) 	*
;*  FILE:  	        	helloworld_PIC16F819_simple.asm                  	*
;*  WATCHDOGTIMER:  	no                                               	*
;*  REVISION:	    	24.03.2023                                      	*
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

LYSDIODE		EQU		3

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

		MOVLW	B'11111111'			;Hele PORT A er input RA0-RA7 
									;RA5 kan kun være input (Input fra knap)
		MOVWF	TRISA				;Sæt in-out bitmønstret til tris-reg. port A (file 85H)


		MOVLW	B'00000000'			;RB0-RB7 (Hele portB) er output
		MOVWF	TRISB				;Placer informationen i tris-reg. port B (file 86H)


		MOVLW	B'00000110'			;Fortæller at A0 (RA0) er DIGITAL input (se side 170 i bogen
									;"PIC in practice" - eller på side 82 i datablad for 16F818/819)
									; Se RIGISTER 11-2 i databladet
		MOVWF	ADCON1				;Informationen placeres i AD control register nr. 1

		MOVLW	B'01000000'			;Fortæller intern clock skal være 1 MHz (Op til 8 MHz)
									;(Se side 38 i datablad) ,  bit  IOFS=0 
		MOVWF	OSCCON				;OSCCON ligger på adressen 0x8F - altså i bank 1

		
		MOVLW	B'00000111'			;PreScaler er 1:256 -  Dvs. timerens tællehastighed er rimelig hurtig !!!
									; 
		MOVWF	OPTION_R			;Fortæl om prescaler-tallet til option registret

		BCF		STATUS,5			;Vi hopper tilbage til bank 0. 
									;(Vi er nemlig færdige med at snakke med de filer, som ligger i bank 1)
	
		CLRF	PORTA				;Nulstil portA
		CLRF 	PORTB				;Nulstil portB
	
		CALL	GODAW				;Hop til Godaw
		
		CALL	GODAW
		
		CALL	GODAW
		
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
				CALL 	COUNT2				
				RETURN


PAUSE			CALL 	COUNT1
				CALL	COUNT1
				CALL	COUNT1
				CALL	COUNT1
				CALL	COUNT1
				CALL	COUNT1		
				RETURN


PAUSE_5s
				MOVLW	d'48'
				MOVWF	TELLER
LOOP2			CLRF	TMR0
LOOP1			MOVFW	TMR0
				SUBLW	d'100'			
				BTFSS	STATUS,ZEROBIT
				GOTO	LOOP1
				DECFSZ	TELLER
				GOTO	LOOP2
				CLRF	TMR0
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
				
				



;*********************************************************************************************
;      
;		MAIN 
;
;*********************************************************************************************

MAIN	BSF		PORTB,0			;Her tænder jeg sgu for lysdioden, din klaphat
		BSF		PORTB,1
		CALL	PAUSE_5s		;Her holdes en lille pause, hvor der ikke sker en skid

		BCF		PORTB,0			;Her slukker jeg lysdioden igen, din klaphat
		BCF		PORTB,1
		CALL	PAUSE_5s		;Her holdes en lille pause, hvor der ikke sker en skid

		GOTO	MAIN			;Forever loop. Start forfra.

END
