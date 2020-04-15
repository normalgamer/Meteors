  .inesprg 1	; 1x 16KB PRG code
  .ineschr 1	; 1x  8KB CHR data
  .inesmap 0	; mapper 0 = NROM, no bank swapping
  .inesmir 1	; background mirroring
  

;;;;;;;;;;;;;;;

  .rsset $0000
	
score	.rs 2	; player 1 gamepad buttons, one bit per button
seed	.rs 1	; Seed for the Pseudo Random Number Generator
rand	.rs 1





  .bank 0
  .org $C000

vblankwait:			; First wait for vblank to make sure PPU is ready
	BIT $2002
	BPL vblankwait
	RTS

RESET:
	SEI				; disable IRQs
	CLD				; disable decimal mode
  
	JSR vblankwait

clrmem:
	LDA #$FE
	STA $0200, x
	INX
	BNE clrmem
	JSR vblankwait
   


LoadPalettes:
	LDA $2002				; read PPU status to reset the high/low latch
	LDA #$3F
	STA $2006				; write the high byte of $3F00 address
	LDA #$00
	STA $2006				; write the low byte of $3F00 address
	LDX #$00				; start out at 0
LoadPalettesLoop:
	LDA palette, x			; load data from address (palette + the value in x)
	STA $2007				; write to PPU
	INX						; X = X + 1
	CPX #$20             	; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
	BNE LoadPalettesLoop  	; Branch to LoadPalettesLoop if compare was Not Equal to zero
							; if compare was equal to 32, keep going down

LoadSprites:
	LDX #$00				; start at 0
LoadSpritesLoop:
	LDA sprites, x			; load data from address (sprites + x)
	STA $0200, x			; store into RAM address ($0200 + x)
	INX						; X = X + 1
	CPX #$10				; Compare X to hex $10, decimal 16
	BNE LoadSpritesLoop		; Branch to LoadSpritesLoop if compare was Not Equal to zero
							; if compare was equal to 16, continue down



	LDA #%10010000	; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000

	LDA #%00011110	; enable sprites, enable background, no clipping on left side
	STA $2001
	
	LDA #$3E
	STA seed

main:
	JMP main		;jump back to main, infinite loop, waiting for NMI



NMI:				; Aki komiensa la peska
	LDA #$00
	STA $2003       ; set the low byte (00) of the RAM address
	LDA #$02
	STA $4014       ; set the high byte (02) of the RAM address, start the transfer



	; This is the PPU clean up section, so rendering the next frame starts properly.
	LDA #%10010000	; Enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110	; Enable sprites, enable background, no clipping on left side
	STA $2001
	LDA #$00		; Tell the ppu there is no background scrolling
	STA $2005
	STA $2005
    
	; All graphics updates done by here, run game engine
	

LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016			; tell both the controllers to latch buttons


ReadA: 
  LDA $4016			; player 1 - A
  AND #%00000001	; only look at bit 0
  BEQ ReadADone		; branch to ReadADone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadADone:			; handling this button is done
  

ReadB: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadBDone		; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadBDone:			; handling this button is done

ReadSelect: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadSelectDone; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadSelectDone:		; handling this button is done

ReadStart: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadStartDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadStartDone:		; handling this button is done

ReadUp: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadUpDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadUpDone:			; handling this button is done

ReadDown: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadDownDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadDownDone:		; handling this button is done

ReadLeft: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadLeftDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)
  DEC $0203
  DEC $0207
  DEC $020B
  DEC $020F
  DEC $0203
  DEC $0207
  DEC $020B
  DEC $020F
ReadLeftDone:		; handling this button is done

ReadRight: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadRightDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)
  INC $0203
  INC $0207
  INC $020B
  INC $020F
  INC $0203
  INC $0207
  INC $020B
  INC $020F
ReadRightDone:		; handling this button is done



  
  RTI             ; return from interrupt



generatePrng:		; Pseudo Random Number Generator, probably not the best in the world
	LDA seed
	LDY #$E3
	ROL A
	STA rand
	ROL A
	TAX
	ADC rand,X



;;;;;;;;;;;;;;  
  
  
  
	.bank 1
	.org $E000
palette:
	.db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F	; Background palette
	.db $0F,$00,$12,$21,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C	; Sprite palette

sprites:
	;   vert tile attr       horiz
	.db $D0, $00, %00000000, $80	;sprite 0
	.db $D0, $00, %01000000, $88	;sprite 1
	.db $D8, $10, %00000000, $80	;sprite 2
	.db $D8, $10, %01000000, $88	;sprite 3
	
	;76543210
	;|||   ||
	;|||   ++- Color Palette of sprite.  Choose which set of 4 from the 16 colors to use
	;|||
	;||+------ Priority (0: in front of background; 1: behind background)
	;|+------- Flip sprite horizontally
	;+-------- Flip sprite vertically




	.org $FFFA		;First of the three vectors starts here
	.dw NMI			;When an NMI happens (once per frame if enabled) the 
					;processor will jump to the label NMI:
	.dw RESET		;When the processor first turns on or is reset, it will jump
					;to the label RESET:
	.dw 0			;External interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "chr.chr"	;Includes 8KB graphics file
  
  
  .bank 3
  .org $E000