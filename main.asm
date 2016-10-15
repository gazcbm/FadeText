*=$1000 ;sys4096
;----------- Declerations -----------------
fadetimer=#00
colour_idx=#$00
;----------- main section -----------------

           	LDX #$00    ;load black (doubles as offset) 
           	stx $d020   ;change borders and foreground 
           	stx $d021 
clear      	lda #$20     ; load the space char 
           	sta $0400,x  ; fill the screen with space 
           	sta $0500,x 
           	sta $0600,x 
           	sta $06e8,x 
           	inx          ; increment pointer 
           	bne clear    ; if not done do another iteration 

           	sei         ; set interrupt disable flag 
           	ldy #$7f    ; $7f = %01111111 

           	sty $dd0d   ; Turn off CIA interrupts 
           	lda $dd0d   ; cancel pending interrupts 

           	lda #$01    ; Set Interrupt Request Mask... 
           	sta $d01a   ; Rasterbeam 

           	lda #<irq     ; point IRQ Vector to our custom irq routine 
           	ldx #>irq 
           	sta $314      ; store in $314/$315 
           	stx $315 

           	lda #$00      ; trigger first interrupt at row zero 
           	sta $d012     ; VIC-II 

			ldx #$00      ;set string offset 
write_txt  	lda string1,x ;read the x char in the string 
           	sta $05a2,x   ;store on screen location 
           	inx           ;increment offset 
           	cpx #$05      ;have we wrote 5 characters? 
           	bne write_txt ;if not do another iteration. 
           	cli           ; enable IRQ processing 


irq        	asl $d019      ;ack interupt 
		   	pha        ;store register A in stack
			txa
			pha        ;store register X in stack
			tya
			pha        ;store register y in stack
		    dec fadetimer
		 	bmi dofade
exitirq     pla
            tay        ;restore register Y from stack 
            pla
            tax        ;restore register X from stack
            pla        ;restiore register A from stack
           	rti

doFade     	lda colour,colour_idx 	;load from colour table
           	sta $d9a2,x				;plot CRAM 
           	inx                   	;Increment CRAM position
           	cpx #$05			  	;5 positions?
           	bne doFade				;If not, then repeat
           	inc colour_idx			;forward to the next colour
           	lda colour_idx			;load into the accumulator (is this required, does INC store in A? Breakbpoint?)
           	cmp $#04				;4th colour?
           	beq cancelirq.          ;if yes, kill the raster IRQ
          	jmp exitirq				;return to IRQ sr.
               

cancelirq  	lda $ff					;%11111111 Cancel 
			sta $d019				;VIC register
			jmp exitirq				;back to finish IRQ sr
			
; --------------- below this line is old code ---------------------
fade_in    ldx #$00       ;set string offset 
           ldy #$00       ;set colour offset 
change_col lda colour,y   ;read the y colour 
           sta $d9a2,x    ;write colour to location 
           inx            ;increment the string offset 
           cpx #$05       ;have we done 5 letters? 
           bne change_col ; if not do another interation 
           ldx #$00       ;if so, reset string offset for the next colour 
           iny            ;increment offset for next colour 
           cpy #$04       ;is this the last colour? 
           bne change_col ;if not do another iteration 
           rts            ;if so, we''ve finished here 

colour     byte $00,$12,$15,$01 
string1    text 'hello' 

;IRQ 
;[save registers on stack] 
;DEC fadeTimer 
;BMI doFade 
;EXITIRQ 
;; pull off registers of the stack in reverse order 
;rti 
;doFade 
;lda #16 ; this is the number of frames to wait before changing colour 
;sta fadeTimer 
; plot CRAM 
;values here 
;jmp EXITIRQ 
