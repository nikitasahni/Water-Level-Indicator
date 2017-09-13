;**** Timer **** 
TSCR1 EQU $46
TSCR2 EQU $4D
TIOS  EQU $40
TCTL1 EQU $48
TCTL2 EQU $49
TFLG1 EQU $4E
TIE   EQU $4C
TSCNT EQU $44
TC4	  EQU $58
TC1	  EQU $52
;***************

;*** PORTS **** 
DDRA  EQU $02
PORTA EQU $00
PORTB EQU $01
DDRB  EQU $03
PORTM EQU $0250
DDRM  EQU $0252
;**************

;*** ADC Unit *** 
ATDCTL2	EQU $122
ATDCTL4 EQU $124
ATDCTL5 EQU $125
ADTSTAT0 EQU $126
ATD1DR1H EQU $132
ATD1DR1L EQU $133
;****************		
		
				ORG $1000
DutyCycle		DS 2
written			ds 1
		
				ORG $400
				LDS #$4000 
				
				jsr initLCD
				jsr Delay1MS
		
				LDAA #$00
				staa DDRB
				
				LDAA #$90			; Perform basic timer initialization to setup an output compare on PT4
				STAA TSCR1
				LDAA #$03
				STAA TSCR2 
				ldaa #$12
				staa TIOS							
				LDAA #$01
				STAA TCTL1
				
				ldaa #0
				staa written

Test		 	LDAA PORTB		; load the input to accumulator A
				
compare1		cmpa #$F0		; compare for Empty
				bgt compare2	; if not true branch to half
empty			ldaa written
				cmpa #0
				beq write
				bne TEST
write			ldaa #1
				staa written
				
				ldaa #$14
				staa PORTM				
				
				ldaa #$45
				staa PORTA
		
				bclr PORTM,$10	 
				jsr Delay1MS
				jsr Delay1MS
				bset PORTM,$10	 
		
				ldaa #$4D
				staa PORTA
		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
				
				ldaa #$50
				staa PORTA
		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
		
				ldaa #$54
				staa PORTA
				
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
		
				ldaa #$59
				staa PORTA
		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10
				bra Test
				
compare2		cmpa #$F1		; compare for Quarter Full
			    bgt compare3	; if not true branch to half
				beq Quarter
				blt empty
Quarter			ldaa #0
				staa written
				ldaa #$10
				staa PORTM

				ldaa #$01
				staa PORTA
				jsr Delay1MS	 		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
				jsr Delay1MS
				ldd #!150
				std DutyCycle
				lbra Motor
		
compare3		cmpa #$F2		; compare for half Full
			 	bgt compare4	; if not true branch to ThreeQuarter			
				beq half
				blt Quarter
half			ldaa #0
				staa written
				ldaa #$10
				staa PORTM

				ldaa #$01
				staa PORTA
				jsr Delay1MS	 		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
				jsr Delay1MS
				ldd #!250
				std DutyCycle
				ldaa PORTB
				cmpa #$F2
				lbeq Motor
		
compare4  		cmpa #$F4		; compare for ThreeQuarter Full
				bgt compare5	; if not true branch to Full
				beq ThreeQuarter
				blt half
ThreeQuarter	ldaa #0
				staa written
				ldaa #$10
				staa PORTM

				ldaa #$01
				staa PORTA
				jsr Delay1MS	 		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
				jsr Delay1MS
				ldd #!450
				std DutyCycle
				ldaa PORTB
				cmpa #$F4
				beq Motor
				
compare5		cmpa #$F8		; compare for Full
				beq Full
				blt ThreeQuarter
Full			ldaa #0
				staa written
				ldaa #$10
				staa PORTM

				ldaa #$01
				staa PORTA
				jsr Delay1MS	 		
				bclr PORTM,$10	 
				jsr Delay1MS
				bset PORTM,$10	
				jsr Delay1MS
				ldd #!250
				std DutyCycle
				ldaa PORTB
				cmpa #$F1
				beq soundAlarm
		
soundAlarm		ldaa PORTB
				cmpa #$F0
				lbeq Test
				LDD TSCNT
				ADDD DutyCycle				; Add an offset to the current TSCNT equivalent to the ON time and store to TC4
				STD TC4
				LDAA #$02					; Initialize register TCTL1 to CLEAR bit 4 on a compare event
				STAA TCTL1
wait			BRCLR TFLG1,$10,wait			; Spin until the TFLG1 register indicates a bit 4 compare event
				LDD #!1024
				SUBD DutyCycle
				ADDD TSCNT	
									; Read current 16 bit value of TSCNT				; Add an offset to the current TSCNT equivalent to the OFF time and store to TC4
				STD TC4
				LDAA #$03					; Initialize register TCTL1 to SET bit 4 on a compare event
				STAA TCTL1
wait2			BRCLR TFLG1,$10,wait2			; Spin until the TFLG1 register indicates a bit 4 compare event
			
				bra soundAlarm
				
Motor			ldaa PORTB
				cmpa #$F0
				lbeq Test
				ldd TSCNT
	 			addd #!150
	 			addd DutyCycle
	 			std TC1
	
				ldaa #$08
	 			staa TCTL2
	
wait1 			brclr TFLG1,$02,wait1	
	
	 			ldd TSCNT
	 
	 			addd #!1024
	 			subd DutyCycle
	 			std TC1
	 
	 			ldaa #$0C
	 	  		staa TCTL2
	
wait3 			brclr TFLG1,$02,wait3
	  			
				bra MOTOR
				

InitLCD:	ldaa #$FF ; Set port A to output for now
		staa DDRA

                ldaa #$1C ; Set port M bits 4,3,2
		staa DDRM


		LDAA #$30	; We need to send this command a bunch of times
		psha
		LDAA #5     ; delay value
		psha
		jsr SendWithDelay
		pula

		ldaa #1
		psha
		jsr SendWithDelay
		jsr SendWithDelay
		jsr SendWithDelay
		pula
		pula

		ldaa #$08
		psha
		ldaa #1
		psha
		jsr SendWithDelay
		pula
		pula

		ldaa #1
		psha
		psha
		jsr SendWithDelay
		pula
		pula

		ldaa #6
		psha
		ldaa #1
		psha
		jsr SendWithDelay
		pula
		pula

		ldaa #$0E
		psha
		ldaa #1
		psha
		jsr SendWithDelay
		pula
		pula

		rts


SendWithDelay:  TSX
		LDAA 3,x
		STAA PORTA

		bset PORTM,$10	 ; Turn on bit 4
		jsr Delay1MS
		bclr PORTM,$10	 ; Turn off bit 4

		tsx
		ldaa 2,x
		psha
		clra
		psha
		jsr Delay
		pula
		pula
		rts

Delay1MS:  
		ldy	#$800
top:	dey
		bne	top	
		rts
		
Delay:		ldab 2,x
start:		jsr Delay1MS
			decb
			bne start
			rts